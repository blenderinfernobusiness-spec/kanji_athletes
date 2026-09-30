import 'package:flutter/material.dart';
import 'kanji_challenge_data.dart' show SimilarKanji, similarKanjiGroups;

const _kPurple = Color(0xFF9A00FE);

// The single "Similar Kanji" entry in Study → Lessons opens this - a list of
// every authored comparison group in one place, each tappable into its own
// SimilarKanjiScreen. Always unlocked, unlike the day lessons below it,
// since it isn't tied to any deck's schedule.
class SimilarKanjiListScreen extends StatelessWidget {
  final bool isDarkMode;

  const SimilarKanjiListScreen({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: const Text('Similar Kanji'),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: similarKanjiGroups.length,
          itemBuilder: (context, index) {
            final group = similarKanjiGroups[index];
            return Card(
              color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.compare_arrows, color: _kPurple),
                title: Text(
                  group.members.map((m) => m.japanese).join('　·　'),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                ),
                subtitle: Text(
                  group.members.map((m) => m.english).join(' · '),
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SimilarKanjiScreen(members: group.members, isDarkMode: isDarkMode)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// A side-by-side comparison of a group of kanji that are easy to visually
// confuse with each other (see kanji_challenge_data.dart's
// similarKanjiGroups). Used two ways:
//  - Pushed right after KanjiIntroScreen for a brand-new card whose kanji is
//    part of a group, with [highlight] set to that card's own kanji so it
//    stands out from the others it's being compared against. Always shown
//    non-redacted in that context: the whole point is comparing shapes, so
//    there's no way to show it without giving the shape away - callers only
//    push it once the card's answer is already known.
//  - Browsed directly from Study → Lessons' standalone "Similar Kanji"
//    section, with [highlight] left null, showing every member of the group
//    as plain reference material rather than "the new one vs. the rest".
class SimilarKanjiScreen extends StatelessWidget {
  final List<SimilarKanji> members;
  final String? highlight;
  final bool isDarkMode;

  const SimilarKanjiScreen({super.key, required this.members, this.highlight, required this.isDarkMode});

  Widget _kanjiTile(bool isDarkMode, String kanji, String english, {required bool isTarget}) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: isTarget ? _kPurple.withValues(alpha: isDarkMode ? 0.25 : 0.12) : (isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100]),
        borderRadius: BorderRadius.circular(16),
        border: isTarget ? Border.all(color: _kPurple, width: 2) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(kanji, style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text(
            english,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white70 : Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final intro = highlight != null
        ? '$highlight looks a lot like ${members.length > 2 ? "these kanji" : "this kanji"} - take a moment to compare them.'
        : "These kanji are easy to mix up - take a moment to compare them.";
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: const Text('Similar Kanji'),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Text(intro, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: isDarkMode ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final m in members) _kanjiTile(isDarkMode, m.japanese, m.english, isTarget: m.japanese == highlight),
                ],
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
