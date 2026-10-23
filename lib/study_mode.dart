import 'package:flutter/material.dart';
import 'study_data.dart';
import 'spaced_repetition_standard.dart';
import 'listening_player.dart';
import 'games_mode.dart';
import 'lesson_data.dart';
import 'lesson_viewer_screen.dart';
import 'grammar_data.dart';
import 'study_progress_screen.dart';
import 'app_colors.dart';
import 'app_theme.dart';

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
// Public so onboarding_flow.dart can reuse the exact same entry point when
// auto-opening a freshly-added Kana Course deck, rather than duplicating it.
Future<void> startSpacedRepetition(
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
        builder: (context) => LessonViewerScreen(lesson: lesson, isDarkMode: isDarkMode, deck: deck, onChanged: onChanged),
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

// The Grammar deck's study is its lessons alone - no spaced repetition. Opens
// today's lesson, or once it's done, offers the next grammar point early.
Future<void> _startGrammarLesson(
  BuildContext context,
  StudyDeck deck,
  bool isDarkMode,
  VoidCallback onChanged,
) async {
  final today = lessonDayFor(deck);
  if (today < 1 || today > grammarPoints.last.day) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Every grammar point so far is covered.')),
    );
    return;
  }
  if (deck.completedLessonDays.contains(today)) {
    await _showNextGrammarPrompt(context, deck, isDarkMode, onChanged);
    return;
  }
  await _openGrammarDay(context, deck, today, isDarkMode, onChanged);
}

Future<void> _openGrammarDay(
  BuildContext context,
  StudyDeck deck,
  int day,
  bool isDarkMode,
  VoidCallback onChanged,
) async {
  final lesson = lessonForTrackAndDay(kGrammarTrackId, day);
  if (lesson == null) return;
  final completed = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (context) => LessonViewerScreen(lesson: lesson, isDarkMode: isDarkMode, deck: deck, onChanged: onChanged)),
  );
  if (completed != true) return;
  if (!deck.completedLessonDays.contains(day)) {
    deck.completedLessonDays.add(day);
    onChanged();
  }
  if (!context.mounted) return;
  await _showNextGrammarPrompt(context, deck, isDarkMode, onChanged);
}

int? _nextUncompletedGrammarDay(StudyDeck deck, int after) {
  for (final point in grammarPoints) {
    if (point.day > after && !deck.completedLessonDays.contains(point.day)) return point.day;
  }
  return null;
}

Future<void> _showNextGrammarPrompt(
  BuildContext context,
  StudyDeck deck,
  bool isDarkMode,
  VoidCallback onChanged,
) async {
  final today = lessonDayFor(deck);
  final next = _nextUncompletedGrammarDay(deck, today);
  final nextLesson = next == null ? null : lessonForTrackAndDay(kGrammarTrackId, next);
  final fg = AppColors.text(isDarkMode);
  final muted = AppColors.textMuted(isDarkMode);

  final learnNow = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.cardBg(isDarkMode),
      shape: pixelShape() ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        nextLesson == null ? 'All caught up' : 'Lesson complete',
        style: TextStyle(color: fg, fontWeight: FontWeight.bold),
      ),
      content: Text(
        nextLesson == null
            ? 'You have covered every grammar point so far. The next one unlocks tomorrow.'
            : 'Want to keep going? Day $next is "${nextLesson.title}". Or come back for it tomorrow.',
        style: TextStyle(color: muted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Not now'),
        ),
        if (nextLesson != null)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Learn Day $next now'),
          ),
      ],
    ),
  );

  if (learnNow == true && next != null && context.mounted) {
    await _openGrammarDay(context, deck, next, isDarkMode, onChanged);
  }
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
    final isGrammar = isGrammarTrackId(deck.lessonSetId);
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
              deck.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text(isDarkMode),
              ),
            ),
            const SizedBox(height: 16),
            if (isGrammar)
              _buildModeButton(context, "Lessons", () async {
                Navigator.pop(context);
                await _startGrammarLesson(hostContext, deck, isDarkMode, onChanged);
              }, iconId: 'tabLessons')
            else
              _buildModeButton(context, "Spaced Repetition", () async {
                Navigator.pop(context);
                await startSpacedRepetition(hostContext, deck, isDarkMode, onChanged);
              }, iconId: 'tabCards'),
            // No lesson recap, no new cards, no challenge-day gating, and
            // nothing ever offers to pull more new cards in - just today's
            // due reviews, for every deck including the Grammar deck and the
            // day-scheduled challenge decks (which skip their lesson/unlock
            // flow here entirely).
            _buildModeButton(context, "Spaced Repetition (Only Revision)", () {
              Navigator.pop(context);
              Navigator.push(
                hostContext,
                MaterialPageRoute(
                  builder: (context) => SpacedRepetitionStandardScreen(
                    deck: deck,
                    isDarkMode: isDarkMode,
                    onChanged: onChanged,
                    revisionOnly: true,
                  ),
                ),
              );
            }, iconId: 'tabCards'),
            _buildModeButton(context, "Reading & Listening", () {
              Navigator.pop(context);
              Navigator.push(
                hostContext,
                MaterialPageRoute(
                  builder: (context) => ListeningPlayerScreen(
                    title: deck.name,
                    cards: deck.cards,
                    isDarkMode: isDarkMode,
                    fixedSentences: isGrammar ? grammarSentencesByForm() : null,
                  ),
                ),
              );
            }, iconId: 'tabReading'),
            _buildModeButton(context, "Games and more", () {
              Navigator.pop(context);
              showGamesMenu(hostContext, deck.name, deck.cards, isDarkMode);
            }, iconId: 'sword'),
            if (deck.lessonSetId != null)
              _buildModeButton(context, "Study progress", () {
                Navigator.pop(context);
                Navigator.push(
                  hostContext,
                  MaterialPageRoute(
                    builder: (context) => StudyProgressScreen(deck: deck, isDarkMode: isDarkMode, onChanged: onChanged),
                  ),
                );
              }, iconId: 'stats'),
          ],
        ),
      ),
    );
  }
}
