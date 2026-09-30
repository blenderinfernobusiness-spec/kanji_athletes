import 'package:flutter/material.dart';
import 'study_data.dart';
import 'sets_data.dart';
import 'kanji_challenge_data.dart';

// Replaces the old To-Do list button on the home screen. Summarizes Study
// progress: total words studied (nextReviewDate != null is the same "has
// been studied at least once" signal spaced_repetition_standard.dart uses),
// a breakdown by JLPT level (cross-referenced against the dictionary's own
// JLPT tags, since StudyCard itself doesn't carry a level), and 90 Day Kanji
// Challenge progress if that deck exists.
class StatsScreen extends StatefulWidget {
  final bool isDarkMode;

  const StatsScreen({super.key, required this.isDarkMode});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _loading = true;
  int _deckCount = 0;
  int _totalCards = 0;
  int _studiedCount = 0;
  Map<String, int> _levelCounts = {};
  int _otherCount = 0;

  StudyDeck? _challengeDeck;
  int _challengeDayNumber = 0;
  int _challengeStudied = 0;
  int _challengeTotal = 0;
  int _challengeUnlocked = 0;

  static const List<String> _levelOrder = ['N1', 'N2', 'N3', 'N4', 'N5'];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final decks = await loadStudyDecks();
    final allCards = <StudyCard>[for (final d in decks) ...d.cards];
    final studiedCards = allCards.where((c) => c.nextReviewDate != null).toList();

    // Cross-reference each studied card's japanese text against the
    // dictionary's own JLPT tags to bucket it by level.
    final levelByWord = <String, String>{};
    for (final set in setsData.values) {
      for (final item in set.items) {
        final tags = item.tags.isNotEmpty ? item.tags : set.tags;
        for (final tag in tags) {
          final match = RegExp(r'JLPT (N[1-5])').firstMatch(tag);
          if (match != null) {
            levelByWord.putIfAbsent(item.japanese.trim(), () => match.group(1)!);
            break;
          }
        }
      }
    }

    final levelCounts = {for (final l in _levelOrder) l: 0};
    int otherCount = 0;
    for (final c in studiedCards) {
      final level = levelByWord[c.japanese.trim()];
      if (level != null && levelCounts.containsKey(level)) {
        levelCounts[level] = levelCounts[level]! + 1;
      } else {
        otherCount++;
      }
    }

    StudyDeck? challengeDeck;
    for (final d in decks) {
      if (d.challengeStartDate != null) {
        challengeDeck = d;
        break;
      }
    }

    int challengeDayNumber = 0;
    int challengeStudied = 0;
    int challengeTotal = 0;
    int challengeUnlocked = 0;
    if (challengeDeck != null) {
      challengeTotal = challengeDeck.cards.length;
      challengeStudied = challengeDeck.cards.where((c) => c.nextReviewDate != null).length;
      final start = DateTime.parse(challengeDeck.challengeStartDate!);
      challengeDayNumber = DateTime.now().difference(start).inDays + 1;
      if (challengeDayNumber < 1) challengeDayNumber = 1;
      if (challengeDayNumber > kanjiChallengeDays.length) challengeDayNumber = kanjiChallengeDays.length;
      challengeUnlocked = challengeDeck.cards.where((c) => (c.challengeDay ?? 1) <= challengeDayNumber).length;
    }

    if (!mounted) return;
    setState(() {
      _deckCount = decks.length;
      _totalCards = allCards.length;
      _studiedCount = studiedCards.length;
      _levelCounts = levelCounts;
      _otherCount = otherCount;
      _challengeDeck = challengeDeck;
      _challengeDayNumber = challengeDayNumber;
      _challengeStudied = challengeStudied;
      _challengeTotal = challengeTotal;
      _challengeUnlocked = challengeUnlocked;
      _loading = false;
    });
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
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
        title: const Text('Stats'),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF9A00FE)))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Study progress',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        _statRow('Decks', '$_deckCount'),
                        _statRow('Total cards', '$_totalCards'),
                        _statRow('Words studied', '$_studiedCount'),
                        if (_totalCards > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _studiedCount / _totalCards,
                                minHeight: 8,
                                backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
                                color: const Color(0xFF9A00FE),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Words studied by JLPT level',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        for (final level in _levelOrder) _statRow(level, '${_levelCounts[level] ?? 0}'),
                        _statRow('Not JLPT-tagged', '$_otherCount'),
                      ],
                    ),
                  ),
                  if (_challengeDeck != null)
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kanjiChallengeDeckName,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          _statRow('Day', '$_challengeDayNumber / ${kanjiChallengeDays.length}'),
                          _statRow('Kanji unlocked', '$_challengeUnlocked / $_challengeTotal'),
                          _statRow('Kanji studied', '$_challengeStudied / $_challengeTotal'),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _challengeTotal > 0 ? _challengeStudied / _challengeTotal : 0.0,
                                minHeight: 8,
                                backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
                                color: const Color(0xFF9A00FE),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
