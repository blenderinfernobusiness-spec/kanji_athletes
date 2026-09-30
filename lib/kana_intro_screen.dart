import 'package:flutter/material.dart';
import 'study_data.dart';
import 'study_settings.dart';
import 'audio_service.dart';

const _kPurple = Color(0xFF9A00FE);

// Shown once, automatically, the first time a brand-new Kana-type flashcard
// comes up in a Hiragana Challenge session (see spaced_repetition_standard
// .dart's _maybeShowCardIntroBatch) - a quick "here's the character and its
// sound" beat before it's drilled by drawing it, prompted by that sound.
// Much lighter than KanjiIntroScreen/VocabIntroScreen since a bare kana
// character has no dictionary meaning or example sentences of its own -
// those come right after, as the character's own example-word flashcards.
class KanaIntroScreen extends StatefulWidget {
  final StudyCard card;
  final bool isDarkMode;
  // This card's 1-based position and the batch size, for a small "2 of 4"
  // progress label - see KanjiIntroScreen/VocabIntroScreen for the same
  // convention.
  final int? batchPosition;
  final int? batchTotal;

  const KanaIntroScreen({
    super.key,
    required this.card,
    required this.isDarkMode,
    this.batchPosition,
    this.batchTotal,
  });

  @override
  State<KanaIntroScreen> createState() => _KanaIntroScreenState();
}

class _KanaIntroScreenState extends State<KanaIntroScreen> {
  StudySettings _settings = StudySettings();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await loadStudySettings();
    if (!mounted) return;
    setState(() => _settings = settings);
  }

  Future<void> _speak() async {
    final ok = await AudioService().speak(
      widget.card.japanese,
      'Japanese',
      rate: _settings.japaneseSpeed,
      voiceName: _settings.japaneseVoiceName,
    );
    if (!ok && mounted) showMissingVoiceSnackBar(context, widget.isDarkMode, 'Japanese');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final card = widget.card;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: Text(
          widget.batchTotal != null && widget.batchTotal! > 1
              ? 'New Hiragana  ·  ${widget.batchPosition}/${widget.batchTotal}'
              : 'New Hiragana',
        ),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      card.japanese,
                      style: TextStyle(fontSize: 96, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : Colors.black),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up, size: 32),
                      color: _kPurple,
                      onPressed: _speak,
                    ),
                  ],
                ),
                Text(
                  card.romaji.isNotEmpty ? card.romaji : card.english,
                  style: TextStyle(fontSize: 28, color: isDarkMode ? Colors.white70 : Colors.black54),
                ),
                const SizedBox(height: 24),
                Text(
                  "You'll practice drawing this next, prompted by its sound.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white54 : Colors.black45),
                ),
              ],
            ),
          ),
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
                widget.batchTotal == null || (widget.batchPosition ?? widget.batchTotal!) >= widget.batchTotal!
                    ? "Start studying"
                    : "Next",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
