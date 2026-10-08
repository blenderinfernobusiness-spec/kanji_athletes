import 'package:flutter/material.dart';
import 'study_data.dart';
import 'study_settings.dart';
import 'audio_service.dart';
import 'translation_service.dart';
import 'listening_player.dart' show WordPopupCard, DeckPickerDialog, SelectionTranslateCard;

// Splits imported text into individual sentences, breaking on Japanese/
// English sentence-ending punctuation (。！？.!?) as well as line breaks -
// good enough for arbitrary pasted text without needing full segmentation.
List<String> splitIntoSentences(String text) {
  final sentences = <String>[];
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(ch);
    if ('。！？.!?\n'.contains(ch)) {
      final s = buffer.toString().trim();
      if (s.isNotEmpty) sentences.add(s);
      buffer.clear();
    }
  }
  final rest = buffer.toString().trim();
  if (rest.isNotEmpty) sentences.add(rest);
  return sentences;
}

// Reads an imported passage of Japanese text, broken down sentence by
// sentence (the default view). Each sentence gets the same LingQ-style word
// highlighting/lookup as Listening mode - dictionary words in light purple,
// deck words in a darker purple, tap for a popup with reading/romaji/
// meaning/memory technique/kanji breakdown/add-to-deck - plus its own play
// button, and a transport bar at the bottom plays straight through the
// passage exactly like Listening mode's play/pause/skip/previous controls.
class ReadingTextScreen extends StatefulWidget {
  final ReadingText readingText;
  final bool isDarkMode;

  const ReadingTextScreen({
    super.key,
    required this.readingText,
    required this.isDarkMode,
  });

  @override
  State<ReadingTextScreen> createState() => _ReadingTextScreenState();
}

class _ReadingTextScreenState extends State<ReadingTextScreen> {
  Map<String, HighlightEntry> _highlightIndex = {};
  StudySettings _settings = StudySettings();
  List<Map<String, dynamic>> _japaneseVoices = [];
  bool _loading = true;
  OverlayEntry? _wordPopup;
  OverlayEntry? _selectionPopup;
  String _selectedText = '';

  late final List<String> _sentences = splitIntoSentences(widget.readingText.content);
  late final List<GlobalKey> _sentenceKeys = List.generate(_sentences.length, (_) => GlobalKey());
  int _currentIndex = 0;
  bool _playing = false;
  int _playbackRunId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final decks = await loadStudyDecks();
    final allCards = <StudyCard>[for (final deck in decks) ...deck.cards];
    final settings = await loadStudySettings();
    final voices = await AudioService().voicesForLanguage('Japanese');
    if (!mounted) return;
    setState(() {
      _highlightIndex = buildHighlightIndex(allCards);
      _settings = settings;
      _japaneseVoices = voices;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _playbackRunId++;
    AudioService().stop();
    _closeWordPopup();
    _closeSelectionPopup();
    super.dispose();
  }

  Future<void> _playCurrent() async {
    final runId = ++_playbackRunId;
    if (_currentIndex >= _sentences.length) {
      setState(() => _playing = false);
      return;
    }
    setState(() {});
    final ok = await AudioService().speak(
      _sentences[_currentIndex],
      'Japanese',
      rate: _settings.japaneseSpeed,
      voiceName: _settings.japaneseVoiceName,
      waitForCompletion: true,
    );
    if (!ok) {
      if (mounted) {
        showMissingVoiceSnackBar(context, widget.isDarkMode, 'Japanese');
        setState(() => _playing = false);
      }
      return;
    }
    if (runId != _playbackRunId || !mounted || !_playing) return;
    await Future.delayed(const Duration(milliseconds: 400));
    if (runId != _playbackRunId || !mounted || !_playing) return;

    if (_currentIndex + 1 >= _sentences.length) {
      setState(() => _playing = false);
      return;
    }
    if (_settings.listeningAutoAdvance) {
      _advance();
    } else {
      setState(() => _playing = false);
    }
  }

  // Auto-scrolls the whole-text view to the currently playing sentence -
  // harmlessly a no-op in single-sentence mode, since no other sentence's
  // key is mounted there.
  void _scrollToCurrent() {
    final ctx = _sentenceKeys[_currentIndex].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.3);
    }
  }

  void _advance() {
    setState(() => _currentIndex++);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    _playCurrent();
  }

  void _togglePlayPause() {
    if (_sentences.isEmpty) return;
    setState(() => _playing = !_playing);
    if (_playing) {
      _playCurrent();
    } else {
      AudioService().stop();
      _playbackRunId++;
    }
  }

  // Manual page-flip, LingQ-style - just moves to the next/previous sentence
  // in silence unless sequential playback is already running, in which case
  // it keeps reading from the new sentence.
  void _skip() {
    if (_sentences.isEmpty || _currentIndex + 1 >= _sentences.length) return;
    AudioService().stop();
    _playbackRunId++;
    setState(() => _currentIndex++);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    if (_playing) _playCurrent();
  }

  void _previous() {
    if (_currentIndex == 0) return;
    AudioService().stop();
    _playbackRunId++;
    setState(() => _currentIndex--);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    if (_playing) _playCurrent();
  }

  Future<void> _translateSentence(int index) => openGoogleTranslate(_sentences[index]);

  // Plays a single tapped sentence on its own, pausing any sequential
  // playback rather than continuing through the passage - mirrors
  // Listening's manual "replay" buttons.
  Future<void> _playSentenceAt(int index) async {
    AudioService().stop();
    _playbackRunId++;
    setState(() {
      _playing = false;
      _currentIndex = index;
    });
    final ok = await AudioService().speak(
      _sentences[index],
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

  void _closeSelectionPopup() {
    _selectionPopup?.remove();
    _selectionPopup = null;
  }

  // Shows a little anchored box (same style as the word lookup popup) for a
  // free-form text selection: the selected text, its translation (fetched
  // automatically as soon as it opens, via MyMemory), a speaker button, a
  // practice-writing button when it contains kanji, and an add-to-deck
  // action - triggered as soon as the user finishes highlighting text,
  // rather than needing to right-click and choose "Translate".
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
              onAddToDeck: (toAdd) {
                _closeWordPopup();
                _addEntryToDeck(toAdd);
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
    await updateCardInAllDecks(entry.japanese, (c) => c.memoryTechnique = technique);
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
              "Reading Settings",
              style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
            ),
            content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Show whole text",
                        style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87, fontSize: 14),
                      ),
                      subtitle: Text(
                        "See the whole passage at once, split into sentences by line breaks, instead of one sentence per screen.",
                        style: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black45, fontSize: 12),
                      ),
                      value: _settings.readingWholeTextView,
                      activeColor: const Color(0xFF9A00FE),
                      onChanged: (v) => applyChange(() => _settings.readingWholeTextView = v),
                    ),
                    const Divider(height: 24),
                    Text("Text size", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 13)),
                    Row(
                      children: [
                        Text("A", style: TextStyle(fontSize: 14, color: widget.isDarkMode ? Colors.white54 : Colors.black45)),
                        Expanded(
                          child: Slider(
                            value: _settings.readingTextScale,
                            min: 0.8,
                            max: 1.6,
                            divisions: 8,
                            activeColor: const Color(0xFF9A00FE),
                            label: '${(_settings.readingTextScale * 100).round()}%',
                            onChanged: (v) => applyChange(() => _settings.readingTextScale = v),
                          ),
                        ),
                        Text("A", style: TextStyle(fontSize: 22, color: widget.isDarkMode ? Colors.white54 : Colors.black45)),
                      ],
                    ),
                    const Divider(height: 24),
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
                    const SizedBox(height: 8),
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

  InlineSpan _sentenceSpan(String text, bool isDarkMode) {
    final baseStyle = TextStyle(
      fontSize: 20 * _settings.readingTextScale,
      height: 1.9,
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
                    alpha: tok.entry!.isDeckWord ? (isDarkMode ? 0.55 : 0.35) : (isDarkMode ? 0.25 : 0.15),
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

  // Opens the sentence in Google Translate externally - shared between
  // single-sentence and whole-text view. There's no in-app translation API
  // wired up right now, so this is the stand-in until one is.
  Widget _translateAction(int index, bool isDarkMode, {double iconSize = 20}) {
    return IconButton(
      onPressed: () => _translateSentence(index),
      icon: const Icon(Icons.translate),
      iconSize: iconSize,
      color: isDarkMode ? Colors.white54 : Colors.black45,
      visualDensity: VisualDensity.compact,
      tooltip: "Translate this sentence on Google Translate",
    );
  }

  // One sentence fills the whole reading area, LingQ-style, with speaker and
  // translate buttons for just this sentence - Previous/Next in the
  // transport bar below flip between sentences.
  Widget _buildCurrentSentence(bool isDarkMode) {
    final index = _currentIndex;
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(_sentenceSpan(_sentences[index], isDarkMode), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _playSentenceAt(index),
                    icon: const Icon(Icons.volume_up),
                    iconSize: 28,
                    color: const Color(0xFF9A00FE),
                    tooltip: "Play this sentence",
                  ),
                  const SizedBox(width: 8),
                  _translateAction(index, isDarkMode, iconSize: 26),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Whole-text mode: every sentence at once, each on its own line/card, with
  // its own play + translate buttons; the sentence currently being read (via
  // the transport bar's sequential playback) is outlined.
  Widget _buildWholeTextView(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _sentences.length,
      itemBuilder: (context, index) {
        final isActive = index == _currentIndex && _playing;
        return Container(
          key: _sentenceKeys[index],
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: isActive ? Border.all(color: const Color(0xFF9A00FE), width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text.rich(_sentenceSpan(_sentences[index], isDarkMode))),
                  IconButton(
                    onPressed: () => _playSentenceAt(index),
                    icon: const Icon(Icons.volume_up, size: 20),
                    color: const Color(0xFF9A00FE),
                    visualDensity: VisualDensity.compact,
                    tooltip: "Play this sentence",
                  ),
                  _translateAction(index, isDarkMode),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransportBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
        border: Border(top: BorderSide(color: isDarkMode ? Colors.white12 : Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentIndex == 0 ? null : _previous,
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
            onPressed: _currentIndex + 1 >= _sentences.length ? null : _skip,
            icon: const Icon(Icons.skip_next),
            iconSize: 36,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: Text(widget.readingText.title, overflow: TextOverflow.ellipsis),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showSettingsDialog,
            icon: const Icon(Icons.settings),
            tooltip: "Reading settings",
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF9A00FE)))
            : _sentences.isEmpty
                ? Center(
                    child: Text(
                      "No readable text found.",
                      style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                    ),
                  )
                : Column(
                    children: [
                      if (!_settings.readingWholeTextView)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (_currentIndex + 1) / _sentences.length,
                                    backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
                                    color: const Color(0xFF9A00FE),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${_currentIndex + 1} / ${_sentences.length}',
                                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: Listener(
                          // Auto-loads the translate/add-to-deck pop-up as
                          // soon as a highlight is finished (pointer/finger
                          // released), rather than needing to right-click (or
                          // long-press) and choose "Translate" from a menu.
                          onPointerUp: (event) {
                            final selected = _selectedText;
                            if (selected.isNotEmpty) {
                              _showSelectionPopup(selected, event.position);
                            }
                          },
                          child: SelectionArea(
                            onSelectionChanged: (content) => _selectedText = content?.plainText.trim() ?? '',
                            child: _settings.readingWholeTextView
                                ? _buildWholeTextView(isDarkMode)
                                : _buildCurrentSentence(isDarkMode),
                          ),
                        ),
                      ),
                      _buildTransportBar(isDarkMode),
                    ],
                  ),
      ),
    );
  }
}

