import 'package:flutter/material.dart';
import 'study_data.dart';
import 'grammar_data.dart';
import 'sets_data.dart';
import 'kanji_challenge_data.dart';
import 'hiragana_challenge_data.dart';
import 'deck_detail.dart';
import 'study_mode.dart';
import 'mistakes_data.dart';
import 'mistakes_mode.dart';
import 'reading_tab.dart';
import 'lesson_data.dart';
import 'lesson_viewer_screen.dart';
import 'similar_kanji_screen.dart';
import 'quick_sync_button.dart';

class StudyScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const StudyScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final List<StudyDeck> _decks = [];
  bool _isLoading = true;
  // Admin-only preview toggle for the Lessons tab (see _showAdminUnlockDialog)
  // - bypasses every lesson's day-gating so every lesson can be viewed
  // regardless of challenge progress. Session-only by design, not persisted.
  bool _adminUnlockAllLessons = false;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    final decks = await loadStudyDecks();
    setState(() {
      _decks
        ..clear()
        ..addAll(decks);
      _isLoading = false;
    });
  }

  Future<void> _saveDecks() async {
    await saveStudyDecks(_decks);
  }

  void _showAddDeckDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Add Deck",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          "Would you like to use a premade deck or create a custom one?",
          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPremadeDeckPicker();
            },
            child: Text(
              "Premade",
              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9A00FE),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _showCustomDeckNameDialog();
            },
            child: const Text("Custom"),
          ),
        ],
      ),
    );
  }

  void _showCustomDeckNameDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Name Your Deck",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: "Deck name",
            hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
            filled: true,
            fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9A00FE),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              setState(() {
                _decks.add(StudyDeck(name: name));
              });
              _saveDecks();
              Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  // A 12%-alpha purple fill reads as a moody tinted card on dark mode's
  // #2A2A2A dialog background, but the exact same blend over a light-mode
  // white dialog comes out as a flat, washed-out pastel lavender - looks
  // cheap rather than "featured". Light mode instead gets only a hint of
  // tint, leaning on the solid purple border (kept in both modes) to carry
  // the "special" look instead of the fill.
  Widget _specialDeckCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF9A00FE).withValues(alpha: widget.isDarkMode ? 0.12 : 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF9A00FE)),
      ),
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF9A00FE)),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showPremadeDeckPicker() {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final query = searchController.text.trim().toLowerCase();
          final entries = setsData.entries
              .where((e) => query.isEmpty || e.value.name.toLowerCase().contains(query))
              .toList()
            ..sort((a, b) => a.value.name.compareTo(b.value.name));
          return AlertDialog(
            backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              "Choose a Premade Set",
              style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
            ),
            content: SizedBox(
              width: 320,
              height: 460,
              // A single scrollable list for everything - the special decks,
              // search field, and browsable sets - rather than a fixed
              // Column with just the sets list scrolling in whatever cramped
              // space happened to be left over underneath.
              child: ListView(
                children: [
                  _specialDeckCard(
                    icon: Icons.spa,
                    title: hiraganaChallengeDeckName,
                    subtitle:
                        '${hiraganaChallengeDays.fold<int>(0, (sum, day) => sum + day.length)} hiragana so far · new to Japanese? start here',
                    onTap: () {
                      Navigator.pop(context);
                      _createHiraganaChallengeDeck();
                    },
                  ),
                  const SizedBox(height: 8),
                  _specialDeckCard(
                    icon: Icons.local_fire_department,
                    title: kanjiChallengeDeckName,
                    subtitle:
                        '${kanjiChallengeDays.fold<int>(0, (sum, day) => sum + day.length)} kanji so far · new kanji unlock automatically each day',
                    onTap: () {
                      Navigator.pop(context);
                      _createKanjiChallengeDeck();
                    },
                  ),
                  const SizedBox(height: 8),
                  _specialDeckCard(
                    icon: Icons.menu_book,
                    title: "Essential Vocabulary Challenge",
                    subtitle: '${setsData['Essential Vocabulary']?.items.length ?? 0} words · you set how many new words per day',
                    onTap: () {
                      Navigator.pop(context);
                      _createEssentialVocabDeck();
                    },
                  ),
                  const SizedBox(height: 8),
                  _specialDeckCard(
                    icon: Icons.translate,
                    title: kGrammarDeckName,
                    subtitle: '${grammarPoints.length} grammar points · one new point each day, learned through lessons',
                    onTap: () {
                      Navigator.pop(context);
                      _createGrammarDeck();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search sets",
                      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          "No sets found",
                          style: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black45),
                        ),
                      ),
                    )
                  else
                    for (final entry in entries)
                      ListTile(
                        title: Text(entry.value.name, style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
                        subtitle: Text(
                          '${entry.value.items.length} item${entry.value.items.length == 1 ? '' : 's'} · ${entry.value.setType}',
                          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _createDeckFromSet(entry.value);
                        },
                      ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Fills in a card's fields from a dictionary entry, matching the same
  // per-type mapping used when adding a card from the dictionary search
  // (see card_edit_dialog.dart) - kana entries store their romaji in
  // `translation`, so English is set to that too (rather than left blank)
  // since every game mode expects a meaning to show.
  StudyCard _studyCardFromItem(Item item) {
    String hiragana;
    String english;
    String romaji = '';
    String cardType;
    if (item.itemType == 'Hiragana' || item.itemType == 'Katakana') {
      hiragana = item.japanese;
      romaji = item.translation;
      english = item.translation;
      cardType = 'Kana';
    } else if (item.itemType == 'Vocab') {
      hiragana = item.reading;
      english = item.translation;
      cardType = 'Vocab';
    } else {
      hiragana = item.kunYomi.isNotEmpty ? item.kunYomi : item.onYomi;
      english = item.translation;
      cardType = 'Kanji';
    }
    return StudyCard(
      japanese: item.japanese,
      hiragana: hiragana,
      romaji: romaji,
      english: english,
      kanjiVGCodes: findKanjiVGCodesForWord(item.japanese),
      cardType: cardType,
    );
  }

  Future<void> _createDeckFromSet(ItemSet set) async {
    final cards = set.items.map(_studyCardFromItem).toList();
    String name = set.name;
    int copy = 1;
    while (_decks.any((d) => d.name == name)) {
      copy++;
      name = '${set.name} ($copy)';
    }
    setState(() {
      _decks.add(StudyDeck(name: name, cards: cards));
    });
    await _saveDecks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created deck "$name" with ${cards.length} card${cards.length == 1 ? '' : 's'}')),
    );
  }

  // Same underlying deck as picking "Essential Vocabulary" from the set
  // list, except it's tagged with the Essential Vocabulary Challenge's
  // lesson track - unlike the Kanji Challenge, new words are still
  // introduced at the user's own configured daily rate (via the deck's
  // ordinary "new cards per day" setting), not a fixed per-day schedule.
  // Same underlying builder as the Kanji Challenge, but for the Hiragana
  // Challenge deck - the builder itself can't set lessonSetId (that'd need
  // it to import lesson_data.dart, which already imports it back), so it's
  // set here after the deck's built, same as _createKanjiChallengeDeck.
  // Lets someone who already did some of this challenge elsewhere (most
  // likely Anki) skip re-learning days they've covered, instead of always
  // starting fresh at Day 1 - returns the day they got to, or null to start
  // from Day 1 as normal.
  Future<int?> _promptRestoreProgress() async {
    final controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text(
          "Already done some of this challenge?",
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "If you already got partway through this on Anki (or anywhere else), enter the last day you completed. Those days will be marked as already studied instead of starting over, and the next day unlocks today.",
              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Day you got to',
                hintText: 'Leave blank to start from Day 1',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text("Start from Day 1", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE)),
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              Navigator.pop(context, (parsed != null && parsed > 0) ? parsed : null);
            },
            child: const Text("Continue", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _createHiraganaChallengeDeck() async {
    final deck = buildHiraganaChallengeDeck();
    String name = deck.name;
    int copy = 1;
    while (_decks.any((d) => d.name == name)) {
      copy++;
      name = '${deck.name} ($copy)';
    }
    deck.name = name;
    deck.lessonSetId = kHiraganaTrackId;
    setState(() {
      _decks.add(deck);
    });
    await _saveDecks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Started "$name" - day 1 hiragana are ready to study')),
    );
  }

  Future<void> _createEssentialVocabDeck() async {
    final set = setsData['Essential Vocabulary'];
    if (set == null) return;
    final cards = set.items.map(_studyCardFromItem).toList();
    String name = 'Essential Vocabulary Challenge';
    int copy = 1;
    while (_decks.any((d) => d.name == name)) {
      copy++;
      name = 'Essential Vocabulary Challenge ($copy)';
    }
    setState(() {
      _decks.add(StudyDeck(
        name: name,
        cards: cards,
        lessonSetId: kEssentialVocabTrackId,
        deckCreatedDate: todayStamp(),
      ));
    });
    await _saveDecks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Started "$name" with ${cards.length} words')),
    );
  }

  Future<void> _createGrammarDeck() async {
    String name = kGrammarDeckName;
    int copy = 1;
    while (_decks.any((d) => d.name == name)) {
      copy++;
      name = '$kGrammarDeckName ($copy)';
    }
    setState(() {
      _decks.add(StudyDeck(
        name: name,
        cards: buildGrammarCards(),
        lessonSetId: kGrammarTrackId,
        deckCreatedDate: todayStamp(),
      ));
    });
    await _saveDecks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Started "$name" - the first grammar lesson is ready')),
    );
  }

  void _showDeckOptionsMenu(StudyDeck deck) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                deck.name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Rename"),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDeckDialog(deck);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text("Duplicate"),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDuplicateDeck(deck);
                },
              ),
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text("Reset Progress"),
                onTap: () {
                  Navigator.pop(context);
                  _confirmResetDeckProgress(deck);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteDeck(deck);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDeckDialog(StudyDeck deck) {
    final controller = TextEditingController(text: deck.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Rename Deck", style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: "Deck name",
            hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
            filled: true,
            fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              setState(() => deck.name = name);
              _saveDecks();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDuplicateDeck(StudyDeck deck) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Duplicate Deck?", style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
        content: Text(
          'This will create a copy of "${deck.name}", including all its cards and progress.',
          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _duplicateDeck(deck);
            },
            child: const Text("Duplicate"),
          ),
        ],
      ),
    );
  }

  Future<void> _duplicateDeck(StudyDeck deck) async {
    final copy = duplicateDeck(deck, _decks);
    setState(() => _decks.add(copy));
    await _saveDecks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplicated as "${copy.name}"')),
    );
  }

  void _confirmResetDeckProgress(StudyDeck deck) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Reset Progress?", style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
        content: Text(
          'This marks every card in "${deck.name}" as new again${deck.challengeStartDate != null ? " and restarts its challenge schedule from day 1" : ""}. This cannot be undone.',
          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              setState(() => resetDeckProgress(deck));
              _saveDecks();
              Navigator.pop(context);
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDeck(StudyDeck deck) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Deck?", style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
        content: Text(
          'This will permanently delete "${deck.name}" and all ${deck.cards.length} card${deck.cards.length == 1 ? '' : 's'} in it. This cannot be undone.',
          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              _deleteDeck(deck);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDeck(StudyDeck deck) async {
    setState(() => _decks.remove(deck));
    await _saveDecks();
  }

  Future<void> _createKanjiChallengeDeck() async {
    final completedDay = await _promptRestoreProgress();
    if (!mounted) return;
    final deck = buildKanjiChallengeDeck();
    String name = deck.name;
    int copy = 1;
    while (_decks.any((d) => d.name == name)) {
      copy++;
      name = '${deck.name} ($copy)';
    }
    deck.name = name;
    deck.lessonSetId = kKanjiChallengeTrackId;
    if (completedDay != null) applyImportedChallengeProgress(deck, completedDay);
    setState(() {
      _decks.add(deck);
    });
    await _saveDecks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(completedDay != null
            ? 'Started "$name" - Day ${completedDay + 1} kanji are ready to study'
            : 'Started "$name" - day 1 kanji are ready to study'),
      ),
    );
  }

  // The first deck following the given lesson curriculum (see
  // lesson_data.dart), or null if the user hasn't created one yet.
  StudyDeck? _deckForTrack(String trackId) {
    for (final d in _decks) {
      if (d.lessonSetId == trackId) return d;
    }
    return null;
  }

  void _showMistakesScopeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Study Mistakes",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _scopeButton("Today", 'today'),
              _scopeButton("This Week", 'week'),
              _scopeButton("Last 100", 'last100'),
              _scopeButton("Last 250", 'last250'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scopeButton(String label, String scope) {
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
          onPressed: () {
            Navigator.pop(context);
            _openMistakesForScope(scope, label);
          },
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Future<void> _openMistakesForScope(String scope, String label) async {
    final all = await loadMistakes();
    final filtered = filterMistakes(all, scope);
    final cards = filtered.map((m) => m.toStudyCard()).toList();
    if (!mounted) return;
    showMistakesModeMenu(context, 'Mistakes - $label', cards, widget.isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        appBar: AppBar(
          title: const Text('Study'),
          backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          foregroundColor: widget.isDarkMode ? Colors.white : Colors.black87,
          elevation: 0,
          actions: [syncAppBarAction(context, widget.isDarkMode)],
          bottom: TabBar(
            indicatorColor: const Color(0xFF9A00FE),
            labelColor: const Color(0xFF9A00FE),
            unselectedLabelColor: widget.isDarkMode ? Colors.white54 : Colors.black45,
            tabs: const [
              Tab(text: "Flashcards"),
              Tab(text: "Reading & Immersion"),
              Tab(text: "Lessons"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFlashcardsTab(),
            ReadingAndImmersionTabView(isDarkMode: widget.isDarkMode),
            _buildLessonsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardsTab() {
    return SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF9A00FE)))
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9A00FE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _showAddDeckDialog,
                  child: const Text(
                    "Press to add deck",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _decks.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _decks.length) {
                          return Card(
                            color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.error_outline, color: Colors.orangeAccent),
                              title: Text(
                                "Mistakes",
                                style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                              ),
                              subtitle: Text(
                                "Review cards you've gotten wrong",
                                style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                              ),
                              onTap: _showMistakesScopeDialog,
                            ),
                          );
                        }
                        final deck = _decks[index];
                        return Card(
                          color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
                          child: ListTile(
                            title: Text(
                              deck.name,
                              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                            ),
                            subtitle: Text(
                              '${deck.cards.length} card${deck.cards.length == 1 ? '' : 's'}',
                              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                            ),
                            trailing: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF9A00FE),
                              ),
                              onPressed: () => showStudyModeMenu(context, deck, widget.isDarkMode, _saveDecks),
                              child: const Text("Study"),
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeckDetailScreen(
                                    deck: deck,
                                    isDarkMode: widget.isDarkMode,
                                    onThemeChanged: widget.onThemeChanged,
                                    onChanged: _saveDecks,
                                    onDelete: () => _deleteDeck(deck),
                                    onDuplicate: () => _duplicateDeck(deck),
                                  ),
                                ),
                              );
                              setState(() {});
                            },
                            onLongPress: () => _showDeckOptionsMenu(deck),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
    );
  }

  // Lists every authored lesson, gated by the 90 Day Challenge's current
  // day - lessons for days not yet reached appear locked and faded, since
  // they recap material the user hasn't gotten to yet.
  String _trackLabel(String trackId) {
    switch (trackId) {
      case kKanjiChallengeTrackId:
        return '90 Day Kanji Challenge';
      case kEssentialVocabTrackId:
        return 'Essential Vocabulary Challenge';
      case kHiraganaTrackId:
        return 'Kana Course';
      case kGrammarTrackId:
        return kGrammarDeckName;
      default:
        return trackId;
    }
  }

  // A single standalone entry, always unlocked regardless of challenge day -
  // unlike the day lessons below, this isn't tied to any deck's schedule,
  // just a quick way to browse every authored "easy to mix up" kanji
  // comparison at any time.
  Widget _buildSimilarKanjiCard() {
    return Card(
      color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.compare_arrows, color: Color(0xFF9A00FE)),
        title: Text(
          'Similar Kanji',
          style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
        ),
        subtitle: Text(
          '${similarKanjiGroups.length} group${similarKanjiGroups.length == 1 ? '' : 's'} of easy-to-confuse kanji',
          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SimilarKanjiListScreen(isDarkMode: widget.isDarkMode)),
        ),
      ),
    );
  }

  // Prompts for the admin password and, on a match, flips
  // _adminUnlockAllLessons so every lesson in the list below can be opened
  // and viewed regardless of challenge-day progress - for previewing
  // content, not something an ordinary user is expected to use.
  void _showAdminUnlockDialog() {
    final controller = TextEditingController();
    showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Admin Unlock",
          style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: "Password",
            hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
            filled: true,
            fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Unlock"),
          ),
        ],
      ),
    ).then((value) {
      if (value == null || !mounted) return;
      if (value == 'thekanjiathleteboss') {
        setState(() => _adminUnlockAllLessons = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All lessons unlocked for viewing.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect password.')),
        );
      }
    });
  }

  List<Lesson> get _allLessons => [...lessons, ...grammarLessons];

  // Lessons are grouped by course, in this order. Within a course they run in
  // the order they happen - an end-of-day lesson sits after its day's cards.
  List<Widget> _lessonSectionWidgets() {
    const sections = [
      MapEntry(kHiraganaTrackId, 'Kana Course'),
      MapEntry(kKanjiChallengeTrackId, '90 Day Kanji Challenge'),
      MapEntry(kEssentialVocabTrackId, 'Vocabulary'),
      MapEntry(kGrammarTrackId, kGrammarDeckName),
    ];
    double sortKey(Lesson l) => l.endOfDay != null ? l.endOfDay! + 0.5 : l.day.toDouble();
    final widgets = <Widget>[];
    for (final section in sections) {
      final sectionLessons = _allLessons.where((l) => l.trackId == section.key).toList()
        ..sort((a, b) => sortKey(a).compareTo(sortKey(b)));
      if (sectionLessons.isEmpty) continue;
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(
          section.value,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
      widgets.addAll(sectionLessons.map(_buildLessonCard));
    }
    return widgets;
  }

  Widget _buildLessonCard(Lesson lesson) {
    final deck = _deckForTrack(lesson.trackId);
    final currentDay = deck == null ? 0 : lessonDayFor(deck);
    final completed = deck?.completedLessonDays.contains(lesson.day) ?? false;
    // A lesson already completed - e.g. by pulling its day in early from a
    // Spaced Repetition session - is unlocked regardless of what the
    // calendar day says. An admin who's unlocked everything can also open
    // any lesson regardless of progress, purely for viewing/previewing it.
    // For an end-of-day lesson (see Lesson.endOfDay), it's really "day
    // endOfDay + 1" that unlocks it, matching when it actually auto-triggers
    // mid-session - falling back to the ordinary day check would otherwise
    // show it as still locked here even after it's already been shown.
    final unlockDay = lesson.endOfDay != null ? lesson.endOfDay! + 1 : lesson.day;
    final unlocked = _adminUnlockAllLessons || unlockDay <= currentDay || completed;
    return Opacity(
      opacity: unlocked ? 1.0 : 0.4,
      child: Card(
        color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Icon(
            unlocked ? (completed ? Icons.check_circle : Icons.menu_book) : Icons.lock,
            color: unlocked ? const Color(0xFF9A00FE) : (widget.isDarkMode ? Colors.white38 : Colors.black38),
          ),
          title: Text(
            lesson.endOfDay != null ? 'End of Day ${lesson.endOfDay}: ${lesson.title}' : 'Day ${lesson.day}: ${lesson.title}',
            style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
          ),
          subtitle: Text(
            unlocked
                ? (completed
                    ? 'Completed'
                    : lesson.activityBuilder == null
                        ? '${lesson.steps.length} interactive steps'
                        : lesson.steps.isEmpty
                            ? 'A creative activity'
                            : '${lesson.steps.length} interactive steps + activity')
                : lesson.endOfDay != null
                    ? '${_trackLabel(lesson.trackId)} · unlocks at the end of day ${lesson.endOfDay}'
                    : '${_trackLabel(lesson.trackId)} · unlocks on day ${lesson.day}',
            style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
          ),
          onTap: unlocked
              ? () async {
                  final done = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LessonViewerScreen(
                        deck: _deckForTrack(lesson.trackId),
                        onChanged: () => _saveDecks(),
                        lesson: lesson,
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                  );
                  if (done == true && deck != null && !deck.completedLessonDays.contains(lesson.day)) {
                    setState(() => deck.completedLessonDays.add(lesson.day));
                    await _saveDecks();
                  }
                }
              : null,
        ),
      ),
    );
  }

  Widget _buildLessonsTab() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!_adminUnlockAllLessons)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _showAdminUnlockDialog,
                icon: const Icon(Icons.lock_open, size: 16),
                label: const Text("Unlock All"),
                style: TextButton.styleFrom(foregroundColor: widget.isDarkMode ? Colors.white38 : Colors.black38),
              ),
            ),
          if (similarKanjiGroups.isNotEmpty) ...[
            _buildSimilarKanjiCard(),
            const SizedBox(height: 4),
          ],
          if (_allLessons.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                "No day lessons yet - start the Hiragana Challenge, the 90 Day Kanji Challenge, or the Essential Vocabulary Challenge to unlock Day 1.",
                textAlign: TextAlign.center,
                style: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black45),
              ),
            )
          else
            ..._lessonSectionWidgets(),
        ],
      ),
    );
  }
}
