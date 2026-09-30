import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'study_data.dart';
import 'study_settings.dart';
import 'audio_service.dart';
import 'tatoeba_service.dart';
import 'listening_player.dart' show WordPopupCard, DeckPickerDialog;

const _kPurple = Color(0xFF9A00FE);

// Shown once, automatically, the first time a brand-new Vocab-type
// flashcard comes up in a Spaced Repetition session (see
// spaced_repetition_standard.dart's _maybeShowCardIntro) - the sibling of
// KanjiIntroScreen: the word, its reading and meaning, the individual kanji
// making it up (if any, each tappable for its own lookup), and real example
// sentences for the word itself from Tatoeba, with the same tap-to-look-up
// purple highlighting, TTS, and translations used in Reading/Listening.
class VocabIntroScreen extends StatefulWidget {
  final StudyCard card;
  final bool isDarkMode;
  // When shown as part of a batch of new-card intros (see
  // spaced_repetition_standard.dart's _maybeShowCardIntroBatch), this card's
  // 1-based position and the batch size, for a small "2 of 4" progress
  // label - null/omitted when shown on its own.
  final int? batchPosition;
  final int? batchTotal;
  // True when opened mid-study before the answer's been revealed (via the
  // "About this word" button) - hides the word itself, its hiragana, and
  // the kanji-breakdown section entirely, and blanks the word out of every
  // example sentence, so browsing for context doesn't hand you the answer.
  final bool redacted;

  const VocabIntroScreen({
    super.key,
    required this.card,
    required this.isDarkMode,
    this.batchPosition,
    this.batchTotal,
    this.redacted = false,
  });

  @override
  State<VocabIntroScreen> createState() => _VocabIntroScreenState();
}

class _VocabIntroScreenState extends State<VocabIntroScreen> {
  bool _loading = true;
  Map<String, HighlightEntry> _highlightIndex = {};
  StudySettings _settings = StudySettings();
  List<String> _kanjiInWord = [];
  // null = still loading; empty = looked up, none found.
  List<TatoebaSentence>? _sentences;
  int _shownCount = 2;
  OverlayEntry? _wordPopup;

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

  Future<void> _load() async {
    final decks = await loadStudyDecks();
    final allCards = <StudyCard>[for (final deck in decks) ...deck.cards];
    final settings = await loadStudySettings();
    final kanji = extractKanjiOnly(widget.card.japanese);
    if (!mounted) return;
    setState(() {
      _highlightIndex = buildHighlightIndex(allCards);
      _settings = settings;
      _kanjiInWord = kanji;
      _loading = false;
    });
    final sentences = await getTatoebaSentencesFor(widget.card.japanese);
    if (!mounted) return;
    setState(() => _sentences = sentences);
  }

  void _showMore() {
    setState(() => _shownCount = (_shownCount + 2).clamp(0, _sentences?.length ?? 0));
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
  // the mnemonic saved against the word actually being introduced.
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

  // Blanks out every occurrence of the word itself within [text] (a
  // full-width underscore per character, so the sentence still reads at
  // roughly its normal length).
  String _mask(String text) => text.replaceAll(widget.card.japanese, '＿' * widget.card.japanese.length);

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

  Widget _sentenceCard(bool isDarkMode, TatoebaSentence sentence) {
    final redacted = widget.redacted;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text.rich(_sentenceSpan(redacted ? _mask(sentence.text) : sentence.text, isDarkMode))),
              if (!redacted)
                IconButton(
                  icon: const Icon(Icons.volume_up, size: 20),
                  color: _kPurple,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _speak(sentence.text),
                ),
            ],
          ),
          if (sentence.translation != null && sentence.translation!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              sentence.translation!,
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ],
          const SizedBox(height: 6),
          InkWell(
            onTap: sentence.sentenceUrl == null ? null : () => _openSentenceSource(sentence.sentenceUrl),
            child: Text(
              sentence.username != null ? 'Sentence by ${sentence.username} · ${sentence.license ?? 'Tatoeba'}' : 'via Tatoeba',
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.white38 : Colors.black38,
                decoration: sentence.sentenceUrl != null ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kanjiChip(bool isDarkMode, String kanji) {
    final entry = _highlightIndex[kanji];
    return ActionChip(
      label: Text(
        entry != null && entry.meaning.isNotEmpty ? '$kanji · ${entry.meaning}' : kanji,
        style: const TextStyle(fontSize: 14),
      ),
      backgroundColor: _kPurple.withValues(alpha: 0.15),
      onPressed: entry == null
          ? null
          : () {
              // Anchor near the middle of the screen since this chip isn't
              // tied to a specific tap position the way a sentence word is.
              final size = MediaQuery.of(context).size;
              _showWordPopup(entry, Offset(size.width / 2, size.height / 2));
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final card = widget.card;
    final redacted = widget.redacted;
    final visibleSentences = (_sentences ?? const []).take(_shownCount).toList();

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: Text(
          widget.batchTotal == null
              ? 'Word Info'
              : widget.batchTotal! > 1
                  ? 'New Word  ·  ${widget.batchPosition}/${widget.batchTotal}'
                  : 'New Word',
        ),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: widget.batchTotal == null,
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
                              redacted ? '＿' * card.japanese.length : card.japanese,
                              style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : Colors.black),
                            ),
                            if (!redacted)
                              IconButton(
                                icon: const Icon(Icons.volume_up, size: 28),
                                color: _kPurple,
                                onPressed: () => _speak(card.hiragana.isNotEmpty ? card.hiragana : card.japanese),
                              ),
                          ],
                        ),
                        if (!redacted && card.hiragana.isNotEmpty && card.hiragana != card.japanese)
                          Text(
                            card.hiragana,
                            style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white70 : Colors.black54),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          card.english,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!redacted) _memoryTechniqueSection(isDarkMode),
                  if (!redacted && _kanjiInWord.isNotEmpty) ...[
                    Text(
                      'Kanji in this word',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _kanjiInWord.map((k) => _kanjiChip(isDarkMode, k)).toList(),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'Example sentences',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  if (_sentences == null)
                    const Center(
                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _kPurple)),
                    )
                  else if (_sentences!.isEmpty)
                    Text(
                      "No example sentences found for this word.",
                      style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: isDarkMode ? Colors.white38 : Colors.black38),
                    )
                  else ...[
                    for (final sentence in visibleSentences) _sentenceCard(isDarkMode, sentence),
                    if (_shownCount < _sentences!.length)
                      Center(
                        child: TextButton.icon(
                          onPressed: _showMore,
                          icon: const Icon(Icons.add, color: _kPurple),
                          label: const Text("More example sentences", style: TextStyle(color: _kPurple)),
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
