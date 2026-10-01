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
  // Deck cards take priority over plain dictionary Items, same override
  // order the app itself uses.
  function buildLookupIndex(data) {
    const index = new Map();
    const sets = data.sets || {};
    for (const key of Object.keys(sets)) {
      const items = sets[key].items || [];
      for (const item of items) {
        if (!item.japanese || item.itemType === 'Hiragana' || item.itemType === 'Katakana') continue;
        index.set(item.japanese, {
          reading: item.reading || item.onYomi || item.kunYomi || '',
          meaning: item.translation || '',
        });
      }
    }
    const decks = data.studyDecks || [];
    for (const deck of decks) {
      for (const card of deck.cards || []) {
        // Same exclusion as the dictionary items above - a bare kana deck
        // would otherwise flag nearly every character in any sentence.
        if (!card.japanese || card.cardType === 'Kana') continue;
        index.set(card.japanese, { reading: card.hiragana || '', meaning: card.english || '' });
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

  function normalizeSettings(s) {
    return {
      enabled: !s || s.enabled !== false,
      autoPause: !s || s.autoPause !== false,
    };
  }

  async function loadState() {
    backupCache = await storageGet(KA_STORAGE_KEYS.backup);
    lookupIndex = backupCache ? buildLookupIndex(backupCache.data) : null;
    settings = normalizeSettings(await storageGet(KA_STORAGE_KEYS.settings));
  }

  async function updateSettings(patch) {
    settings = { ...settings, ...patch };
    await storageSet({ [KA_STORAGE_KEYS.settings]: settings });
    syncOverlayFromDom();
  }

  chrome.storage.onChanged.addListener((changes, area) => {
    if (area !== 'local') return;
    if (changes[KA_STORAGE_KEYS.backup]) {
      backupCache = changes[KA_STORAGE_KEYS.backup].newValue;
      lookupIndex = backupCache ? buildLookupIndex(backupCache.data) : null;
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
    if (typeof deckIndexOrNewName === 'number') {
      deck = data.studyDecks[deckIndexOrNewName];
    } else {
      deck = {
        name: deckIndexOrNewName,
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
    deck.cards.push({
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
    });
    backupCache.unsyncedCount = (backupCache.unsyncedCount || 0) + 1;
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
      hint.textContent = 'Not in your dictionary/decks - add it manually:';
      popup.appendChild(hint);
      const meaningInput = document.createElement('input');
      meaningInput.type = 'text';
      meaningInput.placeholder = 'English meaning (optional)';
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

  function syncOverlayFromDom() {
    const overlay = ensureOverlay();
    if (!overlay) return;
    if (!settings.enabled) {
      overlay.textContent = '';
      return;
    }
    const container = findCaptionContainer();
    const segments = container ? container.querySelectorAll('.ytp-caption-segment') : [];
    overlay.textContent = Array.from(segments)
      .map((el) => (el.textContent || '').trim())
      .filter(Boolean)
      .join('\n');
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
    if (!text) return;

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
