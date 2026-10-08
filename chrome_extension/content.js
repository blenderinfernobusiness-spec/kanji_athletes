// Runs on YouTube watch pages. Mirrors lib/study_data.dart's
// buildHighlightIndex/tokenizeSentence for lookup, and
// lib/listening_player.dart's DeckPickerDialog + _addSelectionToDeck for the
// add-to-deck flow - see the plan doc for the full file:line references.
//
// Storage helpers, the lookup index, and the word-lookup popup live in
// shared.js (loaded before this file - see manifest.json), shared with
// screen_reader.js's page-wide reading mode so both features see the same
// data and show the exact same popup.

(function () {
  let settings = { enabled: true, autoPause: true };

  async function loadState() {
    await loadBackupAndIndex();
    settings = normalizeSettings(await storageGet(KA_STORAGE_KEYS.settings));
  }

  chrome.storage.onChanged.addListener(async (changes, area) => {
    if (area !== 'local') return;
    if (changes[KA_STORAGE_KEYS.settings]) {
      settings = normalizeSettings(changes[KA_STORAGE_KEYS.settings].newValue);
      syncOverlayFromDom();
    }
  });

  // --- Caption capture ---
  // Ruled out, in order: YouTube's own caption box has selection
  // deliberately disabled (dragging over it never produces a real text
  // selection); the <video> element's native textTracks aren't populated by
  // YouTube at all; and fetching the caption track's own data URL directly
  // (the timedtext endpoint) consistently came back 200 OK with a
  // completely empty body no matter which JS world or format was used -
  // this looks like a deliberate server-side restriction on scripted access
  // to that endpoint, not something fixable with more header/timing tweaks.
  //
  // What actually works: don't re-fetch anything - just mirror the text
  // YouTube is ALREADY legitimately displaying. Reading .textContent of its
  // caption segments isn't blocked (only *selecting* them with a mouse is),
  // so a MutationObserver watches that box and copies its text into our own
  // plain, selectable overlay whenever it changes. This also means it shows
  // whatever language YouTube's own CC menu is currently set to - there's no
  // way to force a different one without that restriction applying equally
  // to however we'd go about reading an un-selected track's data.

  let overlayEl = null;

  function findVideo() {
    return document.querySelector('.html5-main-video') || document.querySelector('video');
  }

  function findOverlayHost() {
    return document.getElementById('movie_player') || document.querySelector('.html5-video-player');
  }

  function ensureOverlay() {
    const host = findOverlayHost();
    if (!host) return null;
    if (overlayEl && overlayEl.isConnected) return overlayEl;
    overlayEl = document.createElement('div');
    overlayEl.id = 'ka-subtitle-overlay';
    host.appendChild(overlayEl);
    return overlayEl;
  }

  function findCaptionContainer() {
    return document.querySelector('.ytp-caption-window-container');
  }

  // Renders each line through tokenizeText so recognized dictionary/deck
  // words get wrapped in a clickable, purple-highlighted span - the same
  // "known word" treatment Reading and Listening give automatically in the
  // app itself, rather than requiring a manual drag-select every time.
  function renderOverlayLine(line) {
    if (!lookupIndex) return escapeHtml(line);
    return tokenizeText(line, lookupIndex)
      .map((t) =>
        t.entry
          ? `<span class="ka-highlight ka-highlight-${settings.highlightStyle}" data-word="${escapeHtml(t.text)}">${escapeHtml(t.text)}</span>`
          : escapeHtml(t.text)
      )
      .join('');
  }

  // True while the user has the mouse button down inside the overlay (a
  // drag selection in progress). Captions advance on their own timer,
  // independent of the user's mouse, so one could change mid-drag; rebuilding
  // the overlay's innerHTML at that moment destroys the exact text nodes the
  // browser's Selection is anchored to, which is what caused the drag
  // selection to unpredictably jump/expand. syncOverlayFromDom defers the
  // rebuild until mouseup instead of ever touching the DOM out from under an
  // active selection.
  let isSelectingInOverlay = false;

  function syncOverlayFromDom() {
    const overlay = ensureOverlay();
    if (!overlay) return;
    overlay.style.fontSize = `${settings.textSize}px`;
    overlay.style.color = settings.textColor;
    overlay.style.bottom = `${settings.verticalPosition}%`;
    overlay.style.setProperty('--ka-highlight-color', settings.highlightColor);
    overlay.classList.toggle('ka-subtitle-bg', settings.backgroundEnabled);
    if (!settings.enabled) {
      overlay.innerHTML = '';
      return;
    }
    if (isSelectingInOverlay) return;
    const container = findCaptionContainer();
    const segments = container ? Array.from(container.querySelectorAll('.ytp-caption-segment')) : [];
    if (!segments.length) {
      overlay.innerHTML = '';
      return;
    }
    // Some videos use a "rolling" caption style where YouTube keeps several
    // previous lines in the DOM at once instead of removing them - capped
    // to one line by only rendering whichever segments share the same
    // parent as the most recently added one (segments belonging to the
    // current line, even if it's internally split into multiple styled
    // runs), discarding everything earlier.
    const lastSegment = segments[segments.length - 1];
    const lastLineParent = lastSegment.parentElement;
    const currentLineSegments = lastLineParent
      ? segments.filter((s) => s.parentElement === lastLineParent)
      : [lastSegment];
    const line = currentLineSegments
      .map((el) => (el.textContent || '').trim())
      .filter(Boolean)
      .join('');
    overlay.innerHTML = line ? renderOverlayLine(line) : '';
  }

  let captionObserver = null;
  let observedContainer = null;

  function ensureCaptionObserver() {
    const container = findCaptionContainer();
    if (!container || container === observedContainer) return;
    if (captionObserver) captionObserver.disconnect();
    captionObserver = new MutationObserver(syncOverlayFromDom);
    captionObserver.observe(container, { childList: true, subtree: true, characterData: true });
    observedContainer = container;
    syncOverlayFromDom();
  }

  function tick() {
    ensureSettingsButton();
    ensureCaptionObserver();
    syncOverlayFromDom();
  }

  // Polling rather than relying solely on the observer, since YouTube can
  // recreate the caption container (e.g. on fullscreen toggle or navigating
  // to a different video) and the observer needs re-attaching when it does.
  setInterval(tick, 1000);
  tick();

  function withinCaptions(node) {
    return overlayEl && overlayEl.contains(node);
  }

  document.addEventListener('mousedown', (e) => {
    if (!settings.enabled) return;
    if (!withinCaptions(e.target)) return;
    isSelectingInOverlay = true;
    if (!settings.autoPause) return;
    const video = findVideo();
    if (video && !video.paused) video.pause();
  });

  document.addEventListener('mouseup', (e) => {
    if (!settings.enabled) return;
    const wasSelecting = isSelectingInOverlay;
    isSelectingInOverlay = false;
    if (!withinCaptions(e.target)) {
      if (wasSelecting) syncOverlayFromDom(); // catch up on any caption change that happened mid-drag
      return;
    }
    const selection = window.getSelection();
    const text = selection ? selection.toString().trim() : '';

    if (!text) {
      // No drag happened - a plain click on an already-highlighted word
      // still opens its lookup directly, matching "click to auto select"
      // instead of requiring a precise drag across a word that's already
      // known to be a match.
      const wordSpan = e.target.closest ? e.target.closest('.ka-highlight') : null;
      if (wordSpan) {
        const word = wordSpan.dataset.word;
        showLookupPopup(wordSpan.getBoundingClientRect(), word, entryForExactWord(word));
        markJustShowedPopup();
      }
      if (wasSelecting) syncOverlayFromDom();
      return;
    }

    if (!lookupIndex) {
      showHintToast('Open the extension and download your data before looking words up.');
      if (wasSelecting) syncOverlayFromDom();
      return;
    }

    // Deliberately an exact match only, not a fuzzy "hunt for any known
    // substring anywhere inside this" fallback - that used to exist for
    // YouTube's cramped, hard-to-drag-precisely captions, but it just as
    // often surfaced some shorter unrelated word buried inside the drag
    // instead of respecting what was actually selected. A selection that
    // isn't itself a dictionary entry is shown as-is (the usual "not in
    // dictionary" popup), not narrowed down to a smaller piece of it.
    const range = selection.getRangeAt(0);
    const rect = range.getBoundingClientRect();
    const entry = entryForExactWord(text);
    if (wasSelecting) syncOverlayFromDom(); // safe now - rect/text are already captured above
    showLookupPopup(rect, text, entry);
    markJustShowedPopup();
  });

  // --- In-player settings cog ---
  // A toolbar-popup round trip is too slow to reach while actually watching,
  // so the settings that matter mid-video (on/off, auto-pause) live right in
  // YouTube's own control bar instead.

  let settingsPanel = null;

  function closeSettingsPanel() {
    if (settingsPanel) {
      settingsPanel.remove();
      settingsPanel = null;
    }
  }

  function buildSettingsPanel(anchorBtn) {
    const panel = document.createElement('div');
    panel.className = 'ka-settings-panel';

    const enabledLabel = document.createElement('label');
    const enabledCheckbox = document.createElement('input');
    enabledCheckbox.type = 'checkbox';
    enabledCheckbox.checked = settings.enabled;
    enabledCheckbox.addEventListener('change', async () => {
      settings = await updateSettings({ enabled: enabledCheckbox.checked });
      syncOverlayFromDom();
    });
    enabledLabel.appendChild(enabledCheckbox);
    enabledLabel.appendChild(document.createTextNode('Enable subtitle lookup'));
    panel.appendChild(enabledLabel);

    const pauseLabel = document.createElement('label');
    const pauseCheckbox = document.createElement('input');
    pauseCheckbox.type = 'checkbox';
    pauseCheckbox.checked = settings.autoPause;
    pauseCheckbox.addEventListener('change', async () => {
      settings = await updateSettings({ autoPause: pauseCheckbox.checked });
    });
    pauseLabel.appendChild(pauseCheckbox);
    pauseLabel.appendChild(document.createTextNode('Auto-pause on selection'));
    panel.appendChild(pauseLabel);

    const bgLabel = document.createElement('label');
    const bgCheckbox = document.createElement('input');
    bgCheckbox.type = 'checkbox';
    bgCheckbox.checked = settings.backgroundEnabled;
    bgCheckbox.addEventListener('change', async () => {
      overlayEl.classList.toggle('ka-subtitle-bg', bgCheckbox.checked); // live preview
      settings = await updateSettings({ backgroundEnabled: bgCheckbox.checked });
    });
    bgLabel.appendChild(bgCheckbox);
    bgLabel.appendChild(document.createTextNode('Dark background behind subtitles'));
    panel.appendChild(bgLabel);

    const sizeLabel = document.createElement('div');
    sizeLabel.className = 'ka-settings-subheading';
    const sizeValueSpan = document.createElement('span');
    sizeValueSpan.textContent = `${settings.textSize}px`;
    sizeLabel.appendChild(document.createTextNode('Subtitle text size '));
    sizeLabel.appendChild(sizeValueSpan);
    panel.appendChild(sizeLabel);

    const sizeSlider = document.createElement('input');
    sizeSlider.type = 'range';
    sizeSlider.min = '14';
    sizeSlider.max = '48';
    sizeSlider.step = '2';
    sizeSlider.value = String(settings.textSize);
    sizeSlider.addEventListener('input', () => {
      sizeValueSpan.textContent = `${sizeSlider.value}px`;
      overlayEl.style.fontSize = `${sizeSlider.value}px`; // live preview while dragging
    });
    sizeSlider.addEventListener('change', async () => {
      settings = await updateSettings({ textSize: Number(sizeSlider.value) });
    });
    panel.appendChild(sizeSlider);

    const posLabel = document.createElement('div');
    posLabel.className = 'ka-settings-subheading';
    const posValueSpan = document.createElement('span');
    posValueSpan.textContent = `${settings.verticalPosition}%`;
    posLabel.appendChild(document.createTextNode('Subtitle position (from bottom) '));
    posLabel.appendChild(posValueSpan);
    panel.appendChild(posLabel);

    const posSlider = document.createElement('input');
    posSlider.type = 'range';
    posSlider.min = '0';
    posSlider.max = '70';
    posSlider.step = '1';
    posSlider.value = String(settings.verticalPosition);
    posSlider.addEventListener('input', () => {
      posValueSpan.textContent = `${posSlider.value}%`;
      overlayEl.style.bottom = `${posSlider.value}%`; // live preview while dragging
    });
    posSlider.addEventListener('change', async () => {
      settings = await updateSettings({ verticalPosition: Number(posSlider.value) });
    });
    panel.appendChild(posSlider);

    const colorLabel = document.createElement('label');
    colorLabel.className = 'ka-color-row';
    const colorInput = document.createElement('input');
    colorInput.type = 'color';
    colorInput.value = settings.textColor;
    colorInput.addEventListener('input', () => {
      overlayEl.style.color = colorInput.value; // live preview
    });
    colorInput.addEventListener('change', async () => {
      settings = await updateSettings({ textColor: colorInput.value });
    });
    colorLabel.appendChild(document.createTextNode('Subtitle text color'));
    colorLabel.appendChild(colorInput);
    panel.appendChild(colorLabel);

    const styleLabel = document.createElement('div');
    styleLabel.className = 'ka-settings-subheading';
    styleLabel.textContent = 'Highlight style for known words';
    panel.appendChild(styleLabel);

    const styleSelect = document.createElement('select');
    const styleOptions = [
      { value: 'color', label: 'Colored text' },
      { value: 'outline', label: 'Outlined box (keeps normal text color)' },
    ];
    for (const opt of styleOptions) {
      const option = document.createElement('option');
      option.value = opt.value;
      option.textContent = opt.label;
      styleSelect.appendChild(option);
    }
    styleSelect.value = settings.highlightStyle;
    styleSelect.addEventListener('change', async () => {
      settings = await updateSettings({ highlightStyle: styleSelect.value });
      syncOverlayFromDom();
    });
    panel.appendChild(styleSelect);

    const highlightColorLabel = document.createElement('label');
    highlightColorLabel.className = 'ka-color-row';
    const highlightColorInput = document.createElement('input');
    highlightColorInput.type = 'color';
    highlightColorInput.value = settings.highlightColor;
    highlightColorInput.addEventListener('input', () => {
      overlayEl.style.setProperty('--ka-highlight-color', highlightColorInput.value); // live preview
    });
    highlightColorInput.addEventListener('change', async () => {
      settings = await updateSettings({ highlightColor: highlightColorInput.value });
    });
    highlightColorLabel.appendChild(document.createTextNode('Highlight color'));
    highlightColorLabel.appendChild(highlightColorInput);
    panel.appendChild(highlightColorLabel);

    const note = document.createElement('div');
    note.className = 'ka-settings-subheading';
    note.textContent = "Shows whatever language is set in YouTube's own CC menu.";
    panel.appendChild(note);

    return panel;
  }

  function ensureSettingsButton() {
    const controls = document.querySelector('.ytp-right-controls');
    if (!controls || controls.querySelector('#ka-settings-btn')) return;
    const btn = document.createElement('button');
    btn.id = 'ka-settings-btn';
    btn.className = 'ytp-button ka-settings-btn';
    btn.title = 'Kanji Athletes subtitle settings';
    btn.textContent = '⚙';
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      if (settingsPanel) {
        closeSettingsPanel();
        return;
      }
      settingsPanel = buildSettingsPanel(btn);
      const host = findOverlayHost() || document.body;
      host.appendChild(settingsPanel);
    });
    controls.insertBefore(btn, controls.firstChild);
  }

  document.addEventListener('click', (e) => {
    if (settingsPanel && !settingsPanel.contains(e.target) && e.target.id !== 'ka-settings-btn') {
      closeSettingsPanel();
    }
  });

  loadState();
})();
