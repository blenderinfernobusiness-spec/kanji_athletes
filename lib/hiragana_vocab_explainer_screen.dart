import 'package:flutter/material.dart';

const _kPurple = Color(0xFF9A00FE);

// Shown once, automatically, the very first time a Hiragana Challenge
// session reaches its first batch of example-word flashcards - explains how
// those cards work (hiragana with a kanji preview in brackets, romaji and
// meaning revealed on the back) right when it's actually relevant, rather
// than as a generic slide back in the Day 1 lesson before any hiragana had
// even been introduced. See spaced_repetition_standard.dart's
// _maybeShowCardIntroBatch for the one-time gating.
class HiraganaVocabExplainerScreen extends StatelessWidget {
  final bool isDarkMode;
  const HiraganaVocabExplainerScreen({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: const Text('Example Words'),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Now that you know a few hiragana, here are some real words that use them.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.black54),
                ),
                const SizedBox(height: 28),
                Text(
                  'あめ（雨）',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 14),
                Text('a me', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 6),
                Text('Rain', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _kPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    "Each word is written in hiragana - flip the card to see the romaji and meaning, and hear it "
                    "read aloud. When a word has a kanji spelling, like 雨 here, it's shown in brackets as a "
                    "preview - you don't need to learn it yet, it'll come naturally in the 90 Day Kanji Challenge.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black54),
                  ),
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
              child: const Text("Got it", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}
