import 'package:flutter/material.dart';
import 'study_data.dart';
import 'isolated_flashcard_study.dart';
import 'listening_player.dart';
import 'games_mode.dart';
import 'app_colors.dart';
import 'app_theme.dart';

// Pop-up menu of study modes for a Mistakes selection. "Isolated Flashcard
// Study" and "Reading & Listening" work; "Games and more" just dismisses the menu,
// matching the regular per-deck study menu.
void showMistakesModeMenu(BuildContext context, String title, List<StudyCard> cards, bool isDarkMode) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _MistakesModeMenu(title: title, cards: cards, isDarkMode: isDarkMode),
  );
}

class _MistakesModeMenu extends StatelessWidget {
  final String title;
  final List<StudyCard> cards;
  final bool isDarkMode;

  const _MistakesModeMenu({required this.title, required this.cards, required this.isDarkMode});

  Widget _buildModeButton(BuildContext context, String label, VoidCallback onPressed, {String? iconId}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: pixelShape() ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconId != null) ...[
                ThemedIcon(iconId: iconId, size: 22, fallback: const SizedBox.shrink()),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: pixelPanelDecoration(fill: AppColors.cardBg(isDarkMode)) ??
            BoxDecoration(
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
                color: AppColors.text(isDarkMode),
              ),
            ),
            const SizedBox(height: 16),
            _buildModeButton(context, "Isolated Flashcard Study", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IsolatedFlashcardStudyScreen(
                    title: title,
                    cards: cards,
                    isDarkMode: isDarkMode,
                  ),
                ),
              );
            }, iconId: 'tabCards'),
            _buildModeButton(context, "Reading & Listening", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListeningPlayerScreen(
                    title: title,
                    cards: cards,
                    isDarkMode: isDarkMode,
                  ),
                ),
              );
            }, iconId: 'tabReading'),
            _buildModeButton(context, "Games and more", () {
              Navigator.pop(context);
              showGamesMenu(context, title, cards, isDarkMode);
            }, iconId: 'sword'),
          ],
        ),
      ),
    );
  }
}
