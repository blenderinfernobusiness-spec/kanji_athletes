import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'study_data.dart';

const String _mistakesPrefsKey = 'study_mistakes';
// Caps how many mistakes are kept around - comfortably above the biggest
// "last N" filter (250) so that filter always has enough history to draw on.
const int _maxStoredMistakes = 1000;

// A single incorrect answer, logged from any deck's spaced repetition
// session, kept as a self-contained snapshot so it still displays correctly
// even if the original card is later edited or deleted.
class MistakeEntry {
  final String deckName;
  final String japanese;
  final String hiragana;
  final String romaji;
  final String english;
  final List<String> kanjiVGCodes;
  final bool englishFirst;
  final String memoryTechnique;
  final DateTime timestamp;

  MistakeEntry({
    required this.deckName,
    required this.japanese,
    required this.hiragana,
    this.romaji = '',
    required this.english,
    List<String>? kanjiVGCodes,
    this.englishFirst = true,
    this.memoryTechnique = '',
    required this.timestamp,
  }) : kanjiVGCodes = kanjiVGCodes ?? [];

  factory MistakeEntry.fromCard(StudyCard card, String deckName) => MistakeEntry(
    deckName: deckName,
    japanese: card.japanese,
    hiragana: card.hiragana,
    romaji: card.romaji,
    english: card.english,
    kanjiVGCodes: List<String>.from(card.kanjiVGCodes),
    englishFirst: card.englishFirst,
    memoryTechnique: card.memoryTechnique,
    timestamp: DateTime.now(),
  );

  // A throwaway StudyCard for isolated review - never written back to any
  // deck, so studying it can never affect the original card's progress.
  StudyCard toStudyCard() => StudyCard(
    japanese: japanese,
    hiragana: hiragana,
    romaji: romaji,
    english: english,
    kanjiVGCodes: List<String>.from(kanjiVGCodes),
    englishFirst: englishFirst,
    memoryTechnique: memoryTechnique,
  );

  Map<String, dynamic> toMap() => {
    'deckName': deckName,
    'japanese': japanese,
    'hiragana': hiragana,
    'romaji': romaji,
    'english': english,
    'kanjiVGCodes': kanjiVGCodes,
    'englishFirst': englishFirst,
    'memoryTechnique': memoryTechnique,
    'timestamp': timestamp.toIso8601String(),
  };

  factory MistakeEntry.fromMap(Map<String, dynamic> map) => MistakeEntry(
    deckName: map['deckName'] ?? '',
    japanese: map['japanese'] ?? '',
    hiragana: map['hiragana'] ?? '',
    romaji: map['romaji'] ?? '',
    english: map['english'] ?? '',
    kanjiVGCodes: List<String>.from(map['kanjiVGCodes'] ?? const []),
    englishFirst: map['englishFirst'] ?? true,
    memoryTechnique: map['memoryTechnique'] ?? '',
    timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
  );
}

Future<List<MistakeEntry>> loadMistakes() async {
  final prefs = await SharedPreferences.getInstance();
  final encoded = prefs.getString(_mistakesPrefsKey);
  if (encoded == null) return [];
  final decoded = jsonDecode(encoded) as List<dynamic>;
  return decoded.map((m) => MistakeEntry.fromMap(Map<String, dynamic>.from(m))).toList();
}

Future<void> _saveMistakes(List<MistakeEntry> mistakes) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_mistakesPrefsKey, jsonEncode(mistakes.map((m) => m.toMap()).toList()));
}

// Called whenever a card is answered incorrectly during spaced repetition.
Future<void> logMistake(StudyCard card, String deckName) async {
  final mistakes = await loadMistakes();
  mistakes.add(MistakeEntry.fromCard(card, deckName));
  if (mistakes.length > _maxStoredMistakes) {
    mistakes.removeRange(0, mistakes.length - _maxStoredMistakes);
  }
  await _saveMistakes(mistakes);
}

// Undo counterpart to logMistake - removes the most recently logged
// mistake, used when the incorrect answer that created it is undone.
Future<void> removeLastMistake() async {
  final mistakes = await loadMistakes();
  if (mistakes.isEmpty) return;
  mistakes.removeLast();
  await _saveMistakes(mistakes);
}

// Filters the full mistake log down to one of the study menu's scopes.
List<MistakeEntry> filterMistakes(List<MistakeEntry> all, String scope) {
  final now = DateTime.now();
  switch (scope) {
    case 'today':
      final todayStart = DateTime(now.year, now.month, now.day);
      return all.where((m) => !m.timestamp.isBefore(todayStart)).toList();
    case 'week':
      final weekStart = now.subtract(const Duration(days: 7));
      return all.where((m) => m.timestamp.isAfter(weekStart)).toList();
    case 'last100':
      return all.length <= 100 ? List.of(all) : all.sublist(all.length - 100);
    case 'last250':
      return all.length <= 250 ? List.of(all) : all.sublist(all.length - 250);
    default:
      return List.of(all);
  }
}
