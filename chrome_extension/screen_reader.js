// Page-wide "screen reading" mode: when enabled, scans the current page's
// visible text for recognized dictionary/deck words and highlights them
// purple, the same lookup-and-add-to-deck flow as the YouTube subtitle
// overlay (content.js), just applied to any webpage's own text instead of a
// caption box. Off by default - see shared.js's normalizeSettings.
//
// Auto-highlighting uses the CSS Custom Highlight API (CSS.highlights/
// Highlight/Range) instead of wrapping matched words in <span> elements the
// way the subtitle overlay does: that overlay is a line of plain text this
// extension itself owns, but arbitrary page text belongs to someone else's
// DOM (often React/Vue-managed), and splicing <span> tags into it risks
// breaking that page's own rendering or event handlers when it next
// re-renders. The Custom Highlight API draws highlights purely as an
// overlay, with zero DOM mutation - supported in Chrome 105+, which this
// extension already targets.

(function () {
  let settings = normalizeSettings(null);
  let highlightedRanges = []; // [{ range, text, entry }], rebuilt on every rescan
  let pageObserver = null;
  let rescanTimer = null;

  // isOwnUi, markJustShowedPopup, and the click-outside-closes-popup listener
  // live in shared.js - used here too, not just by content.js, so a popup
  // shown from this script closes the same consistent way.

  // Walks the page's text nodes, skipping script/style/input/contenteditable
  // elements, furigana reading annotations (<rt>/<rp> - see groupByBlock's
  // comment for why those specifically matter here), and anything that's
  // part of this extension's own injected UI, plus (as a cheap pre-filter)
  // any node with no Japanese characters at all.
  function collectCandidateTextNodes() {
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
      acceptNode(node) {
        const parent = node.parentElement;
        if (!parent) return NodeFilter.FILTER_REJECT;
        const tag = parent.tagName;
        if (
          tag === 'SCRIPT' ||
          tag === 'STYLE' ||
          tag === 'NOSCRIPT' ||
          tag === 'TEXTAREA' ||
          tag === 'INPUT' ||
          tag === 'RT' ||
          tag === 'RP'
        ) {
          return NodeFilter.FILTER_REJECT;
        }
        if (parent.isContentEditable) return NodeFilter.FILTER_REJECT;
        if (isOwnUi(parent)) return NodeFilter.FILTER_REJECT;
        if (!/[぀-ヿ㐀-鿿]/.test(node.textContent)) return NodeFilter.FILTER_REJECT;
        return NodeFilter.FILTER_ACCEPT;
      },
    });
    const nodes = [];
    let n;
    while ((n = walker.nextNode())) nodes.push(n);
    return nodes;
  }

  const BLOCK_TAGS = new Set([
    'P', 'DIV', 'LI', 'TD', 'TH', 'H1', 'H2', 'H3', 'H4', 'H5', 'H6',
    'BLOCKQUOTE', 'ARTICLE', 'SECTION', 'FIGCAPTION', 'DT', 'DD', 'PRE', 'BODY',
  ]);

  function findBlockAncestor(node) {
    let el = node.parentElement;
    while (el && !BLOCK_TAGS.has(el.tagName)) el = el.parentElement;
    return el || document.body;
  }

  // Many furigana setups (common on Japanese-learning sites) wrap EACH
  // kanji individually in its own <ruby>漢<rt>かん</rt></ruby>, so a
  // multi-character word like 北風 ends up split across two separate text
  // nodes with a reading element in between - scanning each text node in
  // isolation (the original, simpler approach) would never see the full
  // word and would only ever match single characters, if that. Grouping
  // nodes by their nearest block-level ancestor and concatenating them
  // before tokenizing reassembles the word first; a per-character map back
  // to (node, offset) is kept so a match can still be turned into a precise
  // Range afterwards, even one spanning several original text nodes.
  function groupByBlock(nodes) {
    const groups = new Map(); // block element -> text nodes, in document order
    for (const node of nodes) {
      const block = findBlockAncestor(node);
      if (!groups.has(block)) groups.set(block, []);
      groups.get(block).push(node);
    }
    return groups.values();
  }

  function rescanPage() {
    highlightedRanges = [];
    if (!settings.screenReadingEnabled) {
      if (window.Highlight && CSS.highlights) CSS.highlights.delete('ka-screen-highlight');
      return;
    }
    if (!window.Highlight || !CSS.highlights || !lookupIndex) return;

    const ranges = [];
    for (const groupNodes of groupByBlock(collectCandidateTextNodes())) {
      let combined = '';
      const map = []; // map[i] = { node, offset } for combined[i]
      for (const node of groupNodes) {
        const text = node.textContent;
        for (let i = 0; i < text.length; i++) map.push({ node, offset: i });
        combined += text;
      }

      const tokens = tokenizeText(combined, lookupIndex);
      let pos = 0;
      for (const t of tokens) {
        if (t.entry) {
          const first = map[pos];
          const last = map[pos + t.text.length - 1];
          try {
            const range = document.createRange();
            range.setStart(first.node, first.offset);
            range.setEnd(last.node, last.offset + 1);
            ranges.push(range);
            highlightedRanges.push({ range, text: t.text, entry: t.entry });
          } catch (e) {
            // DOM may have changed shape between the walk and here on a
            // fast-mutating page - just skip that one token.
          }
        }
        pos += t.text.length;
      }
    }
    CSS.highlights.set('ka-screen-highlight', new Highlight(...ranges));
  }

  function scheduleRescan() {
    if (rescanTimer) clearTimeout(rescanTimer);
    rescanTimer = setTimeout(rescanPage, 400);
  }

  function isOwnUiNode(n) {
    return n.nodeType === 1 && (isOwnUi(n) || n.matches('.ka-lookup-popup, .ka-hint-toast, .ka-settings-panel'));
  }

  function startObserving() {
    if (pageObserver) return;
    pageObserver = new MutationObserver((mutations) => {
      // Ignore mutations caused only by our own popup/toast elements
      // appearing or disappearing, so showing a lookup popup doesn't
      // trigger its own pointless rescan.
      const relevant = mutations.some((m) => {
        if (isOwnUi(m.target)) return false;
        const touchedOwnUi = [...m.addedNodes, ...m.removedNodes].some(isOwnUiNode);
        return !touchedOwnUi;
      });
      if (relevant) scheduleRescan();
    });
    pageObserver.observe(document.body, { childList: true, subtree: true, characterData: true });
    scheduleRescan();
  }

  function stopObserving() {
    if (pageObserver) {
      pageObserver.disconnect();
      pageObserver = null;
    }
    if (rescanTimer) {
      clearTimeout(rescanTimer);
      rescanTimer = null;
    }
    if (window.Highlight && CSS.highlights) CSS.highlights.delete('ka-screen-highlight');
    highlightedRanges = [];
  }

  // Finds whichever highlighted token (if any) is under the given viewport
  // point - needed because, unlike the subtitle overlay's <span> wrapping,
  // there's no DOM element to hit-test a plain click against here. Each
  // stored highlight keeps its own Range (which, per groupByBlock's comment,
  // may span more than one original text node), so Range.isPointInRange
  // does the containment check directly instead of comparing raw offsets.
  function findHighlightAtPoint(x, y) {
    if (!document.caretRangeFromPoint) return null;
    const caretRange = document.caretRangeFromPoint(x, y);
    if (!caretRange) return null;
    return (
      highlightedRanges.find((h) => h.range.isPointInRange(caretRange.startContainer, caretRange.startOffset)) || null
    );
  }

  document.addEventListener('mouseup', (e) => {
    if (!settings.screenReadingEnabled) return;
    if (isOwnUi(e.target)) return;
    const selection = window.getSelection();
    const text = selection ? selection.toString().trim() : '';

    if (!text) {
      const hit = findHighlightAtPoint(e.clientX, e.clientY);
      if (hit) {
        showLookupPopup(hit.range.getBoundingClientRect(), hit.text, hit.entry);
        markJustShowedPopup();
      }
      return;
    }

    if (!/[぀-ヿ㐀-鿿]/.test(text)) return; // not Japanese - leave normal text selection alone

    if (!lookupIndex) {
      showHintToast('Open the extension and download your data before looking words up.');
      return;
    }

    const range = selection.getRangeAt(0);
    const rect = range.getBoundingClientRect();
    // Deliberately an exact match of the whole selection, not a fuzzy "hunt
    // for any known substring anywhere inside this" search - that only ever
    // surprised people by surfacing some shorter unrelated word buried
    // inside a longer selection instead of respecting what they actually
    // selected. A selection that isn't itself a dictionary entry is shown
    // as-is (the usual "not in dictionary" popup), not narrowed down.
    const entry = lookupIndex.get(text) || null;
    showLookupPopup(rect, text, entry);
    markJustShowedPopup();
  });

  async function applySettings(next) {
    const wasEnabled = settings.screenReadingEnabled;
    settings = next;
    document.documentElement.style.setProperty('--ka-highlight-color', settings.highlightColor);
    if (settings.screenReadingEnabled && !wasEnabled) {
      startObserving();
    } else if (!settings.screenReadingEnabled && wasEnabled) {
      stopObserving();
    } else if (settings.screenReadingEnabled) {
      scheduleRescan();
    }
  }

  chrome.storage.onChanged.addListener(async (changes, area) => {
    if (area !== 'local') return;
    if (changes[KA_STORAGE_KEYS.backup] && settings.screenReadingEnabled) {
      scheduleRescan();
    }
    if (changes[KA_STORAGE_KEYS.settings]) {
      await applySettings(normalizeSettings(changes[KA_STORAGE_KEYS.settings].newValue));
    }
  });

  async function init() {
    await loadBackupAndIndex();
    await applySettings(normalizeSettings(await storageGet(KA_STORAGE_KEYS.settings)));
  }

  init();
})();
