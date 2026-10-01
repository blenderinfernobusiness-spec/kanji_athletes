import 'package:flutter/material.dart';
import 'study_data.dart';
import 'spaced_repetition_standard.dart';
import 'listening_player.dart';
import 'games_mode.dart';
import 'lesson_data.dart';
import 'lesson_viewer_screen.dart';

// Shows a pop-up menu of study modes for a deck. "Spaced Repetition" and
// "Reading & Listening" work; "Games and more" just dismisses the menu.
void showStudyModeMenu(BuildContext context, StudyDeck deck, bool isDarkMode, VoidCallback onChanged) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    // The Study screen's own context, not the bottom sheet's - passed through
    // so Spaced Repetition can push its lesson/session onto it after the
    // sheet (and its transient context) is long gone. See hostContext below.
    builder: (sheetContext) => _StudyModeMenu(deck: deck, isDarkMode: isDarkMode, onChanged: onChanged, hostContext: context),
  );
}

// Starts a Spaced Repetition session, first showing that day's lesson recap
// (if one exists and hasn't been completed yet) - the session only begins
// once the user presses "Complete Lesson", landing them straight on day 1's
// first card. Closing the lesson early backs out without starting a session.
Future<void> _startSpacedRepetition(
  BuildContext context,
  StudyDeck deck,
  bool isDarkMode,
  VoidCallback onChanged,
) async {
  final trackId = deck.lessonSetId;
  final day = trackId == null ? 0 : lessonDayFor(deck);
  final lesson = trackId != null && day > 0 ? lessonForTrackAndDay(trackId, day) : null;
  if (lesson != null && !deck.completedLessonDays.contains(day)) {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => LessonViewerScreen(lesson: lesson, isDarkMode: isDarkMode),
      ),
    );
    if (completed != true) return;
    deck.completedLessonDays.add(day);
    onChanged();
  }
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SpacedRepetitionStandardScreen(
        deck: deck,
        isDarkMode: isDarkMode,
        onChanged: onChanged,
      ),
    ),
  );
}

class _StudyModeMenu extends StatelessWidget {
  final StudyDeck deck;
  final bool isDarkMode;
  final VoidCallback onChanged;
  final BuildContext hostContext;

  const _StudyModeMenu({
    required this.deck,
    required this.isDarkMode,
    required this.onChanged,
    required this.hostContext,
  });

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
              deck.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildModeButton(context, "Spaced Repetition", () async {
              Navigator.pop(context);
              await _startSpacedRepetition(hostContext, deck, isDarkMode, onChanged);
            }),
            _buildModeButton(context, "Reading & Listening", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListeningPlayerScreen(
                    title: deck.name,
                    cards: deck.cards,
                    isDarkMode: isDarkMode,
                  ),
                ),
              );
            }),
            _buildModeButton(context, "Games and more", () {
              Navigator.pop(context);
              showGamesMenu(context, deck.name, deck.cards, isDarkMode);
            }),
          ],
        ),
      ),
    );
  }
}
