import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'beta_tag.dart';
import 'immersion_word_lookup.dart';
import 'kana_romaji.dart';
import 'ruby_text.dart';
import 'listening_player.dart' show SelectionTranslateCard, WordPopupCard;
import 'study_data.dart';
import 'study_settings.dart';

const Color _accent = Color(0xFF9A00FE);
const double _cardWidth = 260.0;

const String _textScalePrefsKey = 'panel_text_scale';
const String _textColorPrefsKey = 'panel_text_color';
const String _highlightColorPrefsKey = 'panel_highlight_color';
const String _furiganaPrefsKey = 'panel_show_furigana';
const String _romajiPrefsKey = 'panel_show_romaji';
const String _historyPrefsKey = 'panel_show_history';
const String _centerPrefsKey = 'panel_center_subtitles';

const List<Color> _textColorPresets = [
  Colors.white,
  Color(0xFFFFEB3B),
  Color(0xFF00E5FF),
  Color(0xFF69F0AE),
  Color(0xFFFF4081),
  Color(0xFFFFAB40),
];

const List<Color> _highlightColorPresets = [
  _accent,
  Color(0xFFFFEB3B),
  Color(0xFF00E5FF),
  Color(0xFF69F0AE),
  Color(0xFFFF4081),
  Colors.white,
];

// A second way to watch an immersion video, alongside the caption-overlay
// player (video_immersion_player.dart): the video sits on top, and the
// Japanese subtitles are read out of YouTube's caption track and shown in a
// panel underneath, one line per caption, with each word's reading above and
// romaji below. Words are tapped for the same lookup as the overlay player.
//
// The page itself is trimmed down to just the player (see _panelScript), so
// the WebView only ever shows the video.
class VideoSubtitlePanelScreen extends StatefulWidget {
  final String initialUrl;
  final String title;
  final bool isDarkMode;
  const VideoSubtitlePanelScreen({
    super.key,
    required this.initialUrl,
    this.title = 'Subtitle panel',
    required this.isDarkMode,
  });

  @override
  State<VideoSubtitlePanelScreen> createState() => _VideoSubtitlePanelScreenState();
}

class _CaptionLine {
  final String text;
  final List<SentenceToken> tokens;
  // One key per token, so a drag can find which word is under the pointer.
  final List<GlobalKey> keys;
  _CaptionLine(this.text, this.tokens)
    : keys = List.generate(tokens.length, (_) => GlobalKey());
}

class _VideoSubtitlePanelScreenState extends State<VideoSubtitlePanelScreen> {
  Map<String, HighlightEntry> _highlightIndex = {};
  StudySettings _settings = StudySettings();
  bool _loading = true;
  final List<_CaptionLine> _lines = [];
  InAppWebViewController? _webViewController;
  // Browsing (full YouTube page) vs watching a video (player on top, subtitle
  // panel below). The page reports which one it's on after every navigation,
  // so the same WebView just changes size rather than being rebuilt.
  bool _inWatch = false;
  String? _watchVideoId;
  // The phrase being selected by a press-and-drag across one caption line.
  _CaptionLine? _dragLine;
  int? _dragStart;
  int? _dragEnd;
  OverlayEntry? _popup;
  // Panel appearance, saved between launches. A null text colour means the
  // theme's own default.
  double _textScale = 1.0;
  Color? _textColor;
  Color _highlightColor = _accent;
  bool _showFurigana = true;
  bool _showRomaji = true;
  bool _showHistory = false;
  bool _centerSubtitles = true;
  static const String _youtubeHome = 'https://www.youtube.com';

  Color get _fgMuted => widget.isDarkMode ? Colors.white60 : Colors.black54;

  void _onPageState(dynamic raw) {
    if (raw is! Map) return;
    final watch = raw['mode'] == 'watch';
    final videoId = raw['id'] as String?;
    if (watch == _inWatch && videoId == _watchVideoId) return;
    setState(() {
      if (videoId != _watchVideoId) _lines.clear();
      _inWatch = watch;
      _watchVideoId = watch ? videoId : null;
    });
  }

  Future<void> _handleBack() async {
    final controller = _webViewController;
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
      return;
    }
    if (_inWatch) {
      await controller?.loadUrl(urlRequest: URLRequest(url: WebUri(_youtubeHome)));
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final decks = await loadStudyDecks();
    final allCards = [for (final d in decks) ...d.cards];
    final settings = await loadStudySettings();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final textColor = prefs.getInt(_textColorPrefsKey);
    final highlightColor = prefs.getInt(_highlightColorPrefsKey);
    setState(() {
      _highlightIndex = buildHighlightIndex(allCards);
      _settings = settings;
      _textScale = prefs.getDouble(_textScalePrefsKey) ?? 1.0;
      _textColor = textColor == null ? null : Color(textColor);
      _highlightColor = highlightColor == null ? _accent : Color(highlightColor);
      _showFurigana = prefs.getBool(_furiganaPrefsKey) ?? true;
      _showRomaji = prefs.getBool(_romajiPrefsKey) ?? true;
      _showHistory = prefs.getBool(_historyPrefsKey) ?? false;
      _centerSubtitles = prefs.getBool(_centerPrefsKey) ?? true;
      _loading = false;
    });
  }

  void _savePref(Future<dynamic> Function(SharedPreferences prefs) write) async {
    final prefs = await SharedPreferences.getInstance();
    await write(prefs);
  }

  void _setTextScale(double value) {
    setState(() => _textScale = value);
    _savePref((p) => p.setDouble(_textScalePrefsKey, value));
  }

  void _setTextColor(Color? color) {
    setState(() => _textColor = color);
    _savePref((p) => color == null ? p.remove(_textColorPrefsKey) : p.setInt(_textColorPrefsKey, color.toARGB32()));
  }

  void _setHighlightColor(Color color) {
    setState(() => _highlightColor = color);
    _savePref((p) => p.setInt(_highlightColorPrefsKey, color.toARGB32()));
  }

  void _setFlag(String key, bool value, void Function(bool) assign) {
    setState(() => assign(value));
    _savePref((p) => p.setBool(key, value));
  }

  // YouTube's caption text grows word by word within a single line, so an
  // update that extends or trims the newest line replaces it in place rather
  // than stacking near-identical entries.
  void _onCaption(String raw) {
    final text = raw.replaceAll('\n', '').trim();
    if (text.isEmpty || _dragLine != null) return;
    setState(() {
      if (_lines.isNotEmpty && (text.startsWith(_lines.last.text) || _lines.last.text.startsWith(text))) {
        final keep = text.length >= _lines.last.text.length ? text : _lines.last.text;
        if (keep != _lines.last.text) {
          _lines[_lines.length - 1] = _CaptionLine(keep, tokenizeSentence(keep, _highlightIndex));
        }
        return;
      }
      _lines.add(_CaptionLine(text, tokenizeSentence(text, _highlightIndex)));
      if (_lines.length > 50) _lines.removeAt(0);
    });
  }

  void _onTapTokenAt(_CaptionLine line, int index) {
    final token = line.tokens[index];
    final entry = token.entry;
    if (entry != null) {
      _showWordCard(entry, _tokenCenter(line, index));
    } else if (extractKanjiOnly(token.text).isNotEmpty) {
      _showPhraseCard(token.text, _tokenCenter(line, index));
    }
  }

  Offset _tokenCenter(_CaptionLine line, int index) {
    final box = line.keys[index].currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      final size = MediaQuery.of(context).size;
      return Offset(size.width / 2, size.height / 2);
    }
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  // Same floating-card style as Reading and Listening: anchored near the word,
  // no dimmed backdrop, dismissed by tapping anywhere else.
  void _showPopup(Offset anchor, Widget Function(VoidCallback close) buildCard) {
    _closePopup();
    final size = MediaQuery.of(context).size;
    final left = (anchor.dx - _cardWidth / 2).clamp(12.0, size.width - _cardWidth - 12.0);
    final showBelow = anchor.dy < size.height - 300;
    final overlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _closePopup),
          ),
          Positioned(
            left: left,
            top: showBelow ? anchor.dy + 16 : null,
            bottom: showBelow ? null : (size.height - anchor.dy + 16),
            child: buildCard(_closePopup),
          ),
        ],
      ),
    );
    _popup = overlay;
    Overlay.of(context).insert(overlay);
  }

  void _closePopup() {
    _popup?.remove();
    _popup = null;
  }

  void _showWordCard(HighlightEntry entry, Offset anchor) {
    _showPopup(
      anchor,
      (close) => WordPopupCard(
        entry: entry,
        isDarkMode: widget.isDarkMode,
        width: _cardWidth,
        settings: _settings,
        highlightIndex: _highlightIndex,
        onClose: close,
        onAddToDeck: (toAdd) {
          close();
          addImmersionEntryToDeck(context, entry: toAdd, isDarkMode: widget.isDarkMode);
        },
        onEditMemoryTechnique: () {
          close();
          editImmersionMemoryTechnique(context, entry: entry, isDarkMode: widget.isDarkMode);
        },
        onOpenKanji: (kEntry) => _showWordCard(kEntry, anchor),
      ),
    );
  }

  void _showPhraseCard(String text, Offset anchor) {
    _showPopup(
      anchor,
      (close) => SelectionTranslateCard(
        text: text,
        isDarkMode: widget.isDarkMode,
        settings: _settings,
        width: _cardWidth,
        onClose: close,
        highlightIndex: _highlightIndex,
        onAddToDeck: (japanese, translation) {
          close();
          addImmersionRawTextToDeck(context, text: japanese, meaning: translation, isDarkMode: widget.isDarkMode);
        },
      ),
    );
  }

  @override
  void dispose() {
    _closePopup();
    super.dispose();
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
      initialSettings: InAppWebViewSettings(
        mediaPlaybackRequiresUserGesture: false,
        // Same desktop user agent as the overlay player - the caption DOM
        // this reads is the desktop one.
        userAgent:
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
      ),
      initialUserScripts: UnmodifiableListView<UserScript>([
        UserScript(source: _panelScript, injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END),
      ]),
      onWebViewCreated: (controller) {
        _webViewController = controller;
        controller.addJavaScriptHandler(
          handlerName: 'kaCaption',
          callback: (args) {
            if (args.isNotEmpty && args[0] is String) _onCaption(args[0] as String);
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'kaPage',
          callback: (args) {
            if (args.isNotEmpty) _onPageState(args[0]);
          },
        );
      },
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final fg = widget.isDarkMode ? Colors.white : Colors.black87;
          final muted = widget.isDarkMode ? Colors.white54 : Colors.black45;
          Widget heading(String text) => Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.bold)),
          );
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subtitle panel settings', style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.bold)),
                  heading('Text size'),
                  Slider(
                    min: 0.7,
                    max: 1.8,
                    divisions: 11,
                    value: _textScale,
                    label: '${(_textScale * 100).round()}%',
                    activeColor: _accent,
                    onChanged: (v) {
                      _setTextScale(v);
                      setSheetState(() {});
                    },
                  ),
                  heading('Text colour'),
                  _swatchRow(
                    colors: [null, ..._textColorPresets],
                    current: _textColor,
                    onPick: (c) {
                      _setTextColor(c);
                      setSheetState(() {});
                    },
                  ),
                  heading('Highlight colour (known words)'),
                  _swatchRow(
                    colors: _highlightColorPresets,
                    current: _highlightColor,
                    onPick: (c) {
                      _setHighlightColor(c!);
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: _accent,
                    title: Text('Furigana (readings above words)', style: TextStyle(color: fg)),
                    value: _showFurigana,
                    onChanged: (v) {
                      _setFlag(_furiganaPrefsKey, v, (b) => _showFurigana = b);
                      setSheetState(() {});
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: _accent,
                    title: Text('Romaji (below words)', style: TextStyle(color: fg)),
                    value: _showRomaji,
                    onChanged: (v) {
                      _setFlag(_romajiPrefsKey, v, (b) => _showRomaji = b);
                      setSheetState(() {});
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: _accent,
                    title: Text('Previous subtitles', style: TextStyle(color: fg)),
                    subtitle: Text('Keep earlier lines in the panel as the video goes on', style: TextStyle(color: muted, fontSize: 12)),
                    value: _showHistory,
                    onChanged: (v) {
                      _setFlag(_historyPrefsKey, v, (b) => _showHistory = b);
                      setSheetState(() {});
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: _accent,
                    title: Text('Centre subtitles', style: TextStyle(color: fg)),
                    value: _centerSubtitles,
                    onChanged: (v) {
                      _setFlag(_centerPrefsKey, v, (b) => _centerSubtitles = b);
                      setSheetState(() {});
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _swatchRow({
    required List<Color?> colors,
    required Color? current,
    required ValueChanged<Color?> onPick,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in colors)
          GestureDetector(
            onTap: () => onPick(c),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c ?? Colors.transparent,
                border: Border.all(
                  color: c == current ? _accent : Colors.grey,
                  width: c == current ? 3 : 1,
                ),
              ),
              child: c == null ? Text('Auto', style: TextStyle(fontSize: 9, color: widget.isDarkMode ? Colors.white70 : Colors.black54)) : null,
            ),
          ),
      ],
    );
  }

  Widget _buildPanel() {
    if (_lines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Press play - Japanese subtitles appear here as the video runs.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _fgMuted),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // Text grows with the panel's width, so it reads well on a phone and
        // on a wide desktop window alike.
        final scale = (constraints.maxWidth / 400).clamp(0.85, 1.8);
        if (_centerSubtitles) {
          // The newest line sits in the middle of the panel, with earlier lines
          // stacked above it and an empty band below, so it's centred both ways.
          final older = _showHistory ? _lines.length - 1 : 0;
          return Column(
            children: [
              Expanded(
                child: older == 0
                    ? const SizedBox.shrink()
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: older,
                        itemBuilder: (context, index) =>
                            _lineWidget(_lines[_lines.length - 2 - index], false, scale),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _lineWidget(_lines.last, true, scale),
              ),
              const Expanded(child: SizedBox.shrink()),
            ],
          );
        }
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: _showHistory ? _lines.length : 1,
          itemBuilder: (context, index) {
            final line = _lines[_lines.length - 1 - index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _lineWidget(line, index == 0, scale),
            );
          },
        );
      },
    );
  }

  Widget _lineWidget(_CaptionLine line, bool isNewest, double scale) {
    return _CaptionLineView(
      line: line,
      isNewest: isNewest,
      isDarkMode: widget.isDarkMode,
      scale: scale * _textScale,
      textColor: _textColor,
      highlightColor: _highlightColor,
      showFurigana: _showFurigana,
      showRomaji: _showRomaji,
      centerSubtitles: _centerSubtitles,
      selectionStart: _dragLine == line ? _dragStart : null,
      selectionEnd: _dragLine == line ? _dragEnd : null,
      onTapToken: (i) => _onTapTokenAt(line, i),
      onDragStart: (global) => _dragStartAt(line, global),
      onDragMove: (global) => _dragMoveTo(line, global),
      onDragEnd: _dragEndAt,
    );
  }

  int? _tokenIndexAt(_CaptionLine line, Offset global) {
    for (var i = 0; i < line.keys.length; i++) {
      final box = line.keys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      if ((box.localToGlobal(Offset.zero) & box.size).contains(global)) return i;
    }
    return null;
  }

  void _dragStartAt(_CaptionLine line, Offset global) {
    final index = _tokenIndexAt(line, global);
    if (index == null) return;
    setState(() {
      _dragLine = line;
      _dragStart = index;
      _dragEnd = index;
    });
  }

  void _dragMoveTo(_CaptionLine line, Offset global) {
    if (_dragLine != line) return;
    final index = _tokenIndexAt(line, global);
    if (index == null || index == _dragEnd) return;
    setState(() => _dragEnd = index);
  }

  // Looks up the phrase covered by the drag, not just one word: a known word
  // opens its card, anything else (including a phrase of several words not
  // yet in the dictionary) opens the add-to-deck sheet with the full phrase.
  void _dragEndAt() {
    final line = _dragLine;
    final start = _dragStart;
    final end = _dragEnd;
    setState(() {
      _dragLine = null;
      _dragStart = null;
      _dragEnd = null;
    });
    if (line == null || start == null || end == null) return;
    final from = start < end ? start : end;
    final to = start < end ? end : start;
    if (from == to) {
      _onTapTokenAt(line, from);
      return;
    }
    final phrase = line.tokens.sublist(from, to + 1).map((t) => t.text).join();
    final anchor = _tokenCenter(line, to);
    final entry = _highlightIndex[phrase];
    if (entry != null) {
      _showWordCard(entry, anchor);
    } else {
      _showPhraseCard(phrase, anchor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: _inWatch ? 'Back to browsing' : 'Back',
            onPressed: _handleBack,
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(widget.title, overflow: TextOverflow.ellipsis)),
              if (isImmersionBeta) ...[const SizedBox(width: 8), const BetaTag()],
            ],
          ),
          backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          foregroundColor: widget.isDarkMode ? Colors.white : Colors.black87,
          actions: [
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Panel settings',
              onPressed: _loading ? null : _showSettingsSheet,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reload',
              onPressed: () => _webViewController?.reload(),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : LayoutBuilder(
                builder: (context, constraints) {
                  // The WebView stays at the same place in this tree in both
                  // modes - only its height changes - so switching between
                  // browsing and watching doesn't reload the page. Watching
                  // caps the video to about half the height, leaving the
                  // subtitle panel room on a wide desktop window.
                  final videoHeight = _inWatch
                      ? (constraints.maxWidth * 9 / 16).clamp(0.0, constraints.maxHeight * 0.5)
                      : constraints.maxHeight;
                  return Column(
                    children: [
                      SizedBox(width: constraints.maxWidth, height: videoHeight, child: _buildWebView()),
                      if (_inWatch) Expanded(child: _buildPanel()),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _CaptionLineView extends StatelessWidget {
  final _CaptionLine line;
  final bool isNewest;
  final bool isDarkMode;
  final double scale;
  final Color? textColor;
  final Color highlightColor;
  final bool showFurigana;
  final bool showRomaji;
  final bool centerSubtitles;
  final int? selectionStart;
  final int? selectionEnd;
  final ValueChanged<int> onTapToken;
  final ValueChanged<Offset> onDragStart;
  final ValueChanged<Offset> onDragMove;
  final VoidCallback onDragEnd;

  const _CaptionLineView({
    required this.line,
    required this.isNewest,
    required this.isDarkMode,
    required this.scale,
    required this.textColor,
    required this.highlightColor,
    required this.showFurigana,
    required this.showRomaji,
    required this.centerSubtitles,
    required this.selectionStart,
    required this.selectionEnd,
    required this.onTapToken,
    required this.onDragStart,
    required this.onDragMove,
    required this.onDragEnd,
  });

  bool _isSelected(int index) {
    final start = selectionStart;
    final end = selectionEnd;
    if (start == null || end == null) return false;
    final from = start < end ? start : end;
    final to = start < end ? end : start;
    return index >= from && index <= to;
  }

  @override
  Widget build(BuildContext context) {
    // A sideways drag selects straight away; press-and-hold also works. Plain
    // vertical movement is left alone so the panel still scrolls.
    return GestureDetector(
      onHorizontalDragStart: (details) => onDragStart(details.globalPosition),
      onHorizontalDragUpdate: (details) => onDragMove(details.globalPosition),
      onHorizontalDragEnd: (_) => onDragEnd(),
      onLongPressStart: (details) => onDragStart(details.globalPosition),
      onLongPressMoveUpdate: (details) => onDragMove(details.globalPosition),
      onLongPressEnd: (_) => onDragEnd(),
      child: Wrap(
        alignment: centerSubtitles ? WrapAlignment.center : WrapAlignment.start,
        spacing: 4 * scale,
        runSpacing: 12 * scale,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          for (var i = 0; i < line.tokens.length; i++)
            _TokenView(
              key: line.keys[i],
              token: line.tokens[i],
              isDarkMode: isDarkMode,
              emphasized: isNewest,
              scale: scale,
              textColor: textColor,
              highlightColor: highlightColor,
              showFurigana: showFurigana,
              showRomaji: showRomaji,
              selected: _isSelected(i),
              onTap: () => onTapToken(i),
            ),
        ],
      ),
    );
  }
}

class _TokenView extends StatelessWidget {
  final SentenceToken token;
  final bool isDarkMode;
  final bool emphasized;
  final double scale;
  final Color? textColor;
  final Color highlightColor;
  final bool showFurigana;
  final bool showRomaji;
  final bool selected;
  final VoidCallback onTap;

  const _TokenView({
    super.key,
    required this.token,
    required this.isDarkMode,
    required this.emphasized,
    required this.scale,
    required this.textColor,
    required this.highlightColor,
    required this.showFurigana,
    required this.showRomaji,
    required this.selected,
    required this.onTap,
  });

  static final RegExp _kanaOnly = RegExp(r'^[぀-ゟ゠-ヿー]+$');

  @override
  Widget build(BuildContext context) {
    final entry = token.entry;
    final reading = entry?.reading ?? '';

    final knownRomaji = entry?.romaji ?? '';
    final romajiSource = reading.isNotEmpty ? reading : (_kanaOnly.hasMatch(token.text) ? token.text : '');
    final romaji = knownRomaji.isNotEmpty ? knownRomaji : (romajiSource.isEmpty ? '' : kanaToRomaji(romajiSource));

    final muted = isDarkMode ? Colors.white60 : Colors.black54;
    final defaultText = isDarkMode ? Colors.white : Colors.black87;
    final fg = entry != null ? highlightColor : (textColor ?? defaultText);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2 * scale, vertical: 2 * scale),
        decoration: BoxDecoration(
          color: selected ? highlightColor.withValues(alpha: 0.35) : null,
          borderRadius: BorderRadius.circular(4 * scale),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            rubyWord(
              text: token.text,
              reading: reading,
              fontSize: (emphasized ? 26 : 20) * scale,
              textColor: fg,
              rubyColor: muted,
              fontWeight: FontWeight.w600,
              showRuby: showFurigana,
            ),
            if (showRomaji)
              Text(romaji.isEmpty ? ' ' : romaji, style: TextStyle(fontSize: 11 * scale, color: muted)),
          ],
        ),
      ),
    );
  }
}

// Trims YouTube's page down to just the player, reads the caption track's
// visible text out to Flutter, and forces Japanese captions on - the same
// player-API route the overlay player uses (see video_immersion_player.dart).
const String _panelScript = r'''
(function () {
  if (window.__kaPanelInjected) return;
  window.__kaPanelInjected = true;

  const style = document.createElement('style');
  style.textContent = `
    html.ka-watch ytd-masthead, html.ka-watch #masthead-container, html.ka-watch tp-yt-app-drawer,
    html.ka-watch ytd-mini-guide-renderer, html.ka-watch #secondary, html.ka-watch #below,
    html.ka-watch #comments, html.ka-watch #related, html.ka-watch ytd-watch-metadata,
    html.ka-watch ytd-watch-next-secondary-results-renderer, html.ka-watch ytd-merch-shelf-renderer {
      display: none !important;
    }
    html.ka-watch, html.ka-watch body, html.ka-watch ytd-app, html.ka-watch ytd-watch-flexy,
    html.ka-watch ytd-page-manager {
      background: #000 !important;
      margin: 0 !important;
      padding: 0 !important;
      overflow: hidden !important;
    }
    html.ka-watch ytd-watch-flexy #primary {
      padding: 0 !important;
      margin: 0 !important;
      max-width: 100vw !important;
      min-width: 0 !important;
    }
    html.ka-watch ytd-watch-flexy, html.ka-watch #columns, html.ka-watch #primary,
    html.ka-watch #player, html.ka-watch #player-container, html.ka-watch #player-container-outer,
    html.ka-watch #player-wide-container {
      margin: 0 !important;
      padding: 0 !important;
      left: 0 !important;
      width: 100vw !important;
      max-width: 100vw !important;
      min-width: 0 !important;
    }
    html.ka-watch #movie_player {
      position: fixed !important;
      top: 0 !important;
      left: 0 !important;
      width: 100vw !important;
      height: 100vh !important;
    }
    html.ka-watch .html5-video-container {
      position: absolute !important;
      top: 0 !important;
      left: 0 !important;
      width: 100% !important;
      height: 100% !important;
    }
    html.ka-watch video {
      position: absolute !important;
      top: 0 !important;
      left: 0 !important;
      width: 100% !important;
      height: 100% !important;
      object-fit: contain !important;
    }
    html.ka-watch .ytp-caption-window-container {
      opacity: 0 !important;
      pointer-events: none !important;
    }
  `;
  document.documentElement.appendChild(style);

  function syncMode() {
    const watch = location.pathname === '/watch';
    document.documentElement.classList.toggle('ka-watch', watch);
    const id = watch ? new URLSearchParams(location.search).get('v') : null;
    window.flutter_inappwebview.callHandler('kaPage', { mode: watch ? 'watch' : 'browse', id: id });
  }
  document.addEventListener('yt-navigate-finish', syncMode);
  window.addEventListener('popstate', syncMode);
  syncMode();

  function textOf(node) {
    let out = '';
    node.childNodes.forEach(function (n) {
      if (n.nodeType === 3) out += n.nodeValue;
      else if (n.nodeType === 1 && n.tagName !== 'RT' && n.tagName !== 'RP') out += textOf(n);
    });
    return out;
  }

  function currentCaption() {
    const lines = new Map();
    document.querySelectorAll('.ytp-caption-window-container .ytp-caption-segment').forEach(function (s) {
      const parent = s.parentElement;
      lines.set(parent, (lines.get(parent) || '') + textOf(s));
    });
    return Array.from(lines.values()).join('').trim();
  }

  let lastSent = '';
  let frame = 0;
  function emit() {
    frame = 0;
    const text = currentCaption();
    if (!text || text === lastSent) return;
    lastSent = text;
    window.flutter_inappwebview.callHandler('kaCaption', text);
  }
  new MutationObserver(function () {
    if (!frame) frame = requestAnimationFrame(emit);
  }).observe(document.documentElement, { childList: true, subtree: true, characterData: true });

  let tries = 0;
  function forceJapanese() {
    const player = document.getElementById('movie_player');
    if (player && typeof player.loadModule === 'function') {
      try {
        player.loadModule('captions');
        player.setOption('captions', 'track', { languageCode: 'ja' });
        return;
      } catch (e) {}
    }
    if (++tries < 15) setTimeout(forceJapanese, 1000);
  }
  setTimeout(forceJapanese, 1500);
})();
''';
