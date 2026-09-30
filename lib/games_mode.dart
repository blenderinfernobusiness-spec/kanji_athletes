import 'package:flutter/material.dart';
import 'study_data.dart';
import 'game_scope_dialog.dart';
import 'writing_game.dart';
import 'reading_game.dart';
import 'match_game.dart';
import 'balloon_game.dart';
import 'jlpt_setup_screen.dart';

// Pop-up menu of games for a deck or Mistakes selection - shared by
// study_mode.dart and mistakes_mode.dart's "Games and more" button. Each
// choice first asks how many cards to play (and how to pick them) via
// showGameScopeDialog, then launches the chosen game.
void showGamesMenu(BuildContext context, String title, List<StudyCard> cards, bool isDarkMode) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _GamesMenu(title: title, cards: cards, isDarkMode: isDarkMode),
  );
}

class _GamesMenu extends StatelessWidget {
  final String title;
  final List<StudyCard> cards;
  final bool isDarkMode;

  const _GamesMenu({required this.title, required this.cards, required this.isDarkMode});

  Widget _buildModeButton(BuildContext context, String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9A00FE),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: onPressed,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Future<void> _startGame(
    BuildContext context,
    Widget Function(List<StudyCard> questions) buildScreen,
  ) async {
    // Grab the Navigator (and its own, long-lived context) before popping the
    // bottom sheet - by the time the scope dialog resolves, the sheet's own
    // context is long gone, so checking *its* .mounted (or pushing through
    // it) would silently no-op even though the surrounding screen is still
    // very much alive.
    final navigator = Navigator.of(context);
    navigator.pop();
    final questions = await showGameScopeDialog(navigator.context, cards: cards, isDarkMode: isDarkMode);
    if (questions == null || questions.isEmpty) return;
    navigator.push(MaterialPageRoute(builder: (context) => buildScreen(questions)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildModeButton(
              context,
              "Writing",
              () => _startGame(
                context,
                (questions) => WritingGameScreen(title: title, questions: questions, isDarkMode: isDarkMode),
              ),
            ),
            _buildModeButton(
              context,
              "Reading",
              () => _startGame(
                context,
                (questions) => ReadingGameScreen(title: title, questions: questions, isDarkMode: isDarkMode),
              ),
            ),
            _buildModeButton(
              context,
              "Match",
              () => _startGame(
                context,
                (questions) => MatchGameScreen(title: title, questions: questions, isDarkMode: isDarkMode),
              ),
            ),
            _buildModeButton(
              context,
              "Balloons",
              () => _startGame(
                context,
                (questions) => BalloonGameScreen(title: title, questions: questions, isDarkMode: isDarkMode),
              ),
            ),
            _buildModeButton(
              context,
              "JLPT Test",
              () => _startGame(
                context,
                (questions) => JlptSetupScreen(title: title, questions: questions, isDarkMode: isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
