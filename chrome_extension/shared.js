// Shared between content.js (YouTube subtitle lookup) and screen_reader.js
// (page-wide reading mode): storage helpers, settings normalization, the
// dictionary/deck lookup index, and the word lookup popup + add-to-deck
// flow. Deliberately NOT wrapped in an IIFE - content scripts from the same
// extension injected into the same frame share one isolated-world global
// scope, so these top-level declarations are what let content.js and
// screen_reader.js see the exact same backupCache/lookupIndex and reuse the
// exact same popup, instead of each keeping its own independent copy that
// could drift out of sync with the other.

let lookupIndex = null; // Map<string, {reading, meaning}>
let backupCache = null; // the cached { data, downloadedAt, unsyncedCount } object
let activePopup = null;

function storageGet(key) {
  return new Promise((resolve) => chrome.storage.local.get(key, (result) => resolve(result[key])));
}

function storageSet(obj) {
  return new Promise((resolve) => chrome.storage.local.set(obj, resolve));
}

// --- Settings ---

const DEFAULT_TEXT_SIZE = 24; // matches content.css's original #ka-subtitle-overlay font-size
const DEFAULT_TEXT_COLOR = '#ffffff';
const DEFAULT_HIGHLIGHT_COLOR = '#9a00fe';
const DEFAULT_VERTICAL_POSITION = 8; // % from the bottom, matches content.css's original bottom: 8%

function normalizeSettings(s) {
  return {
    enabled: !s || s.enabled !== false,
    autoPause: !s || s.autoPause !== false,
    textSize: (s && s.textSize) || DEFAULT_TEXT_SIZE,
    textColor: (s && s.textColor) || DEFAULT_TEXT_COLOR,
    // % from the bottom of the player - checked with != null rather than
    // `||` since 0 (flush with the bottom edge) is a valid position that
    // would otherwise get overridden by the default.
    verticalPosition: s && s.verticalPosition != null ? s.verticalPosition : DEFAULT_VERTICAL_POSITION,
    // A semi-transparent dark bar behind the subtitle line, for videos
    // where the text is hard to read against a bright/busy background.
    backgroundEnabled: !!(s && s.backgroundEnabled),
    // 'color': known words shown in the highlight color as text.
    // 'outline': known words keep the normal text color but get a box in
    // the highlight color drawn around them instead - some users find
    // colored CJK text harder to read against a bright video than an
    // outline is. One color setting covers both, since it's the same
    // "this word is known" accent either way, just applied differently.
    // (Screen reading mode always uses colored text - the CSS Custom
    // Highlight API it relies on can't draw a border/box.)
    highlightStyle: (s && s.highlightStyle) || 'color',
    highlightColor: (s && s.highlightColor) || DEFAULT_HIGHLIGHT_COLOR,
    // Page-wide reading mode (see screen_reader.js) - off by default since
    // it's a broader, opt-in feature, not something that should start
    // scanning every page the moment the extension is installed.
    screenReadingEnabled: !!(s && s.screenReadingEnabled),
  };
}

// Always re-reads the current stored settings before merging [patch] in,
// rather than trusting a long-lived in-memory copy - content.js and
// screen_reader.js (and the popup) can all change settings independently,
// and a stale cached copy would silently wipe out whatever the other one
// just saved.
async function updateSettings(patch) {
  const current = normalizeSettings(await storageGet(KA_STORAGE_KEYS.settings));
  const next = { ...current, ...patch };
  await storageSet({ [KA_STORAGE_KEYS.settings]: next });
  return next;
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

// Greedy longest-match, scanning left-to-right across a whole line - this is
// what powers the automatic purple highlighting, matching tokenizeSentence
// (lib/study_data.dart:280-306) exactly: at each position, try the longest
// known substring first, falling back one character at a time. Runs with no
// match get merged together rather than split per character.
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

async function loadBackupAndIndex() {
  backupCache = await storageGet(KA_STORAGE_KEYS.backup);
  lookupIndex = await buildLookupIndex(backupCache ? backupCache.data : null);
}

chrome.storage.onChanged.addListener(async (changes, area) => {
  if (area !== 'local') return;
  if (changes[KA_STORAGE_KEYS.backup]) {
    backupCache = changes[KA_STORAGE_KEYS.backup].newValue;
    lookupIndex = await buildLookupIndex(backupCache ? backupCache.data : null);
  }
});

// --- Word lookup popup + add-to-deck ---

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
  const decks = backupCache.data.studyDecks || [];
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

// --- Click-outside-to-close for the lookup popup ---
// Shared (not duplicated per-script) so a popup opened by content.js
// (subtitles) or screen_reader.js (page-wide reading mode) is closed the
// same consistent way regardless of which one opened it - having each script
// keep its own separate click listener meant that whichever's settings
// toggle happened to be on (e.g. screen reading mode left enabled while back
// on YouTube) could immediately close a popup the OTHER script had just
// opened, since neither knew about the other's "don't close, that click was
// actually inside something we own" exceptions (like YouTube's caption box).

// Anything matching this is never "clicked outside" the popup, regardless of
// which script's UI it belongs to.
function isOwnUi(node) {
  return !!(
    node &&
    node.closest &&
    node.closest('.ka-lookup-popup, .ka-settings-panel, .ka-hint-toast, #ka-subtitle-overlay, #ka-settings-btn')
  );
}

let _justShowedPopup = false;

// Call right after showLookupPopup from a mouseup handler. A left-click or
// drag's mouseup is always immediately followed by a native click event on
// the same target (a right-click never fires one - only contextmenu) - the
// listener below would otherwise see that follow-up click as "clicked away"
// and close the popup in the same instant it opened. Self-resets on a 0ms
// timeout too, so it can't get stuck true if some gesture skips the click.
function markJustShowedPopup() {
  _justShowedPopup = true;
  setTimeout(() => {
    _justShowedPopup = false;
  }, 0);
}

document.addEventListener('click', (e) => {
  if (_justShowedPopup) {
    _justShowedPopup = false;
    return;
  }
  if (activePopup && !activePopup.contains(e.target) && !isOwnUi(e.target)) {
    closePopup();
  }
});
