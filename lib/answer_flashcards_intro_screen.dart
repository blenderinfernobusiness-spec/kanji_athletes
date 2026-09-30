import 'package:flutter/material.dart';

const _kPurple = Color(0xFF9A00FE);

// Shown once, automatically, right before the very first card of ANY deck is
// ever drilled in a Spaced Repetition session - special decks (the 90 Day
// Kanji Challenge, Essential Vocabulary Challenge, Hiragana Challenge) and
// ordinary custom decks alike (see StudyDeck.hasShownAnswerIntro and
// spaced_repetition_standard.dart's _maybeShowAnswerIntro). Explains however
// that deck's cards actually work to answer, based on the first card's own
// answer mode.
class AnswerFlashcardsIntroScreen extends StatelessWidget {
  final String mode; // 'basic', 'draw', or 'type'
  final bool isDarkMode;

  const AnswerFlashcardsIntroScreen({super.key, required this.mode, required this.isDarkMode});

  IconData get _icon {
    switch (mode) {
      case 'draw':
        return Icons.edit;
      case 'type':
        return Icons.keyboard;
      case 'basic':
      default:
        return Icons.visibility;
    }
  }

  String get _title {
    switch (mode) {
      case 'draw':
        return "Draw the answer";
      case 'type':
        return "Type the answer";
      case 'basic':
      default:
        return "Reveal and grade yourself";
    }
  }

  String get _body {
    switch (mode) {
      case 'draw':
        return "You'll be prompted with a sound or meaning - draw the character from memory on the canvas, then "
            "tap Reveal to check yourself against the correct stroke order. Mark whether you got it right; cards "
            "you miss come back around sooner so you see them again.";
      case 'type':
        return "You'll see a prompt - type what you think the answer is and it's checked automatically the moment "
            "you submit it. Cards you get wrong come back around sooner so you see them again.";
      case 'basic':
      default:
        return "You'll see a prompt - try to recall the answer in your head, then tap Reveal to check yourself "
            "against it. Mark whether you got it right or wrong; cards you miss come back around sooner so you "
            "see them again.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _icon;
    final title = _title;
    final body = _body;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: const Text('How This Works'),
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
                Icon(icon, size: 56, color: _kPurple),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _kPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.4, color: isDarkMode ? Colors.white70 : Colors.black54),
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
