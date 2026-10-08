import 'dart:math';
import 'package:flutter/material.dart';
import 'grammar_data.dart';
import 'immersion_word_lookup.dart';
import 'listening_player.dart' show SelectionTranslateCard, WordPopupCard;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ruby_text.dart';
import 'study_data.dart';
import 'study_settings.dart';

const Color _accent = Color(0xFF9A00FE);

// What each form means, used by the "why" note when a fill-in answer is wrong.
const Map<String, String> _formNotes = {
  'です': 'the polite "is / am / are"',
  'でした': 'the polite "was / were"',
  'だ': 'the casual "is"',
  'だった': 'the casual "was"',
  'じゃない': 'the casual "is not"',
  'ではない': 'the formal "is not"',
  'くない': 'the "not" form of い-adjectives',
  'かった': 'the past form of い-adjectives',
  'くなかった': 'the past "not" form of い-adjectives',
  "は": "the topic marker",
  "が": "the subject marker",
  "を": "the object marker",
  "へ": "the direction marker",
  "に": "the destination, time or place marker",
  "で": "the at, in or with marker",
  "の": "the belonging marker",
  "と": "the and, with marker",
  "も": "the also, too marker",
  "か": "the question marker",
};

// Runs of Japanese text (kana, kanji, and Japanese punctuation).
final RegExp _japaneseRun = RegExp(r'[　-〿぀-ヿ㐀-鿿！-ﾟ]+');

List<String> _sentenceBeats(String text) => text
    .split('. ')
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .map((s) => RegExp(r'[.?!]$').hasMatch(s) ? s : '$s.')
    .toList();

// Splits one explanation bullet into separate reveal beats instead of
// showing the whole rule and its worked example in one lump: each sentence
// of the rule gets its own "Next" first, then - if the bullet ends with a
// worked example after a colon, e.g. "Drop い, add くない: 寒い becomes
// 寒くない (not cold)." - a final "For example: ..." beat.
//
// A bullet can also end with one or more "~~"-separated extra beats, shown
// after the example - for a worked example whose English translation
// implies something the Japanese doesn't actually say (a dropped subject,
// most often), e.g. "...: 夫です (he is my husband).~~Here, \"he\" is
// implied.~~It literally means: husband is."
//
// The text after the colon only counts as a worked example if it has a
// "(...)" English gloss - a colon used mid-sentence just for ordinary
// clarification (not every lesson has a worked example in its first
// bullet) is left alone and the whole bullet is just split sentence by
// sentence instead.
List<String> _explanationBeats(String line) {
  final segments = line.split('~~');
  final main = segments.first;
  final extraBeats = segments.skip(1).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  final colonIndex = main.indexOf(':');
  final examplePart = colonIndex == -1 ? '' : main.substring(colonIndex + 1).trim();
  if (colonIndex == -1 || !examplePart.contains('(')) {
    final sentences = _sentenceBeats(main);
    return [...(sentences.isEmpty ? [main] : sentences), ...extraBeats];
  }
  final rulePart = main.substring(0, colonIndex).trim();
  final sentences = _sentenceBeats(rulePart);
  if (sentences.isEmpty) return [main, ...extraBeats];
  return [...sentences, 'For example: $examplePart', ...extraBeats];
}

// One grammar lesson's activity: the plain explanation, a breakdown of the
// first example sentence (tap a word or a button to reveal more), the other
// examples, then fill in the form, rebuild each sentence from its pieces, and
// write a sentence of your own to share on Skool. Every Japanese word shows
// its reading above it, and each line or sentence appears one press of Next.
class GrammarLessonActivity extends StatefulWidget {
  final GrammarPoint point;
  final bool isDarkMode;
  final VoidCallback onDone;
  final ValueNotifier<double>? progress;

  const GrammarLessonActivity({
    super.key,
    required this.point,
    required this.isDarkMode,
    required this.onDone,
    this.progress,
  });

  @override
  State<GrammarLessonActivity> createState() => GrammarLessonActivityState();
}

enum _Phase { simple, breakdown, examples, related, fillIn, build, create }

class GrammarLessonActivityState extends State<GrammarLessonActivity> {
  _Phase _phase = _Phase.simple;
  int _sentence = 0;

  // How many items of the current page are showing (see _simpleItems and
  // the examples page).
  int _revealed = 0;

  // The dictionary, for furigana and for looking up each breakdown word.
  final Map<String, HighlightEntry> _index = buildHighlightIndex(const []);
  int? _selectedToken;
  List<GlobalKey>? _selectedKeys;
  OverlayEntry? _popup;
  StudySettings _settings = StudySettings();
  final Map<int, List<GlobalKey>> _exampleKeys = {};
  late final List<GlobalKey> _tokenKeys = List.generate(
    _breakdownTokens(widget.point.sentences.first).length,
    (_) => GlobalKey(),
  );
  bool _showTranslation = false;
  bool _showGrammar = false;

  // Fill-in phase.
  List<String> _choices = [];
  String? _picked;

  // Build phase.
  List<String> _pool = [];
  final List<String> _answer = [];
  bool _buildCorrect = false;
  bool _buildTried = false;

  @override
  void initState() {
    super.initState();
    loadStudySettings().then((settings) {
      if (mounted) setState(() => _settings = settings);
    });
  }

  @override
  void dispose() {
    _popup?.remove();
    _popup = null;
    super.dispose();
  }

  Color get _fg => widget.isDarkMode ? Colors.white : Colors.black87;
  Color get _fgMuted => widget.isDarkMode ? Colors.white60 : Colors.black54;
  Color get _cardBg => widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100]!;

  GrammarSentence get _current => widget.point.sentences[_sentence];

  List<String> get _simpleItems => [
    widget.point.form,
    'It means "${widget.point.meaning}".',
    for (final line in widget.point.explanation) ..._explanationBeats(line),
  ];

  void _startFillIn() {
    setState(() {
      _phase = _Phase.fillIn;
      _sentence = 0;
      _setupFillIn();
    });
  }

  // Answers and choices are remembered per sentence, so going back shows what
  // was already done instead of starting it again.
  final Map<int, String> _fillAnswers = {};
  final Map<int, List<String>> _fillChoices = {};
  final Set<int> _buildDone = {};

  void _setupFillIn() {
    _picked = _fillAnswers[_sentence];
    _choices = _fillChoices.putIfAbsent(_sentence, () => List.of(widget.point.formChoices)..shuffle(Random()));
  }

  void _nextFillIn() {
    setState(() {
      if (_sentence < widget.point.sentences.length - 1) {
        _sentence++;
        _setupFillIn();
      } else {
        _phase = _Phase.build;
        _sentence = 0;
        _setupBuild();
      }
    });
  }

  void _setupBuild() {
    final chunks = _current.chunks;
    if (_buildDone.contains(_sentence)) {
      _pool = [];
      _answer
        ..clear()
        ..addAll(chunks);
      _buildCorrect = true;
      _buildTried = false;
      return;
    }
    final shuffled = List.of(chunks)..shuffle(Random());
    // Keep reshuffling so the pieces never start already in the right order.
    while (chunks.length > 1 && _sameOrder(shuffled, chunks)) {
      shuffled.shuffle(Random());
    }
    _pool = shuffled;
    _answer.clear();
    _buildCorrect = false;
    _buildTried = false;
  }

  bool _sameOrder(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _nextBuild() {
    setState(() {
      if (_sentence < widget.point.sentences.length - 1) {
        _sentence++;
        _setupBuild();
      } else {
        _phase = _Phase.create;
      }
    });
  }

  void _goToBreakdown() {
    setState(() {
      _phase = _Phase.breakdown;
      _selectedToken = null;
      _showTranslation = false;
      _showGrammar = false;
    });
  }

  // -1 shows only the intro; each Next press reveals one related form.
  void _startRelated() {
    setState(() {
      _phase = _Phase.related;
      _revealed = -1;
    });
  }

  void _goToExamples() {
    setState(() {
      _phase = _Phase.examples;
      _revealed = 0;
    });
  }

  // Earlier items on a reveal page fade back so the newest one is the focus.
  Widget _focusable({required bool focused, required Widget child}) => AnimatedOpacity(
    duration: const Duration(milliseconds: 300),
    opacity: focused ? 1.0 : 0.35,
    child: child,
  );

  // Shared Next button for the pages that reveal one item per press.
  void _advanceReveal(int total, VoidCallback onFinished) {
    setState(() {
      if (_revealed < total - 1) {
        _revealed++;
      } else {
        onFinished();
      }
    });
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: _fgMuted, fontSize: 15, fontWeight: FontWeight.w600)),
  );

  Widget _nextButton(String label, VoidCallback onPressed) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: _accent,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    onPressed: onPressed,
    child: Text(label),
  );

  // Japanese text with each word's reading above it.
  Widget _furigana(String text, {double fontSize = 22, Color? color, Color? japaneseColor, FontWeight? japaneseWeight, FontWeight weight = FontWeight.w500}) {
    return _FuriganaText(
      text: text,
      index: _index,
      fontSize: fontSize,
      color: color ?? _fg,
      japaneseColor: japaneseColor ?? color ?? _fg,
      japaneseWeight: japaneseWeight ?? weight,
      muted: _fgMuted,
      weight: weight,
    );
  }

  Widget _simple() {
    final items = _simpleItems;
    final shown = items.take(_revealed + 1).toList();
    final isLast = _revealed >= items.length - 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown.length; i++)
          _focusable(
            focused: i == shown.length - 1,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: i == 0
                  ? _thisIsRow()
                  : i == 1
                      ? Text(shown[i], textAlign: TextAlign.center, style: TextStyle(color: _fg, fontSize: 28, fontWeight: FontWeight.w700))
                      : _furigana(shown[i], fontSize: 22, weight: FontWeight.w400, japaneseColor: _accent, japaneseWeight: FontWeight.bold),
            ),
          ),
        const SizedBox(height: 16),
        _nextButton('Next', () {
          if (isLast) {
            _goToBreakdown();
          } else {
            setState(() => _revealed++);
          }
        }),
      ],
    );
  }

  Widget _thisIsRow() => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.end,
    spacing: 14,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text('This is', style: TextStyle(color: _fgMuted, fontSize: 24)),
      ),
      _furigana(widget.point.form, fontSize: 64, color: _accent, weight: FontWeight.bold),
    ],
  );

  // Opens a card next to the tapped word, like Reading and Listening do - it
  // floats over the page rather than growing it.
  void _showCardAt(
    Offset anchor,
    Widget Function(VoidCallback close) buildCard, {
    void Function(Offset tapped)? onOutsideTap,
  }) {
    _popup?.remove();
    final size = MediaQuery.of(context).size;
    const width = 260.0;
    final left = (anchor.dx - width / 2).clamp(12.0, size.width - width - 12.0);
    final showBelow = anchor.dy < size.height - 300;
    void close() {
      _popup?.remove();
      _popup = null;
      if (mounted) {
        setState(() {
          _selectedToken = null;
          _selectedKeys = null;
        });
      }
    }

    final overlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (details) {
                close();
                onOutsideTap?.call(details.globalPosition);
              },
            ),
          ),
          Positioned(
            left: left,
            top: showBelow ? anchor.dy + 16 : null,
            bottom: showBelow ? null : (size.height - anchor.dy + 16),
            child: buildCard(close),
          ),
        ],
      ),
    );
    _popup = overlay;
    Overlay.of(context).insert(overlay);
  }

  void _showWordCard(
    HighlightEntry entry,
    Offset anchor, {
    void Function(Offset tapped)? onOutsideTap,
  }) {
    _showCardAt(
      anchor,
      onOutsideTap: onOutsideTap,
      (close) => WordPopupCard(
        entry: entry,
        isDarkMode: widget.isDarkMode,
        width: 260,
        settings: _settings,
        highlightIndex: _index,
        onClose: close,
        onAddToDeck: (toAdd) {
          close();
          addImmersionEntryToDeck(context, entry: toAdd, isDarkMode: widget.isDarkMode);
        },
        onEditMemoryTechnique: () {
          close();
          editImmersionMemoryTechnique(context, entry: entry, isDarkMode: widget.isDarkMode);
        },
        onOpenKanji: (kEntry) => _showWordCard(kEntry, anchor, onOutsideTap: onOutsideTap),
      ),
    );
  }

  List<GlobalKey> _keysFor(GrammarSentence s, int count) =>
      _exampleKeys.putIfAbsent(s.tatoebaId, () => List.generate(count, (_) => GlobalKey()));

  int? _tokenIndexAt(Offset global, List<GlobalKey> keys, int count) {
    for (var i = 0; i < count; i++) {
      final box = keys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      if ((box.localToGlobal(Offset.zero) & box.size).contains(global)) return i;
    }
    return null;
  }

  void _showTokenPopup(int index, List<SentenceToken> tokens, List<GlobalKey> keys) {
    final token = tokens[index];
    final box = keys[index].currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final anchor = box.localToGlobal(box.size.center(Offset.zero));
    final entry = token.entry;
    setState(() {
      _selectedKeys = keys;
      _selectedToken = index;
    });
    void openTappedWord(Offset tapped) {
      final next = _tokenIndexAt(tapped, keys, tokens.length);
      if (next != null) _showTokenPopup(next, tokens, keys);
    }

    if (entry != null) {
      _showWordCard(entry, anchor, onOutsideTap: openTappedWord);
    } else if (extractKanjiOnly(token.text).isEmpty) {
      // A question mark right after it means it's likely being used as a
      // casual question marker (行くの？) rather than its own taught sense.
      final isQuestionContext = index + 1 < tokens.length && tokens[index + 1].text == '？';
      final questionUse = isQuestionContext ? grammarQuestionUseOf(token.text) : null;
      final lesson = grammarPointForForm(token.text);
      if (questionUse != null) {
        _showCardAt(
          anchor,
          (close) => _GrammarFormCard(
            form: token.text,
            meaning: questionUse.meaning,
            explanation: [questionUse.note],
            index: _index,
            isDarkMode: widget.isDarkMode,
            onClose: close,
          ),
          onOutsideTap: openTappedWord,
        );
      } else if (lesson != null) {
        _showCardAt(
          anchor,
          (close) => _GrammarFormCard(
            form: lesson.form,
            meaning: lesson.meaning,
            explanation: lesson.explanation,
            index: _index,
            isDarkMode: widget.isDarkMode,
            onClose: close,
          ),
          onOutsideTap: openTappedWord,
        );
      } else {
        _showCardAt(
          anchor,
          (close) => _NoEntryCard(text: token.text, isDarkMode: widget.isDarkMode, onClose: close),
          onOutsideTap: openTappedWord,
        );
      }
    } else {
      _showCardAt(
        anchor,
        (close) => SelectionTranslateCard(
          text: token.text,
          isDarkMode: widget.isDarkMode,
          settings: _settings,
          width: 260,
          onClose: close,
          highlightIndex: _index,
          onAddToDeck: (japanese, translation) {
            close();
            addImmersionRawTextToDeck(context, text: japanese, meaning: translation, isDarkMode: widget.isDarkMode);
          },
        ),
        onOutsideTap: openTappedWord,
      );
    }
  }

  // Splits the sentence around its grammar form so the form is one word,
  // even when the dictionary only knows its parts (e.g. でした).
  List<SentenceToken> _breakdownTokens(GrammarSentence s) {
    final at = s.japanese.indexOf(s.target);
    if (at < 0) return tokenizeSentence(s.japanese, _index);
    final before = s.japanese.substring(0, at);
    final after = s.japanese.substring(at + s.target.length);
    final targetEntry = _index[s.target] ??
        HighlightEntry(japanese: s.target, reading: s.target, meaning: widget.point.meaning);
    return [
      if (before.isNotEmpty) ..._beforeTargetTokens(before, s.target),
      SentenceToken(s.target, targetEntry),
      if (after.isNotEmpty) ...tokenizeSentence(after, _index),
    ];
  }

  // Tokenizes the text right before the grammar form, correcting for the
  // common case where the END of that text is really just the start of one
  // word whose ending the target cut off (寒 + くない, cut out of 寒くない;
  // or 試験は難し + くなかった, where only 難し itself - not 試験は too - is
  // the stem that continues into the target). Tries [before]'s own longest
  // trailing stem first, shortening it until stem+target matches a real
  // word, so a stem looked up on its own doesn't instead match an unrelated
  // entry (bare "寒" is also a kanji-reference entry read さむい, the
  // adjective's full kun'yomi - wrong for just this one kanji here).
  // Whatever's left before that stem (試験は) is tokenized normally.
  //
  // Prefers the conjugation table (via conjugatedEntryFor) over the plain
  // tokenizer for the stem+target lookup specifically because a
  // kWordReadingOverrides entry for the same surface text (寒かった, say)
  // would otherwise shadow it and carry no meaning - so tapping the stem
  // would show nothing. The conjugation table's entry always has the base
  // word's own meaning, which becomes "Stem of 寒い (Cold)" rather than
  // leaving the tapped fragment unexplained.
  //
  // Falls back to tokenizing [before] entirely normally when no trailing
  // stem of it turns out to be the start of a longer recognised word.
  List<SentenceToken> _beforeTargetTokens(String before, String target) {
    for (var stemLen = before.length; stemLen >= 1; stemLen--) {
      final prefix = before.substring(0, before.length - stemLen);
      final stem = before.substring(before.length - stemLen);
      final whole = stem + target;
      final wholeTokens = tokenizeSentence(whole, _index);
      final plainEntry = wholeTokens.length == 1 ? wholeTokens.first.entry : null;
      final entry = conjugatedEntryFor(whole, _index) ?? plainEntry;
      if (entry == null || entry.reading.contains(',') || entry.reading.length <= target.length) continue;
      final reading = entry.reading.substring(0, entry.reading.length - target.length);
      final base = entry.dictionaryForm;
      final meaning = base != null && entry.meaning.isNotEmpty ? 'Stem of ${base.japanese} (${entry.meaning})' : entry.meaning;
      return [
        if (prefix.isNotEmpty) ...tokenizeSentence(prefix, _index),
        SentenceToken(stem, HighlightEntry(japanese: stem, reading: reading, meaning: meaning)),
      ];
    }
    return tokenizeSentence(before, _index);
  }

  // Renders the text right before a target form with furigana, going
  // through _beforeTargetTokens instead of the plain _furigana helper so a
  // fragment like 寒 (cut out of 寒くない) gets its reading correctly
  // trimmed from the whole word instead of matching an unrelated entry.
  Widget _beforeTargetText(String before, String target, {double fontSize = 34, FontWeight weight = FontWeight.bold}) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final token in _beforeTargetTokens(before, target))
          rubyWord(
            text: token.text,
            reading: token.entry?.reading ?? '',
            fontSize: fontSize,
            textColor: _fg,
            rubyColor: _fgMuted,
            fontWeight: weight,
          ),
      ],
    );
  }

  Widget _breakdown() {
    final point = widget.point;
    final s = point.sentences.first;
    final tokens = _breakdownTokens(s);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionLabel('Break it down - tap a word'),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 14,
          children: [
            for (var i = 0; i < tokens.length; i++)
              _TokenButton(
                key: _tokenKeys[i],
                text: tokens[i].text,
                reading: extractKanjiOnly(tokens[i].text).isEmpty ? '' : (tokens[i].entry?.reading ?? ''),
                selected: identical(_selectedKeys, _tokenKeys) && _selectedToken == i,
                isTarget: tokens[i].text == s.target,
                isDarkMode: widget.isDarkMode,
                onTap: () => _showTokenPopup(i, tokens, _tokenKeys),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _furigana(s.japanese, fontSize: 34, weight: FontWeight.bold),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            _revealButton('translation', _showTranslation, () => setState(() {
                  _showTranslation = !_showTranslation;
                  _showGrammar = false;
                })),
            _revealButton('grammar', _showGrammar, () => setState(() {
                  _showGrammar = !_showGrammar;
                  _showTranslation = false;
                })),
          ],
        ),
        if (_showTranslation)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(s.english, textAlign: TextAlign.center, style: TextStyle(color: _fg, fontSize: 20)),
          ),
        if (_showGrammar)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              children: [
                for (final paragraph in point.explanation)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _furigana(paragraph, fontSize: 18, weight: FontWeight.w400, japaneseColor: _accent, japaneseWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        _nextButton('More examples', _goToExamples),
      ],
    );
  }

  Widget _revealButton(String label, bool shown, VoidCallback onTap) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      foregroundColor: _accent,
      side: const BorderSide(color: _accent),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      textStyle: const TextStyle(fontSize: 16),
    ),
    onPressed: onTap,
    child: Text(shown ? 'Hide $label' : 'Show $label'),
  );

  Widget _tappableSentence(GrammarSentence s) {
    final tokens = _breakdownTokens(s);
    final keys = _keysFor(s, tokens.length);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 10,
      children: [
        for (var i = 0; i < tokens.length; i++)
          _TokenButton(
            key: keys[i],
            text: tokens[i].text,
            reading: extractKanjiOnly(tokens[i].text).isEmpty ? '' : (tokens[i].entry?.reading ?? ''),
            selected: identical(_selectedKeys, keys) && _selectedToken == i,
            isTarget: tokens[i].text == s.target,
            isDarkMode: widget.isDarkMode,
            onTap: () => _showTokenPopup(i, tokens, keys),
          ),
      ],
    );
  }

  Widget _examples() {
    final more = widget.point.sentences.skip(1).toList();
    final shown = more.take(_revealed + 1).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionLabel('More examples'),
        for (var i = 0; i < shown.length; i++)
          Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _tappableSentence(shown[i]),
                  const SizedBox(height: 8),
                  _focusable(
                    focused: true,
                    child: Column(
                      children: [
                        Text(shown[i].english, textAlign: TextAlign.center, style: TextStyle(color: _fgMuted, fontSize: 18)),
                        const SizedBox(height: 6),
                        Text(
                          'Sentence by ${shown[i].contributor} on Tatoeba (CC BY 2.0 FR)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _fgMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 16),
        _nextButton('Next', () => _advanceReveal(more.length, _startRelated)),
      ],
    );
  }

  Widget _related() {
    final items = widget.point.related;
    final shown = items.take(_revealed + 1).toList();
    final isLast = _revealed >= items.length - 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionLabel('Similar grammar'),
        Text(
          'Just an introduction - you do not need to memorise these. They are here to compare with ${widget.point.form}.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _fgMuted, fontSize: 16),
        ),
        const SizedBox(height: 20),
        for (final r in shown)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _furigana(r.form, fontSize: 36, color: _accent, japaneseWeight: FontWeight.bold),
                const SizedBox(height: 6),
                Text(r.meaning, textAlign: TextAlign.center, style: TextStyle(color: _fg, fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _furigana(r.note, fontSize: 16, weight: FontWeight.w400, japaneseColor: _accent, japaneseWeight: FontWeight.bold),
                if (r.tip != null) _tipDropdown(r.tip!),
              ],
            ),
          ),
        const SizedBox(height: 16),
        _nextButton(isLast ? 'Start practice' : 'Next', () => _advanceReveal(items.length, _startFillIn)),
      ],
    );
  }

  // A real-life usage aside for a related form, collapsed in its own
  // dropdown so it doesn't clutter the main note.
  Widget _tipDropdown(String tip) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(color: _accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: _accent,
          collapsedIconColor: _fgMuted,
          title: Text('Real-life tip', style: TextStyle(color: _accent, fontSize: 14, fontWeight: FontWeight.w600)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            _furigana(tip, fontSize: 15, weight: FontWeight.w400, japaneseColor: _accent, japaneseWeight: FontWeight.bold),
          ],
        ),
      ),
    );
  }

  // Explains only the form that was picked, collapsed in a dropdown so it
  // doesn't give the answer away.
  Widget _whyCard(String picked) {
    final pickedNote = _formNotes[picked] ?? 'a different form';
    return Container(
      width: 460,
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: _accent,
          collapsedIconColor: _fgMuted,
          title: Text('Why?', textAlign: TextAlign.center, style: TextStyle(color: _accent, fontSize: 16)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              '$picked is $pickedNote, so it does not fit this sentence.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _fg, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // A few meaning words also commonly show up contracted in a translation
  // (です's "is" as part of "it's illegal!") - checked after the plain word
  // itself comes up empty.
  static const Map<String, List<String>> _meaningContractions = {
    'is': ["it's", "that's", "he's", "she's", "what's", "there's", "here's", "who's", "this's"],
    'am': ["i'm"],
    'are': ["we're", "you're", "they're"],
  };

  // Bolds and colours the word in an English translation that matches this
  // point's own meaning (です -> "is", もう -> "already"...), so picking the
  // right form and recognising its meaning reinforce each other. Tries each
  // candidate from meaning split on " / " in turn (and a contracted form of
  // it, e.g. "it's" for "is"); falls back to plain muted text if none of
  // them appear in the translation as a whole word (common for particles
  // like は/が, whose meaning is grammatical rather than a literal word).
  Widget _highlightedEnglish(String english, {double fontSize = 20}) {
    final candidates = widget.point.meaning.split(' / ').map((c) => c.trim()).where((c) => c.isNotEmpty);
    final options = candidates.expand((c) => [c, ...?_meaningContractions[c.toLowerCase()]]);
    for (final option in options) {
      final match = RegExp(r'\b' + RegExp.escape(option) + r'\b', caseSensitive: false).firstMatch(english);
      if (match == null) continue;
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(color: _fgMuted, fontSize: fontSize),
          children: [
            TextSpan(text: english.substring(0, match.start)),
            TextSpan(
              text: english.substring(match.start, match.end),
              style: TextStyle(color: _accent, fontWeight: FontWeight.bold),
            ),
            TextSpan(text: english.substring(match.end)),
          ],
        ),
      );
    }
    return Text(english, textAlign: TextAlign.center, style: TextStyle(color: _fgMuted, fontSize: fontSize));
  }

  // A point whose form has more than one variant (て / てください, じゃない
  // / ではない...) accepts any of them as correct for any sentence, not just
  // the one literal variant that particular Tatoeba sentence happened to
  // use - they are interchangeable, so swapping one for another is still a
  // valid sentence.
  Set<String> get _formVariants => widget.point.form.split(' / ').map((v) => v.trim()).toSet();

  Widget _fillIn() {
    final s = _current;
    final index = s.japanese.indexOf(s.target);
    final before = s.japanese.substring(0, index);
    final after = s.japanese.substring(index + s.target.length);
    final correct = _picked != null && _formVariants.contains(_picked);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionLabel('Fill in the form (${_sentence + 1}/${widget.point.sentences.length})'),
        _highlightedEnglish(s.english),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            if (before.isNotEmpty) _beforeTargetText(before, s.target),
            if (correct)
              _furigana(_picked!, fontSize: 34, japaneseColor: _accent, japaneseWeight: FontWeight.bold)
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('＿＿＿', style: TextStyle(color: _fg, fontSize: 34, fontWeight: FontWeight.bold)),
              ),
            if (after.isNotEmpty) _furigana(after, fontSize: 34, weight: FontWeight.bold),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final choice in _choices)
              ChoiceChip(
                label: Text(choice, style: const TextStyle(fontSize: 20)),
                selected: _picked == choice,
                selectedColor: _accent.withValues(alpha: 0.3),
                onSelected: (_) => setState(() {
                  _picked = choice;
                  if (_formVariants.contains(choice)) _fillAnswers[_sentence] = choice;
                }),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (_picked != null)
          Text(
            correct ? 'Correct!' : 'Not quite - try another form.',
            style: TextStyle(color: correct ? Colors.green : Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 18),
          ),
        if (_picked != null && !correct) _whyCard(_picked!),
        const SizedBox(height: 18),
        if (correct) _nextButton('Next', _nextFillIn),
      ],
    );
  }

  // A build-the-sentence piece is just one of the chunk strings, possibly
  // shuffled out of order - so its furigana is found by first computing the
  // reading for the WHOLE original sentence (so a conjugated word like
  // 寒くない is matched as one word, not split into an unrelated standalone
  // "寒"), then slicing out whichever part of that reading belongs to this
  // one piece.
  Widget _chunkFurigana(GrammarSentence s, String piece, {double fontSize = 22}) {
    final chunkIndex = s.chunks.indexOf(piece);
    if (chunkIndex == -1) return _furigana(piece, fontSize: fontSize);
    var offset = 0;
    for (var i = 0; i < chunkIndex; i++) {
      offset += s.chunks[i].length;
    }
    final end = offset + piece.length;
    final segments = <RubySegment>[];
    var cursor = 0;
    for (final token in tokenizeSentence(s.japanese, _index)) {
      for (final seg in rubySegmentsFor(token.text, token.entry?.reading ?? '')) {
        final segStart = cursor;
        final segEnd = cursor + seg.text.length;
        cursor = segEnd;
        if (segEnd <= offset || segStart >= end) continue;
        // A segment can straddle where this piece starts or ends (a kana
        // block like なくない spans both the end of 危な and all of くない)
        // - clip it to just the part inside [offset, end) instead of
        // including it whole on both sides. Only safe to drop characters
        // off a kana segment (empty ruby already); a kanji segment with a
        // real reading should always land fully inside one piece, since
        // chunks are always split on word boundaries - if one somehow
        // doesn't, the ruby is dropped rather than shown for the wrong
        // slice of it.
        final sliceStart = (offset - segStart).clamp(0, seg.text.length);
        final sliceEnd = (end - segStart).clamp(0, seg.text.length);
        if (sliceStart >= sliceEnd) continue;
        final fullyIncluded = sliceStart == 0 && sliceEnd == seg.text.length;
        segments.add(RubySegment(seg.text.substring(sliceStart, sliceEnd), fullyIncluded ? seg.ruby : ''));
      }
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final seg in segments)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(seg.ruby.isEmpty ? ' ' : seg.ruby, style: TextStyle(fontSize: fontSize * 0.45, color: _fgMuted)),
              Text(seg.text, style: TextStyle(fontSize: fontSize, color: _fg, fontWeight: FontWeight.w500)),
            ],
          ),
      ],
    );
  }

  Widget _build() {
    final s = _current;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionLabel('Build the sentence (${_sentence + 1}/${widget.point.sentences.length})'),
        _highlightedEnglish(s.english),
        const SizedBox(height: 18),
        DragTarget<_BuildDrag>(
          onWillAcceptWithDetails: (details) => !_buildCorrect,
          onAcceptWithDetails: (details) => _moveBuildPiece(details.data, _answer.length, toAnswer: true),
          builder: (context, candidate, rejected) => Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
              border: candidate.isNotEmpty ? Border.all(color: Colors.white54, width: 2) : null,
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _answer.length; i++)
                  DragTarget<_BuildDrag>(
                    onWillAcceptWithDetails: (details) => !_buildCorrect,
                    onAcceptWithDetails: (details) => _moveBuildPiece(details.data, i, toAnswer: true),
                    builder: (context, candidate, rejected) => _buildPiece(
                      _BuildDrag(fromAnswer: true, index: i, piece: _answer[i]),
                      ActionChip(
                        label: _chunkFurigana(s, _answer[i]),
                        onPressed: _buildCorrect ? null : () => setState(() => _pool.add(_answer.removeAt(i))),
                      ),
                      highlighted: candidate.isNotEmpty,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        DragTarget<_BuildDrag>(
          onWillAcceptWithDetails: (details) => details.data.fromAnswer && !_buildCorrect,
          onAcceptWithDetails: (details) => _moveBuildPiece(details.data, _pool.length, toAnswer: false),
          builder: (context, candidate, rejected) => Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 60),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: candidate.isNotEmpty ? Border.all(color: Colors.white54, width: 2) : null,
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < _pool.length; i++)
                  _buildPiece(
                    _BuildDrag(fromAnswer: false, index: i, piece: _pool[i]),
                    ActionChip(
                      label: _chunkFurigana(s, _pool[i]),
                      onPressed: _buildCorrect
                          ? null
                          : () => setState(() {
                              _answer.add(_pool.removeAt(i));
                              _buildTried = false;
                            }),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (_buildTried && !_buildCorrect)
          const Text(
            'Not quite - tap a piece in the sentence to take it back.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 18),
          ),
        if (_buildCorrect)
          const Text('Correct!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 18)),
        const SizedBox(height: 18),
        if (!_buildCorrect)
          _nextButton('Check', _answer.isEmpty
              ? () {}
              : () => setState(() {
                    _buildTried = true;
                    _buildCorrect = _sameOrder(_answer, _current.chunks);
                    if (_buildCorrect) _buildDone.add(_sentence);
                  })),
        if (_buildCorrect) _nextButton('Next', _nextBuild),
      ],
    );
  }

  // A piece can be dragged between the sentence row and the pool. Once the
  // sentence is correct the pieces are locked in place.
  Widget _buildPiece(_BuildDrag drag, Widget chip, {bool highlighted = false}) {
    if (_buildCorrect) return chip;
    return Draggable<_BuildDrag>(
      data: drag,
      feedback: Material(color: Colors.transparent, child: chip),
      childWhenDragging: Opacity(opacity: 0.35, child: chip),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: highlighted ? Border.all(color: Colors.white54, width: 2) : null,
        ),
        child: chip,
      ),
    );
  }

  // Takes a piece out of where it was and puts it at toIndex in the target row.
  void _moveBuildPiece(_BuildDrag drag, int toIndex, {required bool toAnswer}) {
    setState(() {
      _buildTried = false;
      (drag.fromAnswer ? _answer : _pool).removeAt(drag.index);
      if (toAnswer) {
        var at = toIndex;
        if (drag.fromAnswer && drag.index < toIndex) at--;
        _answer.insert(at.clamp(0, _answer.length), drag.piece);
      } else {
        _pool.add(drag.piece);
      }
    });
  }

  bool _reviewingSentences = false;

  Widget _create() {
    return _CreativeSentence(
      point: widget.point,
      isDarkMode: widget.isDarkMode,
      onDone: widget.onDone,
      index: _index,
      onReviewing: (reviewing) => setState(() => _reviewingSentences = reviewing),
    );
  }

  // Steps back one slide within the activity. Returns false once already on
  // the first slide, so the lesson can go back to its intro instead.
  bool goBack() {
    switch (_phase) {
      case _Phase.simple:
        if (_revealed == 0) return false;
        setState(() => _revealed--);
        return true;
      case _Phase.breakdown:
        setState(() {
          _phase = _Phase.simple;
          _revealed = _simpleItems.length - 1;
        });
        return true;
      case _Phase.examples:
        if (_revealed > 0) {
          setState(() => _revealed--);
          return true;
        }
        setState(() {
          _phase = _Phase.breakdown;
          _selectedToken = null;
          _showTranslation = false;
          _showGrammar = false;
        });
        return true;
      case _Phase.related:
        if (_revealed >= 0) {
          setState(() => _revealed--);
          return true;
        }
        setState(() {
          _phase = _Phase.examples;
          _revealed = widget.point.sentences.length - 2;
        });
        return true;
      case _Phase.fillIn:
        if (_sentence > 0) {
          setState(() {
            _sentence--;
            _setupFillIn();
          });
          return true;
        }
        setState(() {
          _phase = _Phase.related;
          _revealed = widget.point.related.length - 1;
        });
        return true;
      case _Phase.build:
        if (_sentence > 0) {
          setState(() {
            _sentence--;
            _setupBuild();
          });
          return true;
        }
        setState(() {
          _phase = _Phase.fillIn;
          _sentence = widget.point.sentences.length - 1;
          _setupFillIn();
        });
        return true;
      case _Phase.create:
        setState(() {
          _phase = _Phase.build;
          _sentence = widget.point.sentences.length - 1;
          _setupBuild();
        });
        return true;
    }
  }

  // One unit per slide, example, related form, sentence and the final
  // writing step, so the bar moves on every press.
  double get _progressFraction {
    final point = widget.point;
    final simpleCount = _simpleItems.length;
    final examplesCount = point.sentences.length - 1;
    final relatedCount = point.related.length;
    final sentenceCount = point.sentences.length;
    final baseBreakdown = simpleCount;
    final baseExamples = baseBreakdown + 1;
    final baseRelated = baseExamples + examplesCount;
    final baseFill = baseRelated + relatedCount + 1;
    final baseBuild = baseFill + sentenceCount;
    final baseCreate = baseBuild + sentenceCount;
    final total = baseCreate + 1;
    double done;
    if (_phase == _Phase.simple) {
      done = (_revealed + 1).toDouble();
    } else if (_phase == _Phase.breakdown) {
      done = baseBreakdown + 1.0;
    } else if (_phase == _Phase.examples) {
      done = baseExamples + _revealed + 1.0;
    } else if (_phase == _Phase.related) {
      done = baseRelated + _revealed + 2.0;
    } else if (_phase == _Phase.fillIn) {
      done = baseFill + _sentence + 0.0;
    } else if (_phase == _Phase.build) {
      done = baseBuild + _sentence + 0.0;
    } else {
      done = _reviewingSentences ? total.toDouble() : baseCreate + 0.5;
    }
    return (done / total).clamp(0.0, 1.0);
  }

  Widget _body() {
    switch (_phase) {
      case _Phase.simple:
        return _simple();
      case _Phase.breakdown:
        return _breakdown();
      case _Phase.examples:
        return _examples();
      case _Phase.related:
        return _related();
      case _Phase.fillIn:
        return _fillIn();
      case _Phase.build:
        return _build();
      case _Phase.create:
        return _create();
    }
  }

  // Centres each page vertically when it's short, and scrolls when it isn't.
  Widget _centeredPage(Widget child) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
        child: Center(child: child),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final fraction = _progressFraction;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.progress?.value = fraction;
    });
    return _centeredPage(_body());
  }
}

// Japanese text with a reading above every word that has kanji. Other text
// (English, punctuation) is laid out word by word around it.
class _FuriganaText extends StatelessWidget {
  final String text;
  final Map<String, HighlightEntry> index;
  final double fontSize;
  final Color color;
  final Color japaneseColor;
  final FontWeight japaneseWeight;
  final Color muted;
  final FontWeight weight;

  const _FuriganaText({
    required this.text,
    required this.index,
    required this.fontSize,
    required this.color,
    required this.japaneseColor,
    required this.japaneseWeight,
    required this.muted,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    final pieces = <Widget>[];
    var last = 0;
    for (final match in _japaneseRun.allMatches(text)) {
      if (match.start > last) pieces.addAll(_plain(text.substring(last, match.start)));
      pieces.add(_japanese(match.group(0)!));
      last = match.end;
    }
    if (last < text.length) pieces.addAll(_plain(text.substring(last)));
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: fontSize * 0.2,
      runSpacing: fontSize * 0.3,
      children: pieces,
    );
  }

  List<Widget> _plain(String s) => [
    for (final word in s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty))
      Text(word, style: TextStyle(fontSize: fontSize, color: color, fontWeight: weight)),
  ];

  Widget _japanese(String run) {
    final tokens = tokenizeSentence(run, index);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final token in tokens)
          rubyWord(
            text: token.text,
            reading: token.entry?.reading ?? '',
            fontSize: fontSize,
            textColor: japaneseColor,
            rubyColor: muted,
            fontWeight: japaneseWeight,
          ),
      ],
    );
  }
}

// A piece of a build-the-sentence step, with where it came from.
class _BuildDrag {
  final bool fromAnswer;
  final int index;
  final String piece;

  const _BuildDrag({required this.fromAnswer, required this.index, required this.piece});
}

class _TokenButton extends StatelessWidget {
  final String text;
  final String reading;
  final bool selected;
  final bool isTarget;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _TokenButton({
    super.key,
    required this.text,
    required this.reading,
    required this.selected,
    required this.isTarget,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fill = selected ? _accent : (isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200]!);
    final fg = selected
        ? Colors.white
        : (isTarget ? _accent : (isDarkMode ? Colors.white : Colors.black87));
    final muted = selected ? Colors.white70 : (isDarkMode ? Colors.white60 : Colors.black54);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent, width: 1.5),
        ),
        child: rubyWord(
          text: text,
          reading: reading,
          fontSize: 28,
          textColor: fg,
          rubyColor: muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// The explanation for a grammar form (か, の, ...) that showed up as a word
// with no dictionary entry of its own - either its own lesson's explanation,
// or, when the context fits (grammarQuestionUseOf), a related form's note
// instead, e.g. の explained as a casual question marker rather than belonging.
class _GrammarFormCard extends StatelessWidget {
  final String form;
  final String meaning;
  final List<String> explanation;
  final Map<String, HighlightEntry> index;
  final bool isDarkMode;
  final VoidCallback onClose;

  const _GrammarFormCard({
    required this.form,
    required this.meaning,
    required this.explanation,
    required this.index,
    required this.isDarkMode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDarkMode ? Colors.white : Colors.black87;
    final muted = isDarkMode ? Colors.white60 : Colors.black54;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        constraints: const BoxConstraints(maxHeight: 320),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12)],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(form, style: const TextStyle(color: _accent, fontSize: 26, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close, size: 18, color: muted),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(meaning, style: TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              for (final paragraph in explanation)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _FuriganaText(
                    text: paragraph,
                    index: index,
                    fontSize: 15,
                    color: fg,
                    japaneseColor: _accent,
                    japaneseWeight: FontWeight.bold,
                    muted: muted,
                    weight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoEntryCard extends StatelessWidget {
  final String text;
  final bool isDarkMode;
  final VoidCallback onClose;

  const _NoEntryCard({required this.text, required this.isDarkMode, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final fg = isDarkMode ? Colors.white : Colors.black87;
    final muted = isDarkMode ? Colors.white60 : Colors.black54;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: TextStyle(color: fg, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Punctuation or a grammar ending - there is no dictionary entry for it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onClose, child: const Text('Close')),
          ],
        ),
      ),
    );
  }
}

// The write-your-own step: a box for your words, the grammar point, then a box
// for the ending (a full stop, a question mark, and so on). Tapping an idea
// word puts it into whichever box was used last, then the sentence is copied
// for Skool.
class _CreativeSentence extends StatefulWidget {
  final GrammarPoint point;
  final bool isDarkMode;
  final VoidCallback onDone;
  final Map<String, HighlightEntry> index;
  final ValueChanged<bool> onReviewing;

  const _CreativeSentence({
    required this.point,
    required this.isDarkMode,
    required this.onDone,
    required this.index,
    required this.onReviewing,
  });

  @override
  State<_CreativeSentence> createState() => _CreativeSentenceState();
}

// One finished sentence: the words before the grammar form and the ending after it.
class _SavedSentence {
  final String before;
  final String middle;
  final String after;

  const _SavedSentence(this.before, this.middle, this.after);
}

// Writes several sentences, one page each. Add sentence saves the one being
// written and opens a fresh page with the saved ones shown on top, each with
// a pencil to edit it. Finish shows every sentence to copy into Skool.
class _CreativeSentenceState extends State<_CreativeSentence> {
  static const String _skoolUrl = 'https://www.skool.com/kanji-athletes-5541';

  final TextEditingController _before = TextEditingController();
  final TextEditingController _after = TextEditingController();
  final FocusNode _beforeFocus = FocusNode();
  final FocusNode _afterFocus = FocusNode();
  late TextEditingController _target;
  final List<_SavedSentence> _saved = [];
  // The saved sentence being edited, so it's put back in the same place.
  int? _editingIndex;
  bool _reviewing = false;
  bool _copied = false;
  List<String> _ideas = const [];
  List<String> _studiedPool = const [];
  // A point like て / てください or じゃない / ではない offers more than one
  // variant - the middle segment becomes a dropdown so the learner picks
  // which one each sentence uses, instead of it always being the first.
  late final List<String> _formVariants = widget.point.form.split(' / ');
  late String _selectedVariant = _formVariants.first;

  @override
  void initState() {
    super.initState();
    _target = _before;
    _ideas = widget.point.vocabInspiration.take(6).toList();
    _beforeFocus.addListener(() {
      if (_beforeFocus.hasFocus) _target = _before;
    });
    _afterFocus.addListener(() {
      if (_afterFocus.hasFocus) _target = _after;
    });
    _loadIdeas();
  }

  @override
  void dispose() {
    _before.dispose();
    _after.dispose();
    _beforeFocus.dispose();
    _afterFocus.dispose();
    super.dispose();
  }

  // Ideas come from words already studied on a deck (vocabulary cards that have
  // been reviewed), mixed with this grammar point's own list.
  Future<void> _loadIdeas() async {
    final decks = await loadStudyDecks();
    final studied = <String>{};
    for (final deck in decks) {
      for (final card in deck.cards) {
        if (card.cardType != 'Vocab') continue;
        if (card.repetitions == 0 && card.nextReviewDate == null) continue;
        studied.add(card.japanese.trim());
      }
    }
    _studiedPool = studied.toList();
    if (mounted) _pickIdeas();
  }

  // Picks six ideas, preferring words not already on screen so refresh always
  // brings something new.
  void _pickIdeas() {
    final everything = {..._studiedPool, ...widget.point.vocabInspiration}.toList();
    final fresh = everything.where((w) => !_ideas.contains(w)).toList()..shuffle(Random());
    final pool = fresh.length >= 6 ? fresh : (List.of(everything)..shuffle(Random()));
    setState(() => _ideas = pool.take(6).toList());
  }

  void _insert(String word) {
    final text = _target.text;
    final sel = _target.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final newText = text.replaceRange(start, end, word);
    _target.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + word.length),
    );
    setState(() => _copied = false);
  }

  String _sentenceText(String before, String middle, String after) => '${before.trim()}$middle${after.trim()}';

  bool get _hasDraft => _before.text.trim().isNotEmpty;

  _SavedSentence get _draft => _SavedSentence(_before.text.trim(), _selectedVariant, _after.text.trim());

  void _clearDraft() {
    _before.clear();
    _after.clear();
    _editingIndex = null;
  }

  // Saves what's in the fields. While editing, the saved sentence is replaced
  // in place; otherwise it's added to the end and becomes the one being edited,
  // so it stays highlighted.
  void _saveDraft() {
    final at = _editingIndex;
    if (at != null) {
      _saved[at] = _draft;
    } else {
      _saved.add(_draft);
      _editingIndex = _saved.length - 1;
    }
  }

  void _saveSentence() {
    if (!_hasDraft) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a sentence first.')),
      );
      return;
    }
    setState(() {
      _saveDraft();
      _copied = false;
    });
  }

  // Saves the sentence and starts a fresh page for the next one.
  void _addSentence() {
    if (!_hasDraft) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a sentence first.')),
      );
      return;
    }
    setState(() {
      _saveDraft();
      _clearDraft();
      _copied = false;
    });
  }

  // Saves whatever is being written first, then loads the chosen sentence.
  void _editSaved(int index) {
    setState(() {
      if (_hasDraft) _saveDraft();
      _editingIndex = index;
      _before.text = _saved[index].before;
      _after.text = _saved[index].after;
      _selectedVariant = _saved[index].middle;
      _copied = false;
    });
  }

  // Removes a saved sentence. If it's the one being edited, the fields are
  // cleared; if it sits before the one being edited, that one's position shifts.
  void _deleteSaved(int index) {
    setState(() {
      _saved.removeAt(index);
      final editing = _editingIndex;
      if (editing == null) return;
      if (editing == index) {
        _clearDraft();
      } else if (editing > index) {
        _editingIndex = editing - 1;
      }
      _copied = false;
    });
  }

  void _finish() {
    if (!_hasDraft && _saved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write at least one sentence first.')),
      );
      return;
    }
    setState(() {
      if (_hasDraft) _saveDraft();
      _clearDraft();
      _reviewing = true;
      _copied = false;
    });
    widget.onReviewing(true);
  }

  Future<void> _copyAll() async {
    final text = _saved.map((s) => _sentenceText(s.before, s.middle, s.after)).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied - paste them into a new Skool post.')),
    );
    await launchUrl(Uri.parse(_skoolUrl), mode: LaunchMode.externalApplication);
  }

  Color get _fg => widget.isDarkMode ? Colors.white : Colors.black87;
  Color get _fgMuted => widget.isDarkMode ? Colors.white60 : Colors.black54;
  Color get _cardBg => widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100]!;

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: _cardBg,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
  );

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(color: _fgMuted, fontSize: 15, fontWeight: FontWeight.w600),
    ),
  );

  Widget _sentenceCard(String text, {Widget? trailing, bool highlighted = false}) {
    final fg = highlighted ? Colors.white : _fg;
    final muted = highlighted ? Colors.white70 : _fgMuted;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? _accent : _cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FuriganaText(
              text: text,
              index: widget.index,
              fontSize: 22,
              color: fg,
              japaneseColor: fg,
              japaneseWeight: FontWeight.w500,
              muted: muted,
              weight: FontWeight.w500,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _writingPage() {
    final point = widget.point;
    final editing = _editingIndex != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Make 3 sentences for best results.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _fg, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        if (_saved.isNotEmpty) ...[
          _heading('Your sentences so far'),
          for (var i = 0; i < _saved.length; i++)
            _sentenceCard(
              _sentenceText(_saved[i].before, _saved[i].middle, _saved[i].after),
              highlighted: i == _editingIndex,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: i == _editingIndex ? Colors.white : _accent),
                    tooltip: 'Edit this sentence',
                    onPressed: () => _editSaved(i),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: i == _editingIndex ? Colors.white : _fgMuted),
                    tooltip: 'Delete this sentence',
                    onPressed: () => _deleteSaved(i),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
        ],
        _heading(editing
            ? 'Editing sentence ${_editingIndex! + 1}'
            : 'Sentence ${_saved.length + 1} - your turn, use $_selectedVariant'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _before,
                focusNode: _beforeFocus,
                maxLines: null,
                style: TextStyle(color: _fg, fontSize: 22),
                decoration: _decoration('Your words'),
                onChanged: (_) => setState(() => _copied = false),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _formVariants.length > 1
                  ? DropdownButton<String>(
                      value: _selectedVariant,
                      underline: const SizedBox.shrink(),
                      dropdownColor: _cardBg,
                      style: const TextStyle(color: _accent, fontSize: 30, fontWeight: FontWeight.bold),
                      items: [
                        for (final variant in _formVariants)
                          DropdownMenuItem(value: variant, child: Text(variant)),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedVariant = value);
                      },
                    )
                  : Text(point.form, style: const TextStyle(color: _accent, fontSize: 30, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: TextField(
                controller: _after,
                focusNode: _afterFocus,
                maxLines: null,
                style: TextStyle(color: _fg, fontSize: 22),
                decoration: _decoration(''),
                onChanged: (_) => setState(() => _copied = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'Ideas - tap one to add it to the box you last used',
                style: TextStyle(color: _fgMuted, fontSize: 14),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: _accent),
              tooltip: 'More words',
              onPressed: _pickIdeas,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final word in _ideas)
              ActionChip(
                label: _FuriganaText(
                  text: word,
                  index: widget.index,
                  fontSize: 24,
                  color: _fg,
                  japaneseColor: _fg,
                  japaneseWeight: FontWeight.w500,
                  muted: _fgMuted,
                  weight: FontWeight.w500,
                ),
                onPressed: () => _insert(word),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _heading('Punctuation marks'),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final mark in const ['。', '、', '？', '！'])
              ActionChip(
                label: Text(mark, style: TextStyle(color: _fg, fontSize: 22)),
                onPressed: () => _insert(mark),
              ),
          ],
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: const BorderSide(color: _accent),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              onPressed: _saveSentence,
              child: const Text('Save sentence'),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: const BorderSide(color: _accent),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              onPressed: _addSentence,
              child: const Text('Add sentence'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: 320,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _accent.withValues(alpha: 0.25),
              disabledForegroundColor: Colors.white54,
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            onPressed: _saved.isEmpty ? null : _finish,
            child: const Text('Finish'),
          ),
        ),
      ],
    );
  }

  Widget _reviewPage() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Your sentences',
          textAlign: TextAlign.center,
          style: TextStyle(color: _fg, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_saved.isEmpty)
          Text('No sentences yet.', style: TextStyle(color: _fgMuted, fontSize: 16)),
        for (final s in _saved) _sentenceCard(_sentenceText(s.before, s.middle, s.after)),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          onPressed: _copyAll,
          child: const Text('Copy for Skool'),
        ),
        const SizedBox(height: 16),
        Text(
          _copied ? 'Nice work - share them on Skool for feedback.' : 'Copy them to share on Skool for feedback - optional.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _fgMuted, fontSize: 15),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          ),
          onPressed: widget.onDone,
          child: const Text('Done'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            setState(() => _reviewing = false);
            widget.onReviewing(false);
          },
          child: const Text('Back to writing'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _reviewing ? _reviewPage() : _writingPage();
  }
}
