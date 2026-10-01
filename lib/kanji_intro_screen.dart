import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sets_data.dart';
import 'study_data.dart';
import 'study_settings.dart';
import 'audio_service.dart';
import 'tatoeba_service.dart';
import 'listening_player.dart' show WordPopupCard, DeckPickerDialog;

const _kPurple = Color(0xFF9A00FE);

// Shown once, automatically, the first time a brand-new Kanji-type
// flashcard comes up in a Spaced Repetition session (see
// spaced_repetition_standard.dart's _maybeShowKanjiIntro) - a bit of extra
// context before diving into the drill: the kanji's meaning and common
// readings (from the dictionary), a couple of real example words that use
// it, and - for each word - a genuine example sentence from Tatoeba with
// the same tap-to-look-up purple highlighting, TTS, and translation used in
// Reading/Listening.
class KanjiIntroScreen extends StatefulWidget {
  final StudyCard card;
  final bool isDarkMode;
  // When shown as part of a batch of new-card intros (see
  // spaced_repetition_standard.dart's _maybeShowCardIntroBatch), this card's
  // 1-based position and the batch size, for a small "2 of 4" progress
  // label - null/omitted when shown on its own.
  final int? batchPosition;
  final int? batchTotal;
  // True when opened mid-study before the answer's been revealed (via the
  // "About this kanji" button) - hides the kanji itself, its readings, and
  // any reading/pronunciation clues in the example content, so browsing for
  // context doesn't hand you the answer outright.
  final bool redacted;

  const KanjiIntroScreen({
    super.key,
    required this.card,
    required this.isDarkMode,
    this.batchPosition,
    this.batchTotal,
    this.redacted = false,
  });

  @override
  State<KanjiIntroScreen> createState() => _KanjiIntroScreenState();
}

class _KanjiIntroScreenState extends State<KanjiIntroScreen> {
  bool _loading = true;
  Map<String, HighlightEntry> _highlightIndex = {};
  StudySettings _settings = StudySettings();
  List<Item> _allExampleWords = [];
  int _shownCount = 2;
  // null = still loading; empty list = looked up, none found.
  final Map<String, List<TatoebaSentence>?> _sentencesByWord = {};
  OverlayEntry? _wordPopup;
  Item? _kanjiEntry;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _closeWordPopup();
    super.dispose();
  }

  List<Item> get _visibleWords => _allExampleWords.take(_shownCount).toList();

  Future<void> _load() async {
    final decks = await loadStudyDecks();
    final allCards = <StudyCard>[for (final deck in decks) ...deck.cards];
    final settings = await loadStudySettings();
    final kanjiEntry = dictionaryEntryForKanji(widget.card.japanese);
    final examples = exampleWordsContaining(widget.card.japanese, limit: 20);
    if (!mounted) return;
    setState(() {
      _highlightIndex = buildHighlightIndex(allCards);
      _settings = settings;
      _kanjiEntry = kanjiEntry;
      _allExampleWords = examples;
      _loading = false;
    });
    _loadSentencesFor(_visibleWords);
  }

  Future<void> _loadSentencesFor(List<Item> words) async {
    for (final word in words) {
      if (_sentencesByWord.containsKey(word.japanese)) continue;
      _sentencesByWord[word.japanese] = null;
      if (mounted) setState(() {});
      final sentences = await getTatoebaSentencesFor(word.japanese);
      if (!mounted) return;
      setState(() => _sentencesByWord[word.japanese] = sentences);
    }
  }

  void _showMore() {
    setState(() => _shownCount = (_shownCount + 2).clamp(0, _allExampleWords.length));
    _loadSentencesFor(_visibleWords);
  }

  Future<void> _speak(String text) async {
    final ok = await AudioService().speak(
      text,
      'Japanese',
      rate: _settings.japaneseSpeed,
      voiceName: _settings.japaneseVoiceName,
    );
    if (!ok && mounted) showMissingVoiceSnackBar(context, widget.isDarkMode, 'Japanese');
  }

  void _closeWordPopup() {
    _wordPopup?.remove();
    _wordPopup = null;
  }

  void _showWordPopup(HighlightEntry entry, Offset tapPosition) {
    _closeWordPopup();
    final screenSize = MediaQuery.of(context).size;
    const bubbleWidth = 260.0;
    final left = (tapPosition.dx - bubbleWidth / 2).clamp(12.0, screenSize.width - bubbleWidth - 12.0);
    final showBelow = tapPosition.dy < screenSize.height - 300;

    final overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeWordPopup,
            ),
          ),
          Positioned(
            left: left,
            top: showBelow ? tapPosition.dy + 16 : null,
            bottom: showBelow ? null : (screenSize.height - tapPosition.dy + 16),
            child: WordPopupCard(
              entry: entry,
              isDarkMode: widget.isDarkMode,
              width: bubbleWidth,
              settings: _settings,
              highlightIndex: _highlightIndex,
              onClose: _closeWordPopup,
              onAddToDeck: () {
                _closeWordPopup();
                _addEntryToDeck(entry);
              },
              onEditMemoryTechnique: () {
                _closeWordPopup();
                _editMemoryTechnique(entry);
              },
              onOpenKanji: (kEntry) => _showWordPopup(kEntry, tapPosition),
            ),
          ),
        ],
      ),
    );
    _wordPopup = overlayEntry;
    Overlay.of(context).insert(overlayEntry);
  }

  Future<void> _addEntryToDeck(HighlightEntry entry) async {
    final decks = await loadStudyDecks();
    if (!mounted) return;
    final chosen = await showDialog<StudyDeck>(
      context: context,
      builder: (context) => DeckPickerDialog(decks: decks, isDarkMode: widget.isDarkMode),
    );
    if (chosen == null || !mounted) return;

    final newCard = StudyCard(
      japanese: entry.japanese,
      hiragana: entry.reading,
      english: entry.meaning,
      kanjiVGCodes: findKanjiVGCodesForWord(entry.japanese),
      cardType: entry.japanese.length == 1 ? 'Kanji' : 'Vocab',
    );
    chosen.cards.add(newCard);
    await saveStudyDecks(decks);
    if (!mounted) return;
    entry.isDeckWord = true;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "${entry.japanese}" to ${chosen.name}')),
    );
  }

  Future<String?> _promptForMemoryTechnique(String current) {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          current.isEmpty ? "Add Memory Technique" : "Edit Memory Technique",
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
            style: ElevatedButton.styleFrom(backgroundColor: _kPurple, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _editMemoryTechnique(HighlightEntry entry) async {
    final result = await _promptForMemoryTechnique(entry.memoryTechnique);
    if (result == null || !mounted) return;

    final technique = result.trim();
    entry.memoryTechnique = technique;
    entry.card?.memoryTechnique = technique;
    setState(() {});
    await updateCardInAllDecks(entry.japanese, (c) => c.memoryTechnique = technique);
  }

  // Same as _editMemoryTechnique, but for this screen's own card rather than
  // a word looked up inside a sentence - lets the user add, view, or edit
  // the mnemonic saved against the kanji actually being introduced.
  Future<void> _editCardMemoryTechnique() async {
    final result = await _promptForMemoryTechnique(widget.card.memoryTechnique);
    if (result == null || !mounted) return;

    final technique = result.trim();
    setState(() => widget.card.memoryTechnique = technique);
    await updateCardInAllDecks(widget.card.japanese, (c) => c.memoryTechnique = technique);
  }

  Future<void> _openSentenceSource(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  InlineSpan _sentenceSpan(String text, bool isDarkMode) {
    final baseStyle = TextStyle(fontSize: 17, color: isDarkMode ? Colors.white : Colors.black87);
    final tokens = tokenizeSentence(text, _highlightIndex);
    final spans = <InlineSpan>[
      for (final tok in tokens)
        if (tok.entry == null)
          TextSpan(text: tok.text)
        else
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTapDown: (details) => _showWordPopup(tok.entry!, details.globalPosition),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _kPurple.withValues(alpha: tok.entry!.isDeckWord ? (isDarkMode ? 0.55 : 0.35) : (isDarkMode ? 0.25 : 0.15)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tok.text, style: baseStyle),
              ),
            ),
          ),
    ];
    return TextSpan(style: baseStyle, children: spans);
  }

  // Blanks out every occurrence of the kanji being introduced within [text]
  // (a differently-sized run of full-width underscores so a multi-kanji
  // word/sentence still reads at roughly its normal length).
  String _mask(String text) => text.replaceAll(widget.card.japanese, '＿');

  Widget _memoryTechniqueSection(bool isDarkMode) {
    final technique = widget.card.memoryTechnique;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates, color: _kPurple, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Memory technique',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                ),
              ),
              IconButton(
                icon: Icon(technique.isEmpty ? Icons.add : Icons.edit, size: 20),
                color: _kPurple,
                visualDensity: VisualDensity.compact,
                onPressed: _editCardMemoryTechnique,
              ),
            ],
          ),
          if ((widget.card.memoryImageAsset ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(widget.card.memoryImageAsset!, fit: BoxFit.contain),
            ),
          ],
          if (technique.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(technique, style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black54)),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              "No memory technique saved yet.",
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: isDarkMode ? Colors.white38 : Colors.black38),
            ),
          ],
        ],
      ),
    );
  }

  Widget _exampleWordCard(bool isDarkMode, Item word) {
    final redacted = widget.redacted;
    final sentences = _sentencesByWord[word.japanese];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      redacted ? _mask(word.japanese) : word.japanese,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                    ),
                    if (!redacted && word.reading.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(word.reading, style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black54)),
                    ],
                  ],
                ),
              ),
              if (!redacted)
                IconButton(
                  icon: const Icon(Icons.volume_up, size: 20),
                  color: _kPurple,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _speak(word.japanese),
                ),
            ],
          ),
          Text(word.translation, style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black54)),
          if (sentences == null) ...[
            const SizedBox(height: 12),
            const Center(
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _kPurple)),
            ),
          ] else if (sentences.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "No example sentence found for this word.",
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: isDarkMode ? Colors.white38 : Colors.black38),
            ),
          ] else ...[
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text.rich(_sentenceSpan(redacted ? _mask(sentences.first.text) : sentences.first.text, isDarkMode)),
                ),
                if (!redacted)
                  IconButton(
                    icon: const Icon(Icons.volume_up, size: 20),
                    color: _kPurple,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _speak(sentences.first.text),
                  ),
              ],
            ),
            if (sentences.first.translation != null && sentences.first.translation!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                sentences.first.translation!,
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ],
            const SizedBox(height: 6),
            InkWell(
              onTap: sentences.first.sentenceUrl == null ? null : () => _openSentenceSource(sentences.first.sentenceUrl),
              child: Text(
                sentences.first.username != null
                    ? 'Sentence by ${sentences.first.username} · ${sentences.first.license ?? 'Tatoeba'}'
                    : 'via Tatoeba',
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                  decoration: sentences.first.sentenceUrl != null ? TextDecoration.underline : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final card = widget.card;
    final redacted = widget.redacted;
    final kanjiEntry = _kanjiEntry;
    final readings = redacted
        ? const <String>[]
        : <String>[
            if (kanjiEntry != null && kanjiEntry.onYomi.isNotEmpty) 'On: ${kanjiEntry.onYomi}',
            if (kanjiEntry != null && kanjiEntry.kunYomi.isNotEmpty) 'Kun: ${kanjiEntry.kunYomi}',
          ];

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: Text(
          widget.batchTotal == null
              ? 'Kanji Info'
              : widget.batchTotal! > 1
                  ? 'New Kanji  ·  ${widget.batchPosition}/${widget.batchTotal}'
                  : 'New Kanji',
        ),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kPurple))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              redacted ? '＿' : card.japanese,
                              style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : Colors.black),
                            ),
                            if (!redacted)
                              IconButton(
                                icon: const Icon(Icons.volume_up, size: 28),
                                color: _kPurple,
                                onPressed: () => _speak(card.hiragana.isNotEmpty ? card.hiragana : card.japanese),
                              ),
                          ],
                        ),
                        Text(
                          card.english,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                        if (readings.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            children: readings
                                .map((r) => Text(r, style: TextStyle(fontSize: 15, color: isDarkMode ? Colors.white70 : Colors.black54)))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!redacted) _memoryTechniqueSection(isDarkMode),
                  if (_allExampleWords.isEmpty)
                    Text(
                      "No example words found in the dictionary for this kanji.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black45),
                    )
                  else ...[
                    Text(
                      'Example words',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    for (final word in _visibleWords) _exampleWordCard(isDarkMode, word),
                    if (_shownCount < _allExampleWords.length)
                      Center(
                        child: TextButton.icon(
                          onPressed: _showMore,
                          icon: const Icon(Icons.add, color: _kPurple),
                          label: const Text("More example words", style: TextStyle(color: _kPurple)),
                        ),
                      ),
                  ],
                ],
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                widget.batchTotal == null
                    ? "Close"
                    : (widget.batchPosition ?? widget.batchTotal!) < widget.batchTotal!
                        ? "Next"
                        : "Start studying",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
