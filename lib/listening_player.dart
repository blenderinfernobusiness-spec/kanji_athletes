import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'study_data.dart';
import 'audio_service.dart';
import 'study_settings.dart';
import 'tatoeba_service.dart';
import 'translation_service.dart';
import 'card_edit_dialog.dart' show showStrokeOrderDialog;

// LingQ-style lookup bubble content: word, reading, meaning, an audio
// button, an add-to-deck action (for dictionary words not already in the
// deck), and the individual kanji making up the word, each reopening this
// same bubble for that kanji.
class WordPopupCard extends StatelessWidget {
  final HighlightEntry entry;
  final bool isDarkMode;
  final double width;
  final StudySettings settings;
  final Map<String, HighlightEntry> highlightIndex;
  final VoidCallback onClose;
  final VoidCallback onAddToDeck;
  final VoidCallback onEditMemoryTechnique;
  final void Function(HighlightEntry) onOpenKanji;

  const WordPopupCard({
    required this.entry,
    required this.isDarkMode,
    required this.width,
    required this.settings,
    required this.highlightIndex,
    required this.onClose,
    required this.onAddToDeck,
    required this.onEditMemoryTechnique,
    required this.onOpenKanji,
  });

  @override
  Widget build(BuildContext context) {
    final kanji = entry.japanese.length > 1 ? extractKanjiOnly(entry.japanese) : <String>[];
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        constraints: const BoxConstraints(maxHeight: 340),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.japanese,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final ok = await AudioService().speak(
                        entry.japanese,
                        'Japanese',
                        rate: settings.japaneseSpeed,
                        voiceName: settings.japaneseVoiceName,
                      );
                      if (!ok && context.mounted) showMissingVoiceSnackBar(context, isDarkMode, 'Japanese');
                    },
                    icon: const Icon(Icons.volume_up, size: 20),
                    color: const Color(0xFF9A00FE),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    onPressed: () => showStrokeOrderDialog(
                      context,
                      (entry.card != null && entry.card!.kanjiVGCodes.isNotEmpty)
                          ? entry.card!.kanjiVGCodes
                          : findKanjiVGCodesForWord(entry.japanese),
                      isDarkMode,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: const Color(0xFF9A00FE),
                    tooltip: 'Practice writing',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close, size: 18, color: isDarkMode ? Colors.white54 : Colors.black45),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              if (entry.reading.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(entry.reading, style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white70 : Colors.black54)),
              ],
              if (entry.romaji.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  entry.romaji,
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: isDarkMode ? Colors.white54 : Colors.black45),
                ),
              ],
              if (entry.meaning.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(entry.meaning, style: TextStyle(fontSize: 15, color: isDarkMode ? Colors.white : Colors.black87)),
              ],
              if (entry.memoryTechnique.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 14, color: isDarkMode ? Colors.white54 : Colors.black45),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entry.memoryTechnique,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (entry.isDeckWord) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9A00FE).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Already in your deck",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9A00FE)),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onEditMemoryTechnique,
                  icon: Icon(
                    entry.memoryTechnique.isEmpty ? Icons.add : Icons.edit,
                    size: 16,
                    color: const Color(0xFF9A00FE),
                  ),
                  label: Text(
                    entry.memoryTechnique.isEmpty ? "Add memory technique" : "Edit memory technique",
                    style: const TextStyle(color: Color(0xFF9A00FE), fontSize: 13),
                  ),
                ),
              ] else if (entry.item != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onAddToDeck,
                  icon: const Icon(Icons.add, size: 18, color: Color(0xFF9A00FE)),
                  label: const Text("Add to deck", style: TextStyle(color: Color(0xFF9A00FE))),
                ),
              if (kanji.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: kanji.map((k) {
                    final kEntry = highlightIndex[k];
                    return ActionChip(
                      label: Text(k, style: const TextStyle(fontSize: 14)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFF9A00FE).withValues(alpha: 0.15),
                      onPressed: kEntry == null ? null : () => onOpenKanji(kEntry),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// LingQ-style pop-up for a free-form text selection (rather than a single
// tapped word): the selected text, a button to open it in Google Translate
// (external, since there's no in-app translation API wired up right now), a
// speaker button, a "practice writing" button when the selection contains
// kanji, and an add-to-deck action - shared between Reading and Listening's
// SelectionArea highlighting.
class SelectionTranslateCard extends StatefulWidget {
  final String text;
  final bool isDarkMode;
  final StudySettings settings;
  final double width;
  final VoidCallback onClose;
  final void Function(String japanese, String translation) onAddToDeck;
  // Used for a best-effort reading line: the selection is broken into the
  // same known words used for the purple highlighting, and any recognized
  // word's reading is shown - unrecognized runs (proper nouns, anything not
  // in the dictionary or a deck) are left as-is, since there's no reliable
  // way to guess a reading for those without a real furigana/NLP service.
  final Map<String, HighlightEntry> highlightIndex;

  const SelectionTranslateCard({
    super.key,
    required this.text,
    required this.isDarkMode,
    required this.settings,
    required this.width,
    required this.onClose,
    required this.onAddToDeck,
    required this.highlightIndex,
  });

  @override
  State<SelectionTranslateCard> createState() => _SelectionTranslateCardState();
}

class _SelectionTranslateCardState extends State<SelectionTranslateCard> {
  Future<void> _speak() async {
    final ok = await AudioService().speak(
      widget.text,
      'Japanese',
      rate: widget.settings.japaneseSpeed,
      voiceName: widget.settings.japaneseVoiceName,
    );
    if (!ok && mounted) showMissingVoiceSnackBar(context, widget.isDarkMode, 'Japanese');
  }

  // Best-effort reading for the selection: recognized words (from the
  // dictionary or a deck) contribute their real reading; anything else -
  // most commonly names, since those aren't in the dictionary - is left as
  // the original text. Returns null if nothing at all was recognized.
  String? get _readingLine {
    final tokens = tokenizeSentence(widget.text, widget.highlightIndex);
    var foundAny = false;
    final buffer = StringBuffer();
    for (final tok in tokens) {
      if (tok.entry != null && tok.entry!.reading.isNotEmpty) {
        buffer.write(tok.entry!.reading);
        foundAny = true;
      } else {
        buffer.write(tok.text);
      }
    }
    return foundAny ? buffer.toString() : null;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final kanjiVGCodes = findKanjiVGCodesForWord(widget.text);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: widget.width,
        constraints: const BoxConstraints(maxHeight: 320),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.text,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ),
                  IconButton(
                    onPressed: _speak,
                    icon: const Icon(Icons.volume_up, size: 20),
                    color: const Color(0xFF9A00FE),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (kanjiVGCodes.isNotEmpty)
                    IconButton(
                      onPressed: () => showStrokeOrderDialog(context, kanjiVGCodes, isDarkMode),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: const Color(0xFF9A00FE),
                      tooltip: 'Practice writing',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: Icon(Icons.close, size: 18, color: isDarkMode ? Colors.white54 : Colors.black45),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              if (_readingLine != null && _readingLine != widget.text) ...[
                const SizedBox(height: 2),
                Text(_readingLine!, style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white70 : Colors.black54)),
              ],
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => openGoogleTranslate(widget.text),
                icon: const Icon(Icons.open_in_new, size: 18, color: Color(0xFF9A00FE)),
                label: const Text("Open in Google Translate", style: TextStyle(color: Color(0xFF9A00FE))),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  widget.onClose();
                  widget.onAddToDeck(widget.text, '');
                },
                icon: const Icon(Icons.add, size: 18, color: Color(0xFF9A00FE)),
                label: const Text("Add to deck", style: TextStyle(color: Color(0xFF9A00FE))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Lets the user pick an existing deck (or create a new one) to add a
// highlighted word to.
class DeckPickerDialog extends StatefulWidget {
  final List<StudyDeck> decks;
  final bool isDarkMode;

  const DeckPickerDialog({required this.decks, required this.isDarkMode});

  @override
  State<DeckPickerDialog> createState() => DeckPickerDialogState();
}

class DeckPickerDialogState extends State<DeckPickerDialog> {
  Future<String?> _promptDeckName() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "New Deck",
          style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: "Deck name",
            hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
            filled: true,
            fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Add to Deck",
        style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
      ),
      content: SizedBox(
        width: 280,
        child: widget.decks.isEmpty
            ? Text(
                "No decks yet - create one below.",
                style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
              )
            : SizedBox(
                height: 240,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.decks.length,
                  itemBuilder: (context, index) {
                    final deck = widget.decks[index];
                    return ListTile(
                      title: Text(deck.name, style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87)),
                      subtitle: Text(
                        '${deck.cards.length} card${deck.cards.length == 1 ? '' : 's'}',
                        style: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black45),
                      ),
                      onTap: () => Navigator.pop(context, deck),
                    );
                  },
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        TextButton(
          onPressed: () async {
            final name = await _promptDeckName();
            if (name == null || name.trim().isEmpty || !context.mounted) return;
            final newDeck = StudyDeck(name: name.trim());
            widget.decks.add(newDeck);
            Navigator.pop(context, newDeck);
          },
          child: const Text("New Deck", style: TextStyle(color: Color(0xFF9A00FE))),
        ),
      ],
    );
  }
}

// One queued sentence: which card it came from, and the Tatoeba sentence
// itself (text, translation, and per-sentence attribution).
class _QueuedSentence {
  final StudyCard card;
  final TatoebaSentence sentence;
  _QueuedSentence(this.card, this.sentence);
}

// Plays through example sentences for a set of cards - up to 3 per card,
// fetched from Tatoeba - one sentence at a time: the Japanese sentence is
// read aloud, then its English translation (Tatoeba's own linked
// translation when available, otherwise the card's own meaning as a
// stand-in), advancing automatically. Streams sentences in as they resolve
// rather than waiting for the whole deck, so playback starts quickly even
// for a large deck.
class ListeningPlayerScreen extends StatefulWidget {
  final String title;
  final List<StudyCard> cards;
  final bool isDarkMode;

  const ListeningPlayerScreen({
    super.key,
    required this.title,
    required this.cards,
    required this.isDarkMode,
  });

  @override
  State<ListeningPlayerScreen> createState() => _ListeningPlayerScreenState();
}

class _ListeningPlayerScreenState extends State<ListeningPlayerScreen> {
  static const int _kSentencesPerWord = 3;
  static const int _kStartBuffer = 2;

  final List<_QueuedSentence> _queue = [];
  int _index = 0;
  bool _resolving = true;
  bool _resolvingMore = true;
  bool _waitingForMore = false;
  bool _playing = true;
  bool _finished = false;
  bool _translationRevealed = false;
  int _playbackRunId = 0;
  StudySettings _settings = StudySettings();
  List<Map<String, dynamic>> _englishVoices = [];
  List<Map<String, dynamic>> _japaneseVoices = [];
  late final Map<String, HighlightEntry> _highlightIndex = buildHighlightIndex(widget.cards);
  OverlayEntry? _wordPopup;
  OverlayEntry? _selectionPopup;
  String _selectedText = '';
  // Tracks the queue index each known (deck) word was last read out at, so
  // "read known words first" can skip a word it just covered recently.
  final Map<String, int> _lastKnownWordReadAt = {};
  static const int _kKnownWordRepeatGap = 3;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _settings = await loadStudySettings();
    _englishVoices = await AudioService().voicesForLanguage('English');
    _japaneseVoices = await AudioService().voicesForLanguage('Japanese');
    // Wait for the "no Japanese voice" dialog (if shown) to be dismissed
    // before resolving sentences and starting playback, so audio never
    // starts underneath the pop-up.
    await _maybeShowNoJapaneseVoiceDialog();
    if (!mounted) return;
    _resolveAll();
  }

  Future<void> _maybeShowNoJapaneseVoiceDialog() async {
    if (!mounted || _japaneseVoices.isNotEmpty) return;
    final canInstall = await AudioService().canOfferVoiceInstall();
    if (!mounted) return;
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        completer.complete();
        return;
      }
      // Pop with a result string rather than acting inside the button's
      // onPressed, so we can wait for whatever follow-up dialog (Help) is
      // opened next to *also* close before letting playback start - popping
      // this dialog alone resolves showDialog's future immediately, before
      // any follow-up dialog even opens.
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "No Japanese Voice Found",
            style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
          ),
          content: Text(
            "This device doesn't have a Japanese text-to-speech voice installed, so sentences can't be read aloud yet.",
            style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Dismiss")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, canInstall ? 'install' : 'help'),
              child: Text(canInstall ? "Install" : "Help"),
            ),
          ],
        ),
      );
      if (action == 'install') {
        await AudioService().openInstallVoiceData();
      } else if (action == 'help' && mounted) {
        await showWindowsVoiceSetupHelp(context, widget.isDarkMode, 'Japanese');
      }
      completer.complete();
    });
    await completer.future;
  }

  @override
  void dispose() {
    _playbackRunId++;
    AudioService().stop();
    _closeWordPopup();
    _closeSelectionPopup();
    super.dispose();
  }

  // Streams sentences in one card at a time rather than resolving the whole
  // list upfront - starts playback once _kStartBuffer sentences are ready,
  // then keeps resolving the rest in the background. _playCurrent() picks
  // up newly-arrived sentences via the _waitingForMore handshake if it
  // catches up to the buffered end.
  Future<void> _resolveAll() async {
    bool startedPlayback = false;
    for (final card in widget.cards) {
      final word = card.japanese.trim();
      if (word.isEmpty) continue;
      final sentences = await getTatoebaSentencesFor(word);
      final chosen = sentences.take(_kSentencesPerWord).toList();
      if (!mounted) return;
      if (chosen.isNotEmpty) {
        setState(() {
          for (final s in chosen) {
            _queue.add(_QueuedSentence(card, s));
          }
        });
      }

      if (!startedPlayback && _queue.length >= _kStartBuffer) {
        startedPlayback = true;
        setState(() => _resolving = false);
        _playCurrent();
      } else if (_waitingForMore && _queue.length > _index) {
        _waitingForMore = false;
        _playCurrent();
      }
    }

    if (!mounted) return;
    _resolvingMore = false;
    if (!startedPlayback) {
      setState(() => _resolving = false);
      if (_queue.isNotEmpty) _playCurrent();
    } else if (_waitingForMore) {
      _waitingForMore = false;
      _playCurrent();
    }
  }

  // Reads out each dark-purple (already-in-deck) word in [text], followed by
  // its meaning, before the sentence itself plays - skipping any word read
  // out within the last _kKnownWordRepeatGap sentences so it doesn't get
  // repetitive. Bails out early (via the same runId/mounted/_playing checks
  // used elsewhere) if playback is paused, skipped, or the screen closes
  // partway through.
  Future<void> _readKnownWordsFor(String text, int runId) async {
    final seen = <String>{};
    for (final tok in tokenizeSentence(text, _highlightIndex)) {
      final word = tok.entry;
      if (word == null || !word.isDeckWord || !seen.add(word.japanese)) continue;

      final lastReadAt = _lastKnownWordReadAt[word.japanese];
      if (lastReadAt != null && _index - lastReadAt < _kKnownWordRepeatGap) continue;

      await AudioService().speak(
        word.japanese,
        'Japanese',
        rate: _settings.japaneseSpeed,
        voiceName: _settings.japaneseVoiceName,
        waitForCompletion: true,
      );
      if (runId != _playbackRunId || !mounted || !_playing) return;

      if (word.meaning.isNotEmpty) {
        await AudioService().speak(
          word.meaning,
          'English',
          rate: _settings.englishSpeed,
          voiceName: _settings.englishVoiceName,
          waitForCompletion: true,
        );
        if (runId != _playbackRunId || !mounted || !_playing) return;
      }
      _lastKnownWordReadAt[word.japanese] = _index;
    }
  }

  Future<void> _playCurrent() async {
    final runId = ++_playbackRunId;
    if (_index >= _queue.length) {
      if (_resolvingMore) {
        setState(() => _waitingForMore = true);
        return;
      }
      setState(() => _finished = true);
      return;
    }
    if (_waitingForMore) setState(() => _waitingForMore = false);
    setState(() {});
    final entry = _queue[_index];

    if (_settings.readKnownWordsFirst) {
      await _readKnownWordsFor(entry.sentence.text, runId);
      if (runId != _playbackRunId || !mounted || !_playing) return;
    }

    final spokeJapanese = await AudioService().speak(
      entry.sentence.text,
      'Japanese',
      rate: _settings.japaneseSpeed,
      voiceName: _settings.japaneseVoiceName,
      waitForCompletion: true,
    );
    if (runId != _playbackRunId || !mounted || !_playing) return;

    final translation = entry.sentence.translation;
    bool spokeEnglish = false;
    if (translation != null && translation.isNotEmpty) {
      spokeEnglish = await AudioService().speak(translation, 'English',
          rate: _settings.englishSpeed, voiceName: _settings.englishVoiceName, waitForCompletion: true);
    } else if (entry.card.english.trim().isNotEmpty) {
      // No sentence-level translation from Tatoeba - fall back to the
      // card's own meaning rather than reaching for a translation API.
      spokeEnglish = await AudioService().speak(entry.card.english.trim(), 'English',
          rate: _settings.englishSpeed, voiceName: _settings.englishVoiceName, waitForCompletion: true);
    }
    if (runId != _playbackRunId || !mounted || !_playing) return;

    // speak() returns instantly (no actual delay) when no voice is
    // installed for a language, rather than genuinely speaking anything -
    // without this check, auto-play would race through every remaining
    // sentence in a fraction of a second since nothing is ever actually
    // read aloud to wait for.
    if (!spokeJapanese && !spokeEnglish) {
      setState(() => _playing = false);
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (runId != _playbackRunId || !mounted || !_playing) return;
    if (_settings.listeningAutoAdvance) {
      _advance();
    } else {
      setState(() => _playing = false);
    }
  }

  // Stops whatever's currently playing/queued and pauses auto-play, so a
  // manual replay never overlaps with or gets clobbered by the sequential
  // playback chain.
  void _pauseForManualReplay() {
    AudioService().stop();
    _playbackRunId++;
    if (_playing) setState(() => _playing = false);
  }

  Future<void> _replaySentence() async {
    _pauseForManualReplay();
    final entry = _queue[_index];
    final ok = await AudioService().speak(
      entry.sentence.text,
      'Japanese',
      rate: _settings.japaneseSpeed,
      voiceName: _settings.japaneseVoiceName,
    );
    if (!ok && mounted) showMissingVoiceSnackBar(context, widget.isDarkMode, 'Japanese');
  }

  Future<void> _replayTranslation() async {
    _pauseForManualReplay();
    final entry = _queue[_index];
    final translation = entry.sentence.translation;
    final text = (translation != null && translation.isNotEmpty) ? translation : entry.card.english.trim();
    if (text.isEmpty) return;
    final ok = await AudioService().speak(
      text,
      'English',
      rate: _settings.englishSpeed,
      voiceName: _settings.englishVoiceName,
    );
    if (!ok && mounted) showMissingVoiceSnackBar(context, widget.isDarkMode, 'English');
  }

  void _advance() {
    setState(() {
      _index++;
      _translationRevealed = false;
    });
    _playCurrent();
  }

  void _togglePlayPause() {
    if (_finished) return;
    setState(() => _playing = !_playing);
    if (_playing) {
      _playCurrent();
    } else {
      AudioService().stop();
      _playbackRunId++;
    }
  }

  void _skip() {
    if (_finished || _queue.isEmpty || _waitingForMore) return;
    AudioService().stop();
    _playbackRunId++;
    if (!_playing) setState(() => _playing = true);
    _advance();
  }

  void _previous() {
    if (_index == 0) return;
    AudioService().stop();
    _playbackRunId++;
    setState(() {
      _index--;
      _translationRevealed = false;
      if (!_playing) _playing = true;
    });
    _playCurrent();
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void applyChange(VoidCallback change) {
            setDialogState(change);
            setState(() {});
            saveStudySettings(_settings);
          }

          return AlertDialog(
            backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              "Listening Settings",
              style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
            ),
            content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _speedSlider(
                      "Japanese Speed",
                      _settings.japaneseSpeed,
                      (v) => applyChange(() => _settings.japaneseSpeed = v),
                    ),
                    const SizedBox(height: 4),
                    _voicePicker(
                      "Japanese Voice",
                      _japaneseVoices,
                      _settings.japaneseVoiceName,
                      (v) => applyChange(() => _settings.japaneseVoiceName = v),
                    ),
                    const SizedBox(height: 20),
                    _speedSlider(
                      "English Speed",
                      _settings.englishSpeed,
                      (v) => applyChange(() => _settings.englishSpeed = v),
                    ),
                    const SizedBox(height: 4),
                    _voicePicker(
                      "English Voice",
                      _englishVoices,
                      _settings.englishVoiceName,
                      (v) => applyChange(() => _settings.englishVoiceName = v),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Auto-advance to next sentence",
                        style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87, fontSize: 14),
                      ),
                      value: _settings.listeningAutoAdvance,
                      activeColor: const Color(0xFF9A00FE),
                      onChanged: (v) => applyChange(() => _settings.listeningAutoAdvance = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Read known words first",
                        style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87, fontSize: 14),
                      ),
                      subtitle: Text(
                        "Reads each deck word (and its meaning) before the sentence, at most once every 3 sentences",
                        style: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black45, fontSize: 12),
                      ),
                      value: _settings.readKnownWordsFirst,
                      activeColor: const Color(0xFF9A00FE),
                      onChanged: (v) => applyChange(() => _settings.readKnownWordsFirst = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(context),
                child: const Text("Done"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _speedSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${value.toStringAsFixed(2)}x',
          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 13),
        ),
        Slider(
          value: value,
          min: 0.5,
          max: 2.0,
          divisions: 30,
          activeColor: const Color(0xFF9A00FE),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _voicePicker(
    String label,
    List<Map<String, dynamic>> voices,
    String? selected,
    ValueChanged<String?> onChanged,
  ) {
    final names = voices.map((v) => v['name'].toString()).toList();
    final value = (selected != null && names.contains(selected)) ? selected : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 13)),
        const SizedBox(height: 4),
        DropdownButton<String?>(
          isExpanded: true,
          value: value,
          hint: Text(
            voices.isEmpty ? "No voice installed" : "Device default",
            style: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black45, fontSize: 13),
          ),
          dropdownColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                "Device default",
                style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87, fontSize: 13),
              ),
            ),
            ...names.map(
              (n) => DropdownMenuItem<String?>(
                value: n,
                child: Text(
                  n,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87, fontSize: 13),
                ),
              ),
            ),
          ],
          onChanged: voices.isEmpty ? null : onChanged,
        ),
      ],
    );
  }

  // Builds the sentence as mixed plain/highlighted spans: words already
  // known to the dictionary get a light purple background, words already in
  // the current study set get a stronger one, both tappable for details.
  InlineSpan _sentenceSpan(String text, bool isDarkMode) {
    final baseStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? Colors.white : Colors.black87,
    );
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
                  color: const Color(0xFF9A00FE).withValues(
                    alpha: tok.entry!.isDeckWord
                        ? (isDarkMode ? 0.55 : 0.35)
                        : (isDarkMode ? 0.25 : 0.15),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tok.text, style: baseStyle),
              ),
            ),
          ),
    ];
    return TextSpan(style: baseStyle, children: spans);
  }

  // Closes whatever word popup is currently showing, if any.
  void _closeWordPopup() {
    _wordPopup?.remove();
    _wordPopup = null;
  }

  // LingQ-style word lookup: a small bubble anchored right under (or, if
  // there isn't room, above) the tapped word, rather than a centered dialog
  // that takes over the screen. A full-screen transparent barrier behind it
  // closes it on an outside tap.
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
      builder: (context) => DeckPickerDialog(
        decks: decks,
        isDarkMode: widget.isDarkMode,
      ),
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
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "${entry.japanese}" to ${chosen.name}')),
    );
  }

  // Closes whatever free-selection translate pop-up is currently showing.
  void _closeSelectionPopup() {
    _selectionPopup?.remove();
    _selectionPopup = null;
  }

  // Shows the translate/add-to-deck pop-up for a free-form text selection -
  // triggered as soon as the user finishes highlighting a sentence, the same
  // as in Reading, rather than needing a separate menu action.
  void _showSelectionPopup(String text, Offset anchor) {
    _closeWordPopup();
    _closeSelectionPopup();
    final screenSize = MediaQuery.of(context).size;
    const bubbleWidth = 260.0;
    final left = (anchor.dx - bubbleWidth / 2).clamp(12.0, screenSize.width - bubbleWidth - 12.0);
    final showBelow = anchor.dy < screenSize.height - 300;

    final overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeSelectionPopup,
            ),
          ),
          Positioned(
            left: left,
            top: showBelow ? anchor.dy + 16 : null,
            bottom: showBelow ? null : (screenSize.height - anchor.dy + 16),
            child: SelectionTranslateCard(
              text: text,
              isDarkMode: widget.isDarkMode,
              settings: _settings,
              width: bubbleWidth,
              onClose: _closeSelectionPopup,
              onAddToDeck: _addSelectionToDeck,
              highlightIndex: _highlightIndex,
            ),
          ),
        ],
      ),
    );
    _selectionPopup = overlayEntry;
    Overlay.of(context).insert(overlayEntry);
  }

  Future<void> _addSelectionToDeck(String japanese, String translation) async {
    final decks = await loadStudyDecks();
    if (!mounted) return;
    final chosen = await showDialog<StudyDeck>(
      context: context,
      builder: (context) => DeckPickerDialog(decks: decks, isDarkMode: widget.isDarkMode),
    );
    if (chosen == null || !mounted) return;

    final card = StudyCard(
      japanese: japanese,
      hiragana: '',
      english: translation,
      kanjiVGCodes: findKanjiVGCodesForWord(japanese),
    );
    chosen.cards.add(card);
    await saveStudyDecks(decks);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "$japanese" to ${chosen.name}')),
    );
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
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
    setState(() {});

    // Persist to every saved deck's matching card, not just entry.card - the
    // word may have come from a Mistakes session whose cards aren't the same
    // objects as the ones actually saved to disk.
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

  Future<void> _openSentenceSource(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: Text('Listening: ${widget.title}'),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showSettingsDialog,
            icon: const Icon(Icons.settings),
            tooltip: "Speed & voice settings",
          ),
        ],
      ),
      body: SafeArea(
        child: _resolving
            ? _buildCenteredMessage(isDarkMode, "Preparing sentences...", showSpinner: true)
            : _queue.isEmpty
                ? _buildCenteredMessage(isDarkMode, "No example sentences found for these cards.")
                : _finished
                    ? _buildCenteredMessage(isDarkMode, "Session complete!\n${_queue.length} sentences heard.")
                    : _waitingForMore
                        ? _buildCenteredMessage(isDarkMode, "Loading more sentences...", showSpinner: true)
                        : _buildPlayer(isDarkMode),
      ),
    );
  }

  Widget _buildCenteredMessage(bool isDarkMode, String message, {bool showSpinner = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner) ...[
              const CircularProgressIndicator(color: Color(0xFF9A00FE)),
              const SizedBox(height: 16),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white70 : Colors.black54),
            ),
            if (!showSpinner) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A00FE),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Done"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer(bool isDarkMode) {
    final entry = _queue[_index];
    final sentence = entry.sentence;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / _queue.length,
                    backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
                    color: const Color(0xFF9A00FE),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_index + 1} / ${_queue.length}',
                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 12),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 380),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.card.japanese,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white54 : Colors.black45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Listener(
                              // Auto-loads the translate/add-to-deck pop-up
                              // as soon as a highlight is finished, the same
                              // as in Reading - no right-click/menu needed.
                              onPointerUp: (event) {
                                final selected = _selectedText;
                                if (selected.isNotEmpty) {
                                  _showSelectionPopup(selected, event.position);
                                }
                              },
                              child: SelectionArea(
                                onSelectionChanged: (content) => _selectedText = content?.plainText.trim() ?? '',
                                child: Text.rich(
                                  _sentenceSpan(sentence.text, isDarkMode),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _replaySentence,
                            icon: const Icon(Icons.volume_up, size: 20),
                            color: const Color(0xFF9A00FE),
                            tooltip: "Replay sentence",
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_translationRevealed)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: sentence.translation != null && sentence.translation!.isNotEmpty
                                  ? Text(
                                      sentence.translation!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.black54),
                                    )
                                  : Text(
                                      '${entry.card.english} (word meaning)',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        color: isDarkMode ? Colors.white54 : Colors.black45,
                                      ),
                                    ),
                            ),
                            IconButton(
                              onPressed: _replayTranslation,
                              icon: const Icon(Icons.volume_up, size: 18),
                              color: isDarkMode ? Colors.white54 : Colors.black45,
                              tooltip: "Replay translation",
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        )
                      else
                        TextButton.icon(
                          onPressed: () => setState(() => _translationRevealed = true),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text("Show translation"),
                          style: TextButton.styleFrom(
                            foregroundColor: isDarkMode ? Colors.white54 : Colors.black45,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Per-sentence attribution - Tatoeba's CC BY license
                      // requires crediting each sentence's own contributor,
                      // not just Tatoeba as a whole.
                      InkWell(
                        onTap: sentence.sentenceUrl == null ? null : () => _openSentenceSource(sentence.sentenceUrl),
                        child: Text(
                          sentence.username != null
                              ? 'Sentence by ${sentence.username} · ${sentence.license ?? 'Tatoeba'}'
                              : 'via Tatoeba',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDarkMode ? Colors.white38 : Colors.black38,
                            decoration: sentence.sentenceUrl != null ? TextDecoration.underline : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _index == 0 ? null : _previous,
                icon: const Icon(Icons.skip_previous),
                iconSize: 36,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
                iconSize: 56,
                color: const Color(0xFF9A00FE),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _skip,
                icon: const Icon(Icons.skip_next),
                iconSize: 36,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
