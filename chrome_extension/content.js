// Runs on YouTube watch pages. Mirrors lib/study_data.dart's
// buildHighlightIndex/tokenizeSentence for lookup, and
// lib/listening_player.dart's DeckPickerDialog + _addSelectionToDeck for the
// add-to-deck flow - see the plan doc for the full file:line references.

(function () {
  let lookupIndex = null; // Map<string, {reading, meaning}>
  let backupCache = null; // the cached { data, downloadedAt, unsyncedCount } object
  let settings = { enabled: true, autoPause: true };
  let activePopup = null;

  function storageGet(key) {
    return new Promise((resolve) => chrome.storage.local.get(key, (result) => resolve(result[key])));
  }

  function storageSet(obj) {
    return new Promise((resolve) => chrome.storage.local.set(obj, resolve));
  }

  // --- Lookup index, mirroring buildHighlightIndex (lib/study_data.dart) ---
  // The downloaded backup no longer carries the full dictionary (see
  // lib/backup_data.dart's format 2 - only personal customSets/setOverrides
  // are exported now), so the baseline comes from dictionary.json instead,
  // bundled straight into the extension and generated from the same
  // setsData the app ships with (tool/generate_dictionary_json.dart).
  // Deck cards take priority over custom-set items, which take priority
  // over baseline dictionary entries - same override order the app itself
  // uses for its own highlight index.
  let dictionaryBaseline = null;

  async function loadDictionaryBaseline() {
    if (dictionaryBaseline) return dictionaryBaseline;
    const index = new Map();
    try {
      const res = await fetch(chrome.runtime.getURL('dictionary.json'));
      const data = await res.json();
      for (const key of Object.keys(data)) {
        for (const item of data[key].items || []) {
          if (!item.japanese || item.itemType === 'Hiragana' || item.itemType === 'Katakana') continue;
          index.set(item.japanese, {
            reading: item.reading || item.onYomi || item.kunYomi || '',
            meaning: item.translation || '',
          });
        }
      }
    } catch (e) {
      console.error('[KA] failed to load bundled dictionary.json', e);
    }
    dictionaryBaseline = index;
    return index;
  }

  async function buildLookupIndex(personalData) {
    const index = new Map(await loadDictionaryBaseline());

    if (personalData) {
      // setOverrides: a patch against a baseline entry (translation/reading
      // edited) or a brand-new item added into an otherwise-default set.
      const overrides = personalData.setOverrides || {};
      for (const key of Object.keys(overrides)) {
        for (const patch of overrides[key].itemOverrides || []) {
          if (patch.new) {
            if (patch.itemType === 'Hiragana' || patch.itemType === 'Katakana') continue;
            index.set(patch.japanese, {
              reading: patch.reading || patch.onYomi || patch.kunYomi || '',
              meaning: patch.translation || '',
            });
            continue;
          }
          const existing = index.get(patch.japanese);
          if (!existing) continue;
          index.set(patch.japanese, {
            reading: patch.reading !== undefined ? patch.reading : existing.reading,
            meaning: patch.translation !== undefined ? patch.translation : existing.meaning,
          });
        }
      }

      // customSets: fully custom sets, not backed by any default - add in full.
      const customSets = personalData.customSets || {};
      for (const key of Object.keys(customSets)) {
        for (const item of customSets[key].items || []) {
          if (!item.japanese || item.itemType === 'Hiragana' || item.itemType === 'Katakana') continue;
          index.set(item.japanese, {
            reading: item.reading || item.onYomi || item.kunYomi || '',
            meaning: item.translation || '',
          });
        }
      }

      for (const deck of personalData.studyDecks || []) {
        for (const card of deck.cards || []) {
          // Same exclusion as above - a bare kana deck would otherwise flag
          // nearly every character in any sentence.
          if (!card.japanese || card.cardType === 'Kana') continue;
          index.set(card.japanese, { reading: card.hiragana || '', meaning: card.english || '' });
        }
      }
    }

    return index;
  }

  // Greedy longest-match, mirroring tokenizeSentence (lib/study_data.dart:280-306).
  // Given an imprecise drag-selection, finds the best-matching known
  // substring rather than requiring an exact whole-selection match.
  function findBestMatch(text, index) {
    if (index.has(text)) return { matchedText: text, entry: index.get(text) };
    for (let len = text.length - 1; len >= 1; len--) {
      for (let start = 0; start + len <= text.length; start++) {
        const candidate = text.substring(start, start + len);
        if (index.has(candidate)) return { matchedText: candidate, entry: index.get(candidate) };
      }
    }
    return null;
  }

  // Same algorithm as findBestMatch, but scanning left-to-right across the
  // whole line instead of just one dragged selection - this is what powers
  // the automatic purple highlighting, matching tokenizeSentence
  // (lib/study_data.dart:280-306) exactly: at each position, try the
  // longest known substring first, falling back one character at a time.
  // Runs with no match get merged together rather than split per character.
  function tokenizeText(text, index) {
    const tokens = [];
    if (!index || index.size === 0) return [{ text, entry: null }];
    const maxLen = Math.max(...Array.from(index.keys(), (k) => k.length));
    let i = 0;
    while (i < text.length) {
      let matched = null;
      const longest = Math.min(maxLen, text.length - i);
      for (let len = longest; len >= 1; len--) {
        const candidate = text.substring(i, i + len);
        if (index.has(candidate)) {
          matched = candidate;
          break;
        }
      }
      if (matched) {
        tokens.push({ text: matched, entry: index.get(matched) });
        i += matched.length;
      } else {
        const last = tokens[tokens.length - 1];
        if (last && last.entry === null) {
          last.text += text[i];
        } else {
          tokens.push({ text: text[i], entry: null });
        }
        i += 1;
      }
    }
    return tokens;
  }

  function escapeHtml(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  const DEFAULT_TEXT_SIZE = 24; // matches content.css's original #ka-subtitle-overlay font-size
  const DEFAULT_TEXT_COLOR = '#ffffff';
  const DEFAULT_HIGHLIGHT_COLOR = '#9a00fe';

  function normalizeSettings(s) {
    return {
      enabled: !s || s.enabled !== false,
      autoPause: !s || s.autoPause !== false,
      textSize: (s && s.textSize) || DEFAULT_TEXT_SIZE,
      textColor: (s && s.textColor) || DEFAULT_TEXT_COLOR,
      // 'color': known words shown in the highlight color as text.
      // 'outline': known words keep the normal text color but get a box in
      // the highlight color drawn around them instead - some users find
      // colored CJK text harder to read against a bright video than an
      // outline is. One color setting covers both, since it's the same
      // "this word is known" accent either way, just applied differently.
      highlightStyle: (s && s.highlightStyle) || 'color',
      highlightColor: (s && s.highlightColor) || DEFAULT_HIGHLIGHT_COLOR,
    };
  }

  async function loadState() {
    backupCache = await storageGet(KA_STORAGE_KEYS.backup);
    lookupIndex = await buildLookupIndex(backupCache ? backupCache.data : null);
    settings = normalizeSettings(await storageGet(KA_STORAGE_KEYS.settings));
  }

  async function updateSettings(patch) {
    settings = { ...settings, ...patch };
    await storageSet({ [KA_STORAGE_KEYS.settings]: settings });
    syncOverlayFromDom();
  }

  chrome.storage.onChanged.addListener(async (changes, area) => {
    if (area !== 'local') return;
    if (changes[KA_STORAGE_KEYS.backup]) {
      backupCache = changes[KA_STORAGE_KEYS.backup].newValue;
      lookupIndex = await buildLookupIndex(backupCache ? backupCache.data : null);
    }
    if (changes[KA_STORAGE_KEYS.settings]) {
      settings = normalizeSettings(changes[KA_STORAGE_KEYS.settings].newValue);
      syncOverlayFromDom();
    }
  });

  // --- Popup UI ---

  function closePopup() {
    if (activePopup) {
      activePopup.remove();
      activePopup = null;
    }
  }

  function showHintToast(text) {
    const toast = document.createElement('div');
    toast.className = 'ka-hint-toast';
    toast.textContent = text;
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 3500);
  }

  async function addCardToDeck(deckIndexOrNewName, japanese, reading, meaning) {
    const data = backupCache.data;
    data.studyDecks = data.studyDecks || [];
    let deck;
    let deckName;
    if (typeof deckIndexOrNewName === 'number') {
      deck = data.studyDecks[deckIndexOrNewName];
      deckName = deck.name;
    } else {
      deckName = deckIndexOrNewName;
      deck = {
        name: deckName,
        cards: [],
        newCardsPerDay: 10,
        newCardsIntroducedDate: null,
        newCardsIntroducedToday: 0,
        challengeStartDate: null,
        completedLessonDays: [],
        lessonSetId: null,
        deckCreatedDate: new Date().toISOString().split('T')[0],
        hasShownAnswerIntro: false,
      };
      data.studyDecks.push(deck);
    }
    deck.cards = deck.cards || [];
    const card = {
      japanese,
      hiragana: reading || '',
      romaji: '',
      english: meaning || '',
      kanjiVGCodes: [],
      repetitions: 0,
      easeFactor: 2.5,
      intervalDays: 0,
      nextReviewDate: null,
      progress: 0,
      englishFirst: true,
      answerMode: 'basic',
      memoryTechnique: '',
      isStarred: false,
      challengeDay: null,
      cardType: 'Vocab',
    };
    deck.cards.push(card);
    backupCache.unsyncedCount = (backupCache.unsyncedCount || 0) + 1;
    // Tracked separately from the cached snapshot so syncing can re-apply
    // just these additions onto whatever's freshest on the cloud, instead of
    // uploading this whole (possibly stale) cached copy wholesale - see
    // popup.js's uploadBackup.
    backupCache.pendingAdditions = backupCache.pendingAdditions || [];
    backupCache.pendingAdditions.push({ deckName, card });
    lookupIndex.set(japanese, { reading: reading || '', meaning: meaning || '' });
    await storageSet({ [KA_STORAGE_KEYS.backup]: backupCache });
  }

  function renderDeckPicker(container, onPick) {
    container.innerHTML = '';
    const list = document.createElement('div');
    list.className = 'ka-deck-list';
    const decks = (backupCache.data.studyDecks || []);
    decks.forEach((deck, i) => {
      const row = document.createElement('div');
      row.className = 'ka-deck-item';
      row.textContent = `${deck.name} (${(deck.cards || []).length})`;
      row.addEventListener('click', () => onPick(i));
      list.appendChild(row);
    });
    container.appendChild(list);

    const newInput = document.createElement('input');
    newInput.type = 'text';
    newInput.placeholder = 'New deck name';
    container.appendChild(newInput);

    const newBtn = document.createElement('button');
    newBtn.textContent = '+ New deck';
    newBtn.addEventListener('click', () => {
      const name = newInput.value.trim();
      if (name) onPick(name);
    });
    container.appendChild(newBtn);
  }

  function showLookupPopup(rect, matchedText, entry) {
    closePopup();
    const popup = document.createElement('div');
    popup.className = 'ka-lookup-popup';
    popup.style.left = `${Math.max(8, rect.left)}px`;
    popup.style.top = `${Math.max(8, rect.top - 8)}px`;
    popup.style.transform = 'translateY(-100%)';

    const wordEl = document.createElement('div');
    wordEl.className = 'ka-word';
    wordEl.textContent = matchedText;
    popup.appendChild(wordEl);

    if (entry) {
      if (entry.reading) {
        const readingEl = document.createElement('div');
        readingEl.className = 'ka-reading';
        readingEl.textContent = entry.reading;
        popup.appendChild(readingEl);
      }
      const meaningEl = document.createElement('div');
      meaningEl.className = 'ka-meaning';
      meaningEl.textContent = entry.meaning || '(no meaning on file)';
      popup.appendChild(meaningEl);
    } else {
      const hint = document.createElement('div');
      hint.className = 'ka-status';
      hint.textContent = 'Not in your dictionary/decks:';
      popup.appendChild(hint);

      // Same external hand-off as the app's own openGoogleTranslate
      // (lib/translation_service.dart) - there's no in-app translation API
      // wired up here either, so this is the equivalent stand-in.
      const translateBtn = document.createElement('button');
      translateBtn.className = 'ka-secondary-btn';
      translateBtn.textContent = 'Open in Google Translate';
      translateBtn.addEventListener('click', () => {
        const url = `https://translate.google.com/?sl=ja&tl=en&text=${encodeURIComponent(matchedText)}&op=translate`;
        window.open(url, '_blank');
      });
      popup.appendChild(translateBtn);

      const meaningInput = document.createElement('input');
      meaningInput.type = 'text';
      meaningInput.placeholder = 'English meaning (optional, for adding to a deck)';
      popup.appendChild(meaningInput);
      popup._meaningInput = meaningInput;
    }

    const addBtn = document.createElement('button');
    addBtn.textContent = 'Add to deck';
    popup.appendChild(addBtn);

    const deckPickerContainer = document.createElement('div');
    deckPickerContainer.className = 'hidden';
    popup.appendChild(deckPickerContainer);

    addBtn.addEventListener('click', () => {
      addBtn.classList.add('hidden');
      deckPickerContainer.classList.remove('hidden');
      renderDeckPicker(deckPickerContainer, async (deckIndexOrNewName) => {
        const meaning = entry ? entry.meaning : popup._meaningInput ? popup._meaningInput.value.trim() : '';
        const reading = entry ? entry.reading : '';
        await addCardToDeck(deckIndexOrNewName, matchedText, reading, meaning);
        showHintToast(`Added "${matchedText}" - open the extension to sync when you're done.`);
        closePopup();
      });
    });

    document.body.appendChild(popup);
    activePopup = popup;
  }

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

  function syncOverlayFromDom() {
    const overlay = ensureOverlay();
    if (!overlay) return;
    overlay.style.fontSize = `${settings.textSize}px`;
    overlay.style.color = settings.textColor;
    overlay.style.setProperty('--ka-highlight-color', settings.highlightColor);
    if (!settings.enabled) {
      overlay.innerHTML = '';
      return;
    }
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
    if (!settings.autoPause) return;
    const video = findVideo();
    if (video && !video.paused) video.pause();
  });

  document.addEventListener('mouseup', (e) => {
    if (!settings.enabled) return;
    if (!withinCaptions(e.target)) return;
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
        showLookupPopup(wordSpan.getBoundingClientRect(), word, lookupIndex ? lookupIndex.get(word) : null);
      }
      return;
    }

    if (!lookupIndex) {
      showHintToast('Open the extension and download your data before looking words up.');
      return;
    }

    const range = selection.getRangeAt(0);
    const rect = range.getBoundingClientRect();
    const match = findBestMatch(text, lookupIndex);
    if (match) {
      showLookupPopup(rect, match.matchedText, match.entry);
    } else {
      showLookupPopup(rect, text, null);
    }
  });

  document.addEventListener('click', (e) => {
    if (activePopup && !activePopup.contains(e.target) && !withinCaptions(e.target)) {
      closePopup();
    }
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
    enabledCheckbox.addEventListener('change', () => updateSettings({ enabled: enabledCheckbox.checked }));
    enabledLabel.appendChild(enabledCheckbox);
    enabledLabel.appendChild(document.createTextNode('Enable subtitle lookup'));
    panel.appendChild(enabledLabel);

    const pauseLabel = document.createElement('label');
    const pauseCheckbox = document.createElement('input');
    pauseCheckbox.type = 'checkbox';
    pauseCheckbox.checked = settings.autoPause;
    pauseCheckbox.addEventListener('change', () => updateSettings({ autoPause: pauseCheckbox.checked }));
    pauseLabel.appendChild(pauseCheckbox);
    pauseLabel.appendChild(document.createTextNode('Auto-pause on selection'));
    panel.appendChild(pauseLabel);

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
    sizeSlider.addEventListener('change', () => updateSettings({ textSize: Number(sizeSlider.value) }));
    panel.appendChild(sizeSlider);

    const colorLabel = document.createElement('label');
    colorLabel.className = 'ka-color-row';
    const colorInput = document.createElement('input');
    colorInput.type = 'color';
    colorInput.value = settings.textColor;
    colorInput.addEventListener('input', () => {
      overlayEl.style.color = colorInput.value; // live preview
    });
    colorInput.addEventListener('change', () => updateSettings({ textColor: colorInput.value }));
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
    styleSelect.addEventListener('change', () => updateSettings({ highlightStyle: styleSelect.value }));
    panel.appendChild(styleSelect);

    const highlightColorLabel = document.createElement('label');
    highlightColorLabel.className = 'ka-color-row';
    const highlightColorInput = document.createElement('input');
    highlightColorInput.type = 'color';
    highlightColorInput.value = settings.highlightColor;
    highlightColorInput.addEventListener('input', () => {
      overlayEl.style.setProperty('--ka-highlight-color', highlightColorInput.value); // live preview
    });
    highlightColorInput.addEventListener('change', () => updateSettings({ highlightColor: highlightColorInput.value }));
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
