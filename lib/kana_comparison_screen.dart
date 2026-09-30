import 'package:flutter/material.dart';

const _kPurple = Color(0xFF9A00FE);

// Shown right after KanaIntroScreen for a katakana character, comparing it
// side by side with the hiragana it's already known for the same sound
// (see hiragana_challenge_data.dart's hiraganaEquivalentOf) - the same
// "COMPARISON" beat the Katakana Challenge lesson videos use, reassuring the
// learner they're not learning a new sound, just a new way of writing one
// they already know.
class KanaComparisonScreen extends StatelessWidget {
  final String katakana;
  final String hiragana;
  final bool isDarkMode;

  const KanaComparisonScreen({super.key, required this.katakana, required this.hiragana, required this.isDarkMode});

  Widget _tile(bool isDarkMode, String char, String label) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(char, style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black45)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: const Text('Comparison'),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Text(
                'Same sound, different script!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: isDarkMode ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _tile(isDarkMode, katakana, 'katakana'),
                  const SizedBox(width: 16),
                  Icon(Icons.compare_arrows, color: _kPurple, size: 28),
                  const SizedBox(width: 16),
                  _tile(isDarkMode, hiragana, 'hiragana'),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "$katakana and $hiragana are read exactly the same way - katakana is just used for a different "
                "category of words (mostly foreign loanwords and names), not a new sound to learn.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ],
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
