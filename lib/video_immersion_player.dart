import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'study_data.dart';
import 'study_settings.dart';
import 'listening_player.dart' show WordPopupCard, DeckPickerDialog;

const Color _accent = Color(0xFF9A00FE);
const double _defaultCaptionTextSize = 24;
const String _captionTextSizePrefsKey = 'video_caption_text_size';
const Color _defaultCaptionTextColor = Colors.white;
const String _captionTextColorPrefsKey = 'video_caption_text_color';
const Color _defaultHighlightColor = _accent;
const String _highlightColorPrefsKey = 'video_caption_highlight_color';
const bool _defaultBackgroundEnabled = false;
const String _backgroundEnabledPrefsKey = 'video_caption_background_enabled';

// Hand-picked presets rather than a full RGB picker - plenty for "make the
// subtitles readable against this particular video" without pulling in a
// color-picker package for a one-off setting.
const List<Color> _captionColorPresets = [
  Colors.white,
  Color(0xFFFFEB3B), // yellow
  Color(0xFF00E5FF), // cyan
  Color(0xFF69F0AE), // light green
  Color(0xFFFF4081), // pink
  Color(0xFFFFAB40), // orange
];

const List<Color> _highlightColorPresets = [
  _accent,
  Color(0xFFFFEB3B), // yellow
  Color(0xFF00E5FF), // cyan
  Color(0xFF69F0AE), // light green
  Color(0xFFFF4081), // pink
  Colors.white,
];

String _colorToHex(Color c) => '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

// Plays a YouTube video inside the app with the same clickable-subtitle
// lookup the Chrome extension gives on youtube.com itself - ported here
// rather than shared code, since the extension talks to chrome.storage and
// this talks to a JS<->Dart bridge instead, but the actual trick is
// identical: YouTube's own caption box has text selection deliberately
// disabled, so the injected script mirrors its *displayed* text into a
// plain overlay instead of trying to read the caption track data directly
// (blocked server-side - see the extension's own notes on this). WebView2
// (what flutter_inappwebview uses on Windows) is the same Chromium engine
// the extension already works in, so the same approach carries over.
class VideoImmersionPlayerScreen extends StatefulWidget {
  // Any youtube.com URL to start at - a specific video's watch page, a
  // channel page, or just https://www.youtube.com to browse freely. The
  // caption-lookup script re-injects on every navigation (see
  // initialUserScripts), so it keeps working on whatever video the user
  // navigates to from here, not just the one this screen was opened with.
  final String initialUrl;
  final String title;
  final bool isDarkMode;
  const VideoImmersionPlayerScreen({
    super.key,
    required this.initialUrl,
    this.title = 'YouTube',
    required this.isDarkMode,
  });

  @override
  State<VideoImmersionPlayerScreen> createState() => _VideoImmersionPlayerScreenState();
}

class _VideoImmersionPlayerScreenState extends State<VideoImmersionPlayerScreen> {
  Map<String, HighlightEntry> _highlightIndex = {};
  StudySettings _settings = StudySettings();
  bool _loading = true;
  double _captionTextSize = _defaultCaptionTextSize;
  Color _captionTextColor = _defaultCaptionTextColor;
  Color _highlightColor = _defaultHighlightColor;
  bool _backgroundEnabled = _defaultBackgroundEnabled;
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final decks = await loadStudyDecks();
    final allCards = [for (final d in decks) ...d.cards];
    _settings = await loadStudySettings();
    final prefs = await SharedPreferences.getInstance();
    final savedSize = prefs.getDouble(_captionTextSizePrefsKey);
    final savedColor = prefs.getInt(_captionTextColorPrefsKey);
    final savedHighlightColor = prefs.getInt(_highlightColorPrefsKey);
    final savedBackgroundEnabled = prefs.getBool(_backgroundEnabledPrefsKey);
    if (!mounted) return;
    setState(() {
      _highlightIndex = buildHighlightIndex(allCards);
      if (savedSize != null) _captionTextSize = savedSize;
      if (savedColor != null) _captionTextColor = Color(savedColor);
      if (savedHighlightColor != null) _highlightColor = Color(savedHighlightColor);
      if (savedBackgroundEnabled != null) _backgroundEnabled = savedBackgroundEnabled;
      _loading = false;
    });
  }

  Future<void> _setCaptionTextSize(double size) async {
    setState(() => _captionTextSize = size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_captionTextSizePrefsKey, size);
    await _webViewController?.evaluateJavascript(
      source: "var ov = document.getElementById('ka-overlay'); if (ov) ov.style.fontSize = '${size.round()}px';",
    );
  }

  Future<void> _setCaptionTextColor(Color color) async {
    setState(() => _captionTextColor = color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_captionTextColorPrefsKey, color.toARGB32());
    await _webViewController?.evaluateJavascript(
      source: "var ov = document.getElementById('ka-overlay'); if (ov) ov.style.color = '${_colorToHex(color)}';",
    );
  }

  Future<void> _setHighlightColor(Color color) async {
    setState(() => _highlightColor = color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_highlightColorPrefsKey, color.toARGB32());
    // Set as a CSS custom property (inherited by the .ka-h spans) rather
    // than re-styling each span directly - same approach as the Chrome
    // extension's --ka-highlight-color.
    await _webViewController?.evaluateJavascript(
      source:
          "var ov = document.getElementById('ka-overlay'); "
          "if (ov) ov.style.setProperty('--ka-highlight-color', '${_colorToHex(color)}');",
    );
  }

  Future<void> _setBackgroundEnabled(bool enabled) async {
    setState(() => _backgroundEnabled = enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backgroundEnabledPrefsKey, enabled);
    await _webViewController?.evaluateJavascript(
      source:
          "var ov = document.getElementById('ka-overlay'); "
          "if (ov) ov.classList.toggle('ka-overlay-bg', $enabled);",
    );
  }

  Widget _sheetHeading(String text) => Text(
    text,
    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
  );

  Widget _colorSwatchRow({
    required List<Color> presets,
    required Color current,
    required ValueChanged<Color> onPick,
    required void Function(void Function()) setSheetState,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final color in presets)
          GestureDetector(
            onTap: () {
              setSheetState(() {});
              onPick(color);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: current.toARGB32() == color.toARGB32() ? _accent : Colors.black26,
                  width: current.toARGB32() == color.toARGB32() ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showTextSizeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) => SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _sheetHeading('Subtitle text size'),
                      const Spacer(),
                      Text(
                        '${_captionTextSize.round()}px',
                        style: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black45),
                      ),
                    ],
                  ),
                  Slider(
                    value: _captionTextSize,
                    min: 14,
                    max: 48,
                    divisions: 17,
                    activeColor: _accent,
                    onChanged: (value) {
                      setSheetState(() {});
                      _setCaptionTextSize(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _sheetHeading('Subtitle text color'),
                  const SizedBox(height: 10),
                  _colorSwatchRow(
                    presets: _captionColorPresets,
                    current: _captionTextColor,
                    onPick: _setCaptionTextColor,
                    setSheetState: setSheetState,
                  ),
                  const SizedBox(height: 20),
                  _sheetHeading('Highlighted word color'),
                  const SizedBox(height: 4),
                  Text(
                    'Words recognized from your dictionary/decks.',
                    style: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black45, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  _colorSwatchRow(
                    presets: _highlightColorPresets,
                    current: _highlightColor,
                    onPick: _setHighlightColor,
                    setSheetState: setSheetState,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: _accent,
                    title: Text(
                      'Dark background behind subtitles',
                      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                    ),
                    subtitle: Text(
                      'Helps readability on bright or busy video.',
                      style: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black45, fontSize: 12),
                    ),
                    value: _backgroundEnabled,
                    onChanged: (value) {
                      setSheetState(() {});
                      _setBackgroundEnabled(value);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Only reading/meaning are needed on the JS side - everything else
  // (memory technique, deck membership, kanji breakdown) is looked back up
  // from _highlightIndex on the Dart side once a word's tapped, where the
  // full HighlightEntry already lives.
  String _buildIndexJson() {
    final simplified = {
      for (final e in _highlightIndex.entries) e.key: {'reading': e.value.reading, 'meaning': e.value.meaning},
    };
    // JSON allows the U+2028/U+2029 line separators, which are NOT valid
    // inside a JS script unescaped - vanishingly unlikely in practice here,
    // but cheap to guard against a hard-to-diagnose script syntax error.
    return jsonEncode(simplified).replaceAll('\u2028', '\\u2028').replaceAll('\u2029', '\\u2029');
  }

  String _buildInjectedScript() {
    return '''
(function () {
  if (window.__kaInjected) return;
  window.__kaInjected = true;

  // Surfaces uncaught JS errors (including from YouTube's own scripts) and
  // unhandled promise rejections into Flutter's debug log via
  // onConsoleMessage - cheap safety net for a page this far outside what
  // this extension was originally built against.
  window.addEventListener('error', function (e) {
    console.error('[KA page error] ' + e.message + ' @ ' + e.filename + ':' + e.lineno);
  });
  window.addEventListener('unhandledrejection', function (e) {
    const reason = e.reason && e.reason.message ? e.reason.message : e.reason;
    console.error('[KA page rejection] ' + reason);
  });

  const index = new Map(Object.entries(${_buildIndexJson()}));

  function tokenizeText(text) {
    const tokens = [];
    if (index.size === 0) return [{ text: text, known: false }];
    const maxLen = Math.max(...Array.from(index.keys(), (k) => k.length));
    let i = 0;
    while (i < text.length) {
      let matched = null;
      const longest = Math.min(maxLen, text.length - i);
      for (let len = longest; len >= 1; len--) {
        const candidate = text.substring(i, i + len);
        if (index.has(candidate)) { matched = candidate; break; }
      }
      if (matched) {
        tokens.push({ text: matched, known: true });
        i += matched.length;
      } else {
        const last = tokens[tokens.length - 1];
        if (last && !last.known) last.text += text[i];
        else tokens.push({ text: text[i], known: false });
        i += 1;
      }
    }
    return tokens;
  }

  // Builds DOM nodes directly rather than an HTML string assigned via
  // innerHTML - this page enforces a Trusted Types CSP (require-trusted-
  // types-for 'script'), which throws on any plain-string innerHTML
  // assignment. createElement/appendChild/replaceChildren are unaffected,
  // since they're not HTML-parsing APIs.
  function renderLineInto(container, line) {
    container.replaceChildren();
    for (const t of tokenizeText(line)) {
      if (t.known) {
        const span = document.createElement('span');
        span.className = 'ka-h';
        span.dataset.w = t.text;
        span.textContent = t.text;
        container.appendChild(span);
      } else {
        container.appendChild(document.createTextNode(t.text));
      }
    }
  }

  const style = document.createElement('style');
  style.textContent =
    // opacity/pointer-events, not display:none - removing the native
    // caption box from layout entirely risks breaking YouTube's own
    // Subtitles/CC settings submenu if its internal JS tries to measure or
    // touch that element while building the language list; keeping it
    // present (just invisible and non-interactive) avoids that risk while
    // still getting out of the way of the custom overlay drawn below.
    '.ytp-caption-window-container { opacity: 0 !important; pointer-events: none !important; }' +
    '#ka-overlay { position: absolute; left: 5%; right: 5%; bottom: 8%; text-align: center; z-index: 60;' +
    ' pointer-events: auto; font-size: ${_captionTextSize.round()}px; line-height: 1.4; color: ${_colorToHex(_captionTextColor)};' +
    ' --ka-highlight-color: ${_colorToHex(_highlightColor)};' +
    ' text-shadow: 1px 1px 2px #000, -1px -1px 2px #000, 1px -1px 2px #000, -1px 1px 2px #000;' +
    ' font-family: "YouTube Noto", Roboto, "Arial Unicode MS", Arial, sans-serif;' +
    ' white-space: pre-line; cursor: text; user-select: text; }' +
    '#ka-overlay:empty { display: none; }' +
    // Same backdrop the Chrome extension's "Dark background behind
    // subtitles" toggle uses - a bar behind the whole line, not a box fitted
    // to the text, since the overlay already spans a fixed width.
    '#ka-overlay.ka-overlay-bg { background: rgba(0, 0, 0, 0.7); padding: 4px 0; border-radius: 4px; }' +
    '.ka-h { color: var(--ka-highlight-color, #9a00fe); cursor: pointer; }' +
    ' .ka-h:hover { text-decoration: underline; }';
  document.head.appendChild(style);

  let overlay = null;
  function ensureOverlay() {
    const host = document.getElementById('movie_player') || document.querySelector('.html5-video-player');
    if (!host) return null;
    if (overlay && overlay.isConnected) return overlay;
    overlay = document.createElement('div');
    overlay.id = 'ka-overlay';
    if ($_backgroundEnabled) overlay.classList.add('ka-overlay-bg');
    host.appendChild(overlay);
    return overlay;
  }

  function findCaptionContainer() {
    return document.querySelector('.ytp-caption-window-container');
  }

  function syncOverlay() {
    const ov = ensureOverlay();
    if (!ov) return;
    const container = findCaptionContainer();
    const segments = container ? Array.from(container.querySelectorAll('.ytp-caption-segment')) : [];
    if (!segments.length) { ov.replaceChildren(); return; }
    const lastSegment = segments[segments.length - 1];
    const lastLineParent = lastSegment.parentElement;
    const currentLineSegments = lastLineParent
      ? segments.filter((s) => s.parentElement === lastLineParent)
      : [lastSegment];
    const line = currentLineSegments.map((el) => (el.textContent || '').trim()).filter(Boolean).join('');
    if (line) {
      renderLineInto(ov, line);
    } else {
      ov.replaceChildren();
    }
  }

  let captionObserver = null;
  let observedContainer = null;
  function ensureCaptionObserver() {
    const container = findCaptionContainer();
    if (!container || container === observedContainer) return;
    if (captionObserver) captionObserver.disconnect();
    captionObserver = new MutationObserver(syncOverlay);
    captionObserver.observe(container, { childList: true, subtree: true, characterData: true });
    observedContainer = container;
    syncOverlay();
  }

  setInterval(function () { ensureCaptionObserver(); syncOverlay(); }, 1000);

  function withinOverlay(node) { return overlay && overlay.contains(node); }

  // Same mid-drag protection as the app's YouTube Chrome extension: captions
  // advance on their own timer, so rebuilding the overlay while a selection
  // is in progress would destroy the text nodes it's anchored to and make
  // the selection jump/expand unpredictably.
  let isSelecting = false;

  document.addEventListener('mousedown', function (e) {
    if (!withinOverlay(e.target)) return;
    isSelecting = true;
    const video = document.querySelector('video');
    if (video && !video.paused) video.pause();
  });

  document.addEventListener('mouseup', function (e) {
    const wasSelecting = isSelecting;
    isSelecting = false;
    if (!withinOverlay(e.target)) {
      if (wasSelecting) syncOverlay();
      return;
    }
    const selection = window.getSelection();
    const text = selection ? selection.toString().trim() : '';
    if (!text) {
      const span = e.target.closest ? e.target.closest('.ka-h') : null;
      if (span) window.flutter_inappwebview.callHandler('kaWordTapped', span.dataset.w);
      if (wasSelecting) syncOverlay();
      return;
    }
    if (wasSelecting) syncOverlay();
    // Exact match only, not a fuzzy "any known word inside this" search -
    // see the Chrome extension's own notes on why that fallback was removed:
    // it surprised people by surfacing a shorter unrelated word instead of
    // respecting the actual selection. Dart decides known-vs-not from here.
    window.flutter_inappwebview.callHandler('kaWordTapped', text);
  });

  // Forces captions on in Japanese via the player's own JS API, rather than
  // the visual Subtitles/CC menu - diagnostics showed that menu's language
  // submenu consistently failing to open inside this embedded browser (the
  // click falls through to the raw video element instead), with no JS error
  // or rejection to explain why. #movie_player on the real watch page (same
  // origin, unlike a cross-origin iframe) is the actual player widget
  // instance and exposes setOption/loadModule directly - the same calls the
  // menu would make internally if it worked, just invoked directly instead
  // of depending on a UI interaction that doesn't currently work here.
  // Retries a few times since the player API may not be attached yet the
  // instant the page finishes loading.
  let __kaCaptionAttempts = 0;
  function tryForceJapaneseCaptions() {
    __kaCaptionAttempts++;
    const player = document.getElementById('movie_player');
    if (player && typeof player.loadModule === 'function') {
      try {
        player.loadModule('captions');
        player.setOption('captions', 'track', { languageCode: 'ja' });
        console.log('[KA captions] forced ja track via player API');
        return;
      } catch (e) {
        console.error('[KA captions] setOption failed: ' + e.message);
      }
    }
    if (__kaCaptionAttempts < 10) setTimeout(tryForceJapaneseCaptions, 1000);
    else {
      // Fall back to clicking the CC button for at least *a* caption track,
      // if the player API route never became available.
      const ccButton = document.querySelector('.ytp-subtitles-button');
      if (ccButton && ccButton.getAttribute('aria-pressed') === 'false') ccButton.click();
    }
  }
  setTimeout(tryForceJapaneseCaptions, 1500);
})();
''';
  }

  void _showKnownWordSheet(HighlightEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: WordPopupCard(
          entry: entry,
          isDarkMode: widget.isDarkMode,
          width: double.infinity,
          settings: _settings,
          highlightIndex: _highlightIndex,
          onClose: () => Navigator.pop(context),
          onAddToDeck: () {
            Navigator.pop(context);
            _addEntryToDeck(entry);
          },
          onEditMemoryTechnique: () {
            Navigator.pop(context);
            _editMemoryTechnique(entry);
          },
          onOpenKanji: (kEntry) {
            Navigator.pop(context);
            _showKnownWordSheet(kEntry);
          },
        ),
      ),
    );
  }

  void _showUnknownTextSheet(String text) {
    final meaningController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Not in your dictionary/decks",
              style: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black45, fontSize: 12),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                final url = 'https://translate.google.com/?sl=ja&tl=en&text=${Uri.encodeComponent(text)}&op=translate';
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.translate, color: _accent),
              label: const Text("Open in Google Translate", style: TextStyle(color: _accent)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: meaningController,
              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: "English meaning (optional, for adding to a deck)",
                hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                filled: true,
                fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
                onPressed: () async {
                  Navigator.pop(context);
                  await _addRawTextToDeck(text, meaningController.text.trim());
                },
                child: const Text("Add to deck"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addEntryToDeck(HighlightEntry entry) async {
    final decks = await loadStudyDecks();
    if (!mounted) return;
    final chosen = await showDialog<StudyDeck>(
      context: context,
      builder: (context) => DeckPickerDialog(decks: decks, isDarkMode: widget.isDarkMode),
    );
    if (chosen == null || !mounted) return;

    final card = StudyCard(
      japanese: entry.japanese,
      hiragana: entry.reading,
      english: entry.meaning,
      kanjiVGCodes: findKanjiVGCodesForWord(entry.japanese),
    );
    chosen.cards.add(card);
    await saveStudyDecks(decks);
    if (!mounted) return;
    entry.isDeckWord = true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added "${entry.japanese}" to ${chosen.name}')));
  }

  Future<void> _addRawTextToDeck(String text, String meaning) async {
    final decks = await loadStudyDecks();
    if (!mounted) return;
    final chosen = await showDialog<StudyDeck>(
      context: context,
      builder: (context) => DeckPickerDialog(decks: decks, isDarkMode: widget.isDarkMode),
    );
    if (chosen == null || !mounted) return;

    final card = StudyCard(japanese: text, hiragana: '', english: meaning);
    chosen.cards.add(card);
    await saveStudyDecks(decks);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added "$text" to ${chosen.name}')));
  }

  Future<void> _editMemoryTechnique(HighlightEntry entry) async {
    final controller = TextEditingController(text: entry.memoryTechnique);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          entry.memoryTechnique.isEmpty ? "Add Memory Technique" : "Edit Memory Technique",
          style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: "e.g. a mnemonic or memory aid",
            hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
            filled: true,
            fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Save"),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;

    final technique = result.trim();
    entry.memoryTechnique = technique;
    entry.card?.memoryTechnique = technique;

    final decks = await loadStudyDecks();
    var changed = false;
    for (final deck in decks) {
      for (final card in deck.cards) {
        if (card.japanese.trim() == entry.japanese) {
          card.memoryTechnique = technique;
          changed = true;
        }
      }
    }
    if (changed) await saveStudyDecks(decks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: widget.isDarkMode ? Colors.white : Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            tooltip: 'Back',
            onPressed: () async {
              if (await _webViewController?.canGoBack() ?? false) {
                _webViewController?.goBack();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload page',
            onPressed: () => _webViewController?.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.format_size),
            tooltip: 'Subtitle appearance',
            onPressed: _loading ? null : _showTextSizeSheet,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : InAppWebView(
              // Back to the full watch page (not /embed/): the embed player
              // is meant to be loaded inside an iframe on someone else's
              // page, not navigated to directly as a standalone page like
              // this does - diagnostics showed its Subtitles/CC submenu
              // click consistently falling through to the raw video element,
              // which looks like exactly the kind of thing that mismatch
              // could cause. The actual "no captions" bug turned out to be
              // this script's own innerHTML/Trusted-Types crash, now fixed,
              // so there's no longer a reason to prefer the embed player.
              initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
              initialSettings: InAppWebViewSettings(
                mediaPlaybackRequiresUserGesture: false,
                userAgent:
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                    '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
              ),
              initialUserScripts: UnmodifiableListView<UserScript>([
                UserScript(
                  source: _buildInjectedScript(),
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
                ),
              ]),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                controller.addJavaScriptHandler(
                  handlerName: 'kaWordTapped',
                  callback: (args) {
                    final text = args.isNotEmpty ? args[0] as String : '';
                    if (text.isEmpty) return;
                    final entry = _highlightIndex[text];
                    if (entry != null) {
                      _showKnownWordSheet(entry);
                    } else {
                      _showUnknownTextSheet(text);
                    }
                  },
                );
              },
              // Temporary diagnostic: forwards the page's own JS console
              // (including YouTube's own script errors, via the injected
              // window.onerror hook below) into Flutter's debug log, so the
              // Subtitles/CC submenu failure can be diagnosed from a real
              // error instead of guessing at CSS/DOM causes blind.
              onConsoleMessage: (controller, consoleMessage) {
                debugPrint('[KA webview console] ${consoleMessage.messageLevel}: ${consoleMessage.message}');
              },
            ),
    );
  }
}
