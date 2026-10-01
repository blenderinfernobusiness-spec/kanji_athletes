import 'package:flutter/material.dart';
import 'study_data.dart';
import 'card_edit_dialog.dart';
import 'study_settings.dart';
import 'audio_service.dart';
import 'writing_practice_canvas.dart';
import 'user_profile.dart';
import 'mistakes_data.dart';
import 'lesson_data.dart';
import 'lesson_viewer_screen.dart';
import 'kanji_intro_screen.dart';
import 'vocab_intro_screen.dart';
import 'kana_intro_screen.dart';
import 'kana_comparison_screen.dart';
import 'hiragana_vocab_explainer_screen.dart';
import 'hiragana_challenge_data.dart' show hiraganaEquivalentOf;
import 'answer_flashcards_intro_screen.dart';
import 'similar_kanji_screen.dart';
import 'kanji_challenge_data.dart' show similarKanjiFor, SimilarKanji;
import 'tatoeba_service.dart';

// XP awarded per correct answer, matching the arcade modes' per-item reward.
const int _xpPerCorrectAnswer = 10;

class SpacedRepetitionStandardScreen extends StatefulWidget {
  final StudyDeck deck;
  final bool isDarkMode;
  final VoidCallback onChanged;

  const SpacedRepetitionStandardScreen({
    super.key,
    required this.deck,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  State<SpacedRepetitionStandardScreen> createState() => _SpacedRepetitionStandardScreenState();
}

// Snapshot of a card's spaced-repetition state before a review, so the last
// answer can be undone.
class _UndoEntry {
  final int index;
  final int repetitions;
  final double easeFactor;
  final int intervalDays;
  final String? nextReviewDate;
  final int progress;
  final bool wasCorrect;

  _UndoEntry({
    required this.index,
    required this.repetitions,
    required this.easeFactor,
    required this.intervalDays,
    required this.nextReviewDate,
    required this.progress,
    required this.wasCorrect,
  });
}

// A single graded card, kept for the end-of-session summary.
class _ReviewResult {
  final StudyCard card;
  final bool correct;
  _ReviewResult(this.card, this.correct);
}

class _SpacedRepetitionStandardScreenState extends State<SpacedRepetitionStandardScreen> {
  List<StudyCard> _queue = [];
  int _index = 0;
  int _correctCount = 0;
  StudySettings _settings = StudySettings();
  _UndoEntry? _lastUndo;
  final List<_ReviewResult> _results = [];
  bool _endedEarly = false;
  // How many challenge days beyond the currently-unlocked one the user has
  // chosen to pull in early this session (see _buildContinuePrompt).
  int _extraChallengeDaysUnlocked = 0;

  UserProfile? _userProfile;
  int _levelAtStart = 0;
  int _xpAtStart = 0;
  int _xpEarnedThisSession = 0;

  List<Map<String, dynamic>> _englishVoices = [];
  List<Map<String, dynamic>> _japaneseVoices = [];

  // Per-attempt state, reset whenever the current card changes or is flipped.
  bool _showAnswer = false; // basic mode's reveal gate
  bool _typeMismatched = false; // type mode: typed answer didn't match, needs manual grading
  bool _drawAnswerRevealed = false; // draw mode: stroke order has been shown, ready to grade
  bool _memoryTechniqueRevealed = false; // whether the memory technique panel is shown
  int _drawResetCounter = 0; // bumped to clear the drawing canvas for a new card
  final TextEditingController _typeController = TextEditingController();

  // Cards a kanji intro screen has already been shown for this session, so
  // it's never shown twice for the same still-new card (e.g. if the queue
  // is rebuilt/appended to without the card actually changing).
  final Set<StudyCard> _introShownFor = {};
  // Example words already queued for a background Tatoeba fetch, so the
  // same word's sentences aren't requested twice.
  final Set<String> _prefetchedExampleWords = {};

  @override
  void initState() {
    super.initState();
    _buildQueue();
    _prefetchUpcomingCardSentences();
    _loadSettings();
    _loadProfile();
    _loadVoices();
  }

  // Warms the Tatoeba example-sentence cache (see tatoeba_service.dart,
  // which persists results to disk) for every upcoming brand-new
  // Kanji/Vocab card - a kanji card's example words for KanjiIntroScreen, or
  // a vocab card's own word for VocabIntroScreen - so by the time the user
  // actually reaches one of them, that screen's own fetch is an instant
  // cache hit instead of a fresh network round-trip. Fire-and-forget - runs
  // quietly in the background while the user works through other cards.
  void _prefetchUpcomingCardSentences() {
    for (final card in _queue) {
      if (card.nextReviewDate != null) continue;
      if (card.cardType == 'Kanji') {
        for (final word in exampleWordsContaining(card.japanese, limit: 2)) {
          if (!_prefetchedExampleWords.add(word.japanese)) continue;
          getTatoebaSentencesFor(word.japanese);
        }
      } else if (card.cardType == 'Vocab') {
        if (!_prefetchedExampleWords.add(card.japanese)) continue;
        getTatoebaSentencesFor(card.japanese);
      }
    }
  }

  // Due cards split into reviews (already studied at least once) and new
  // (never studied) - reviews are never capped. New cards are either capped
  // by the deck's flat newCardsPerDay setting (tracked per calendar day, so
  // re-opening the session later the same day doesn't hand out more of
  // them), or, for a day-scheduled challenge deck, gated by each card's own
  // challengeDay against how many days have elapsed since the deck started.
  void _buildQueue() {
    final deck = widget.deck;
    final due = deck.cards.where(isCardDue).toList();
    final reviews = due.where((c) => c.nextReviewDate != null).toList();
    final newCards = due.where((c) => c.nextReviewDate == null).toList();

    List<StudyCard> newCardsForSession;
    if (deck.challengeStartDate != null) {
      final currentDay = _currentChallengeDay();
      newCardsForSession = newCards.where((c) => (c.challengeDay ?? 1) <= currentDay).toList();
    } else {
      final today = todayStamp();
      if (deck.newCardsIntroducedDate != today) {
        deck.newCardsIntroducedDate = today;
        deck.newCardsIntroducedToday = 0;
        widget.onChanged();
      }
      final newAllowed = (deck.newCardsPerDay - deck.newCardsIntroducedToday).clamp(0, newCards.length);
      newCardsForSession = newCards.take(newAllowed).toList();
    }
    _queue = [...reviews, ...newCardsForSession];
  }

  // How many days into a challenge deck's schedule today is (day 1 = the
  // day the deck was created).
  int _currentChallengeDay() {
    final start = DateTime.parse(widget.deck.challengeStartDate!);
    return DateTime.now().difference(start).inDays + 1;
  }

  // Every not-yet-studied card that isn't already in the session's queue -
  // for offering "keep going" on the summary screen once the queue runs out.
  List<StudyCard> _unqueuedNewCards() {
    final queued = _queue.toSet();
    return widget.deck.cards.where((c) => c.nextReviewDate == null && !queued.contains(c)).toList();
  }

  // The next challenge day beyond what's currently unlocked (including any
  // already pulled in early this session) that actually has unstudied cards
  // waiting, or null if there's nothing further to offer.
  int? _nextEarlyChallengeDay() {
    final nextDay = _currentChallengeDay() + 1 + _extraChallengeDaysUnlocked;
    final hasCards = widget.deck.cards.any((c) => c.challengeDay == nextDay && c.nextReviewDate == null);
    return hasCards ? nextDay : null;
  }

  void _continueWithMoreCards() {
    final more = _unqueuedNewCards();
    final count = more.length < widget.deck.newCardsPerDay ? more.length : widget.deck.newCardsPerDay;
    if (count <= 0) return;
    setState(() => _queue = [..._queue, ...more.take(count)]);
    _afterAdvancingToNewCard();
  }

  // Pulling in a day early skips the normal Spaced Repetition entry point
  // (study_mode.dart's _startSpacedRepetition), which is the only other
  // place that day's lesson recap would have been shown - so gate it here
  // too, the same way: show the lesson first (if it exists and hasn't been
  // completed yet), and only pull in the day's cards once it's done.
  Future<void> _continueWithChallengeDay(int day) async {
    final lesson = lessonForTrackAndDay(widget.deck.lessonSetId ?? kKanjiChallengeTrackId, day);
    if (lesson != null && !widget.deck.completedLessonDays.contains(day)) {
      final completed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => LessonViewerScreen(lesson: lesson, isDarkMode: widget.isDarkMode)),
      );
      if (completed != true || !mounted) return;
      widget.deck.completedLessonDays.add(day);
      widget.onChanged();
    }
    final unlocked = widget.deck.cards.where((c) => c.challengeDay == day && c.nextReviewDate == null).toList();
    setState(() {
      _queue = [..._queue, ...unlocked];
      _extraChallengeDaysUnlocked++;
    });
    await _afterAdvancingToNewCard();
  }

  Future<void> _loadVoices() async {
    final english = await AudioService().voicesForLanguage('English');
    final japanese = await AudioService().voicesForLanguage('Japanese');
    if (!mounted) return;
    setState(() {
      _englishVoices = english;
      _japaneseVoices = japanese;
    });
  }

  @override
  void dispose() {
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await UserProfile.load();
    if (!mounted) return;
    setState(() {
      _userProfile = profile;
      _levelAtStart = profile.level;
      _xpAtStart = profile.xp;
    });
  }

  Future<void> _loadSettings() async {
    final settings = await loadStudySettings();
    if (!mounted) return;
    setState(() => _settings = settings);
    _afterAdvancingToNewCard();
  }

  // Speaks the hiragana field, falling back to the base Japanese field
  // only when no hiragana has been entered.
  String _japaneseText(StudyCard card) => card.hiragana.isNotEmpty ? card.hiragana : card.japanese;

  // A card set to draw mode falls back to basic behaviour if it has no
  // stroke data to draw against.
  String _effectiveMode(StudyCard card) =>
      (card.answerMode == 'draw' && card.kanjiVGCodes.isEmpty) ? 'basic' : card.answerMode;

  // Whether the current attempt has already revealed the answer, across
  // every answer mode - the same condition _buildCard uses to decide
  // whether to show the grading buttons.
  bool _isAnswerRevealed(String mode) =>
      (mode == 'basic' && _showAnswer) || (mode == 'draw' && _drawAnswerRevealed) || (mode == 'type' && _typeMismatched);

  // Opens the same context screen shown automatically for a brand-new card
  // (see _maybeShowCardIntroBatch), available any time via the app bar's
  // info button. Before the answer's been revealed this opens in redacted
  // mode - the whole point of "about this card" is extra context, not a way
  // to peek at what you're being tested on.
  Future<void> _showCardInfo(StudyCard card) async {
    final redacted = !_isAnswerRevealed(_effectiveMode(card));
    final Widget introScreen = card.cardType == 'Kanji'
        ? KanjiIntroScreen(card: card, isDarkMode: widget.isDarkMode, redacted: redacted)
        : VocabIntroScreen(card: card, isDarkMode: widget.isDarkMode, redacted: redacted);
    await Navigator.push(context, MaterialPageRoute(builder: (context) => introScreen));
    if (!mounted || redacted || card.cardType != 'Kanji') return;
    final similar = similarKanjiFor(card.japanese);
    if (similar == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimilarKanjiScreen(
          members: [SimilarKanji(card.japanese, card.english), ...similar],
          highlight: card.japanese,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }

  void _autoReadFront() {
    if (_index >= _queue.length) return;
    final card = _queue[_index];
    // A Kana card's front shows its romaji, not the character itself, so
    // it's prompted by sound rather than shape - but the sound it should be
    // heard in is Japanese, not an English voice reading the romaji letters.
    if (card.cardType == 'Kana') {
      if (_settings.autoReadJapanese) {
        AudioService().speak(_japaneseText(card), 'Japanese', rate: _settings.japaneseSpeed, voiceName: _settings.japaneseVoiceName);
      }
      return;
    }
    if (card.englishFirst) {
      if (_settings.autoReadEnglish) {
        AudioService().speak(card.english, 'English', rate: _settings.englishSpeed, voiceName: _settings.englishVoiceName);
      }
    } else {
      if (_settings.autoReadJapanese) {
        AudioService().speak(_japaneseText(card), 'Japanese', rate: _settings.japaneseSpeed, voiceName: _settings.japaneseVoiceName);
      }
    }
  }

  // Whenever the queue reaches a stretch of brand-new (never-reviewed)
  // Kanji/Vocab/Kana cards that haven't had their context screen shown yet,
  // this shows them back to back before returning control to the drill -
  // rather than interrupting after every single new card, it introduces a
  // batch up front, then lets the user work through that batch uninterrupted
  // (each card is marked shown as part of the batch, so the per-advance
  // check that calls this just no-ops for the rest of it).
  //
  // Kanji/Vocab batches are capped at 4 at a time (so a big day's worth of
  // new cards doesn't dump dozens of intro screens on you at once); a
  // Hiragana Challenge kana batch is never capped, since it's always a whole
  // row of characters (5, or 3 for a short one) that's meant to be
  // introduced as a single unit - see hiragana_challenge_data.dart.
  static const int _introBatchSize = 4;

  Future<void> _maybeShowCardIntroBatch() async {
    if (_index >= _queue.length) return;
    final first = _queue[_index];
    // Nothing new to introduce right now: either this card's already been
    // reviewed, its intro already ran (it's simply mid-drill within an
    // already-introduced batch), or it's not a type that gets one at all.
    // Critically, this must be a `return`, not a signal to keep scanning
    // forward - looking past an already-introduced-but-not-yet-drilled card
    // into a later, not-yet-reached batch would show that later batch's
    // intros before the current one has even been drilled.
    if (first.nextReviewDate != null) return;
    if (_introShownFor.contains(first)) return;
    if (first.cardType != 'Kanji' && first.cardType != 'Vocab' && first.cardType != 'Kana') return;

    final batch = <StudyCard>[];
    final capped = first.cardType != 'Kana';
    for (var i = _index; i < _queue.length; i++) {
      final card = _queue[i];
      if (card.nextReviewDate != null) break; // reached already-reviewed cards
      if (_introShownFor.contains(card)) break; // reached the next, later batch
      if (card.cardType != first.cardType) break; // never mix types within one batch
      batch.add(card);
      if (capped && batch.length >= _introBatchSize) break;
    }
    if (batch.isEmpty) return;
    for (final card in batch) {
      _introShownFor.add(card);
    }

    // The very first time a Hiragana Challenge session reaches its first
    // batch of example-word cards, explain how they work right then -
    // rather than back in the Day 1 lesson, before any hiragana had even
    // been introduced. Gated on no Vocab card in the deck having been
    // reviewed yet, so this only ever fires once across the deck's whole
    // lifetime, not on every subsequent day's vocab batch.
    if (batch.first.cardType == 'Vocab' &&
        widget.deck.lessonSetId == kHiraganaTrackId &&
        !widget.deck.cards.any((c) => c.cardType == 'Vocab' && c.nextReviewDate != null)) {
      if (!mounted) return;
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => HiraganaVocabExplainerScreen(isDarkMode: widget.isDarkMode),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      if (!mounted) return;
    }

    for (var i = 0; i < batch.length; i++) {
      if (!mounted) return;
      final card = batch[i];
      final Widget introScreen = card.cardType == 'Kanji'
          ? KanjiIntroScreen(card: card, isDarkMode: widget.isDarkMode, batchPosition: i + 1, batchTotal: batch.length)
          : card.cardType == 'Vocab'
              ? VocabIntroScreen(card: card, isDarkMode: widget.isDarkMode, batchPosition: i + 1, batchTotal: batch.length)
              : KanaIntroScreen(card: card, isDarkMode: widget.isDarkMode, batchPosition: i + 1, batchTotal: batch.length);
      // A null result means "continue" (back arrow, swipe-back, or system
      // back all count as moving to the next card's intro, matching how
      // this batch has always worked); the close ("X") button instead pops
      // with `true`, which breaks out of the whole batch early rather than
      // just advancing to the next card.
      final closed = await Navigator.push<bool>(
        context,
        // No transition animation: the first push happens right after the
        // SRS screen's own setState repaints for the just-advanced-to card,
        // so an animated push would leave that repaint (or the previous
        // card's revealed-answer state) briefly visible underneath the
        // slide-in; later pushes in the same batch would otherwise flash
        // the prior intro screen mid-pop. Popping instantly the same way.
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => introScreen,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      if (!mounted) return;
      if (closed == true) return;
      // A handful of kanji are commonly confused with another similar-
      // looking one - when that's authored, show a quick side-by-side
      // comparison right on top of this card's own intro, same zero-
      // duration push so it doesn't flash the batch screen underneath it.
      final similar = card.cardType == 'Kanji' ? similarKanjiFor(card.japanese) : null;
      if (similar != null) {
        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => SimilarKanjiScreen(
              members: [SimilarKanji(card.japanese, card.english), ...similar],
              highlight: card.japanese,
              isDarkMode: widget.isDarkMode,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        if (!mounted) return;
      }
      // A katakana character gets a quick "same sound, different script"
      // comparison against the hiragana it's already known for, right on
      // top of its own intro - same zero-duration push so it doesn't flash
      // the batch screen underneath it.
      final hiraganaEquivalent = card.cardType == 'Kana' ? hiraganaEquivalentOf(card.japanese) : null;
      if (hiraganaEquivalent != null) {
        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => KanaComparisonScreen(
              katakana: card.japanese,
              hiragana: hiraganaEquivalent,
              isDarkMode: widget.isDarkMode,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        if (!mounted) return;
      }
    }
  }

  // Every place that changes which card is "current" (advancing after a
  // grade, undoing back to one, or appending newly-unlocked cards) should
  // run through this instead of calling _autoReadFront() directly, so the
  // card intro gets its chance to show first.
  Future<void> _afterAdvancingToNewCard() async {
    await _maybeShowCardIntroBatch();
    if (!mounted) return;
    await _maybeShowAnswerIntro();
    if (!mounted) return;
    _prefetchUpcomingCardSentences();
    _autoReadFront();
  }

  // The first time this deck is ever studied - special decks and ordinary
  // custom ones alike - explain how to actually answer a card (reveal-and-
  // grade, draw, or type, based on the very first card's own answer mode)
  // right before that first card is drilled, once its context slide (if
  // any) has already had its turn.
  Future<void> _maybeShowAnswerIntro() async {
    if (widget.deck.hasShownAnswerIntro) return;
    if (_index >= _queue.length) return;
    widget.deck.hasShownAnswerIntro = true;
    widget.onChanged();
    final mode = _effectiveMode(_queue[_index]);
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AnswerFlashcardsIntroScreen(mode: mode, isDarkMode: widget.isDarkMode),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _autoReadBack() {
    if (_index >= _queue.length) return;
    final card = _queue[_index];
    if (card.englishFirst) {
      if (_settings.autoReadJapanese) {
        AudioService().speak(_japaneseText(card), 'Japanese', rate: _settings.japaneseSpeed, voiceName: _settings.japaneseVoiceName);
      }
    } else {
      if (_settings.autoReadEnglish) {
        AudioService().speak(card.english, 'English', rate: _settings.englishSpeed, voiceName: _settings.englishVoiceName);
      }
    }
  }

  void _resetAttemptState() {
    _showAnswer = false;
    _typeMismatched = false;
    _drawAnswerRevealed = false;
    _memoryTechniqueRevealed = false;
    _typeController.clear();
    _drawResetCounter++;
  }

  void _editMemoryTechnique(StudyCard card) {
    final controller = TextEditingController(text: card.memoryTechnique);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Memory Technique",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: "e.g. a mnemonic or memory aid",
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
              setState(() => card.memoryTechnique = controller.text.trim());
              widget.onChanged();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _memoryTechniqueSection(StudyCard card, bool isDarkMode) {
    if (!_memoryTechniqueRevealed) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextButton.icon(
          onPressed: () => setState(() => _memoryTechniqueRevealed = true),
          icon: const Icon(Icons.psychology, color: Color(0xFF9A00FE)),
          label: const Text("Memory Technique", style: TextStyle(color: Color(0xFF9A00FE))),
        ),
      );
    }
    final imageAsset = card.memoryImageAsset ?? '';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageAsset.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(imageAsset, fit: BoxFit.contain),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    card.memoryTechnique.isEmpty ? "No memory technique added yet." : card.memoryTechnique,
                    style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Color(0xFF9A00FE)),
                  tooltip: 'Edit memory technique',
                  onPressed: () => _editMemoryTechnique(card),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _revealDrawAnswer(StudyCard card, bool isDarkMode) {
    setState(() => _drawAnswerRevealed = true);
  }

  void _answer(bool correct) {
    final card = _queue[_index];
    final finishedDay = card.challengeDay;
    final wasNew = card.nextReviewDate == null;
    _lastUndo = _UndoEntry(
      index: _index,
      repetitions: card.repetitions,
      easeFactor: card.easeFactor,
      intervalDays: card.intervalDays,
      nextReviewDate: card.nextReviewDate,
      progress: card.progress,
      wasCorrect: correct,
    );
    recordReview(card, correct);
    if (wasNew) widget.deck.newCardsIntroducedToday++;
    widget.onChanged();
    _results.add(_ReviewResult(card, correct));
    if (correct) {
      _correctCount++;
      _xpEarnedThisSession += _xpPerCorrectAnswer;
      _userProfile?.addXp(_xpPerCorrectAnswer);
      _userProfile?.save();
    } else {
      logMistake(card, widget.deck.name);
    }
    setState(() {
      _index++;
      _resetAttemptState();
    });
    _afterFinishingCard(finishedDay);
  }

  // Whether every card belonging to challenge day [day] has now been
  // reviewed at least once - the signal that day is genuinely "done",
  // independent of where in the queue this card happened to sit (a user who
  // falls behind a day can have a later day's cards already queued up right
  // behind an earlier day's last card).
  bool _dayFullyReviewed(int day) {
    final dayCards = widget.deck.cards.where((c) => c.challengeDay == day);
    return dayCards.isNotEmpty && dayCards.every((c) => c.nextReviewDate != null);
  }

  // The moment a challenge day's cards are all reviewed for the first time,
  // show that day's capstone lesson (if one's authored) right then - before
  // whatever comes next, whether that's the session summary screen or
  // (falling behind a day) cards from a day already unlocked past it.
  Future<void> _maybeShowEndOfDayLesson(int day) async {
    final trackId = widget.deck.lessonSetId;
    if (trackId == null) return;
    // More than one lesson can share the same endOfDay - e.g. a day that
    // wraps up one topic (a self-introduction recap) and also kicks off a
    // new one (introducing katakana) gets both, shown back to back in the
    // order they're authored in.
    for (final lesson in lessons) {
      if (lesson.trackId != trackId || lesson.endOfDay != day) continue;
      if (widget.deck.completedLessonDays.contains(lesson.day)) continue;
      if (!mounted) return;
      final done = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => LessonViewerScreen(lesson: lesson, isDarkMode: widget.isDarkMode)),
      );
      if (done == true && mounted) {
        widget.deck.completedLessonDays.add(lesson.day);
        widget.onChanged();
      }
      if (!mounted) return;
    }
  }

  Future<void> _afterFinishingCard(int? finishedDay) async {
    if (finishedDay != null && _dayFullyReviewed(finishedDay)) {
      await _maybeShowEndOfDayLesson(finishedDay);
      if (!mounted) return;
    }
    await _afterAdvancingToNewCard();
  }

  // Reverts the most recent answer's spaced-repetition update and goes back
  // to that card. Only one level deep - answering again clears it.
  void _undo() {
    final undo = _lastUndo;
    if (undo == null) return;
    final card = _queue[undo.index];
    final wasNewBeforeAnswer = undo.nextReviewDate == null;
    card.repetitions = undo.repetitions;
    card.easeFactor = undo.easeFactor;
    card.intervalDays = undo.intervalDays;
    card.nextReviewDate = undo.nextReviewDate;
    card.progress = undo.progress;
    if (wasNewBeforeAnswer && widget.deck.newCardsIntroducedToday > 0) {
      widget.deck.newCardsIntroducedToday--;
    }
    if (undo.wasCorrect) {
      _correctCount--;
      _xpEarnedThisSession -= _xpPerCorrectAnswer;
      _userProfile?.removeXp(_xpPerCorrectAnswer);
      _userProfile?.save();
    } else {
      removeLastMistake();
    }
    if (_results.isNotEmpty) _results.removeLast();
    widget.onChanged();
    setState(() {
      _index = undo.index;
      _lastUndo = null;
      _resetAttemptState();
    });
    _afterAdvancingToNewCard();
  }

  void _flipCurrentCard() {
    final card = _queue[_index];
    card.englishFirst = !card.englishFirst;
    widget.onChanged();
    setState(() => _resetAttemptState());
    _autoReadFront();
  }

  void _confirmEndSession() {
    final studied = _results.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "End session?",
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
        ),
        content: Text(
          "You've studied $studied card${studied == 1 ? '' : 's'} so far. See your summary now?",
          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Keep studying",
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
              setState(() => _endedEarly = true);
            },
            child: const Text("End"),
          ),
        ],
      ),
    );
  }

  void _showAnswerNow() {
    setState(() => _showAnswer = true);
    _autoReadBack();
  }

  // Type mode: exact match (trimmed, case-insensitive) against whichever
  // side isn't the prompt auto-marks correct; anything else falls back to
  // a manual reveal-and-grade, same as basic mode.
  bool _isTypedAnswerCorrect(StudyCard card, String typed) {
    final t = typed.trim().toLowerCase();
    if (t.isEmpty) return false;
    if (card.englishFirst) {
      return t == card.hiragana.trim().toLowerCase() || t == card.japanese.trim().toLowerCase();
    }
    return t == card.english.trim().toLowerCase();
  }

  void _submitTypedAnswer() {
    final card = _queue[_index];
    if (_isTypedAnswerCorrect(card, _typeController.text)) {
      _answer(true);
    } else {
      setState(() => _typeMismatched = true);
      _autoReadBack();
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Study Settings",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: const Color(0xFF9A00FE),
                  title: Text(
                    "Enable Romaji",
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                  ),
                  value: _settings.enableRomaji,
                  onChanged: (value) {
                    setDialogState(() => _settings.enableRomaji = value);
                    setState(() {});
                    saveStudySettings(_settings);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: const Color(0xFF9A00FE),
                  title: Text(
                    "Auto-read English",
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                  ),
                  value: _settings.autoReadEnglish,
                  onChanged: (value) {
                    setDialogState(() => _settings.autoReadEnglish = value);
                    setState(() {});
                    saveStudySettings(_settings);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: const Color(0xFF9A00FE),
                  title: Text(
                    "Auto-read Japanese",
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                  ),
                  value: _settings.autoReadJapanese,
                  onChanged: (value) {
                    setDialogState(() => _settings.autoReadJapanese = value);
                    setState(() {});
                    saveStudySettings(_settings);
                  },
                ),
                const SizedBox(height: 8),
                _speedSlider(
                  label: "English speed",
                  value: _settings.englishSpeed,
                  isDarkMode: widget.isDarkMode,
                  onChanged: (value) {
                    setDialogState(() => _settings.englishSpeed = value);
                    setState(() {});
                    saveStudySettings(_settings);
                  },
                ),
                _speedSlider(
                  label: "Japanese speed",
                  value: _settings.japaneseSpeed,
                  isDarkMode: widget.isDarkMode,
                  onChanged: (value) {
                    setDialogState(() => _settings.japaneseSpeed = value);
                    setState(() {});
                    saveStudySettings(_settings);
                  },
                ),
                const SizedBox(height: 16),
                _voicePicker(
                  label: "English voice",
                  voices: _englishVoices,
                  selected: _settings.englishVoiceName,
                  isDarkMode: widget.isDarkMode,
                  onChanged: (value) {
                    setDialogState(() => _settings.englishVoiceName = value);
                    setState(() {});
                    saveStudySettings(_settings);
                  },
                ),
                const SizedBox(height: 12),
                _voicePicker(
                  label: "Japanese voice",
                  voices: _japaneseVoices,
                  selected: _settings.japaneseVoiceName,
                  isDarkMode: widget.isDarkMode,
                  onChanged: (value) {
                    setDialogState(() => _settings.japaneseVoiceName = value);
                    setState(() {});
                    saveStudySettings(_settings);
                  },
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A00FE),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Done"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _voicePicker({
    required String label,
    required List<Map<String, dynamic>> voices,
    required String? selected,
    required bool isDarkMode,
    required ValueChanged<String?> onChanged,
  }) {
    if (voices.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "$label: none installed on this device",
          style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black45, fontStyle: FontStyle.italic),
        ),
      );
    }
    // If the previously chosen voice is no longer installed, fall back to
    // "Default" instead of crashing the dropdown on an unmatched value.
    final validSelected = voices.any((v) => v['name'] == selected) ? selected : null;
    return DropdownButtonFormField<String?>(
      initialValue: validSelected,
      dropdownColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text("Default")),
        ...voices.map((v) => DropdownMenuItem<String?>(
              value: v['name'].toString(),
              child: Text(v['name'].toString(), overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: onChanged,
    );
  }

  Widget _speedSlider({
    required String label,
    required double value,
    required bool isDarkMode,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${value.toStringAsFixed(2)}x',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        Slider(
          value: value,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          activeColor: const Color(0xFF9A00FE),
          label: '${value.toStringAsFixed(2)}x',
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _audioButton(String text, String language) {
    return IconButton(
      icon: const Icon(Icons.volume_up),
      color: const Color(0xFF9A00FE),
      tooltip: 'Play audio',
      onPressed: () async {
        final isEnglish = language == 'English';
        final ok = await AudioService().speak(
          text,
          language,
          rate: isEnglish ? _settings.englishSpeed : _settings.japaneseSpeed,
          voiceName: isEnglish ? _settings.englishVoiceName : _settings.japaneseVoiceName,
        );
        if (!ok && mounted) {
          showMissingVoiceSnackBar(context, widget.isDarkMode, language);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final hasCurrentCard = _queue.isNotEmpty && _index < _queue.length;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: Text('${widget.deck.name} - Spaced Repetition'),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo last answer',
            onPressed: _lastUndo == null ? null : _undo,
          ),
          if (hasCurrentCard) ...[
            IconButton(
              icon: const Icon(Icons.flag),
              tooltip: 'End session',
              onPressed: _confirmEndSession,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit card',
              onPressed: () => showEditCardDialog(
                context,
                _queue[_index],
                isDarkMode,
                () => setState(() {}),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.flip),
              tooltip: 'Flip card',
              onPressed: _flipCurrentCard,
            ),
            IconButton(
              icon: const Icon(Icons.gesture),
              tooltip: 'View stroke order',
              onPressed: () => showStrokeOrderDialogFor(context, _queue[_index], isDarkMode),
            ),
            if (_queue[_index].cardType == 'Kanji' || _queue[_index].cardType == 'Vocab')
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'About this ${_queue[_index].cardType == 'Kanji' ? 'kanji' : 'word'}',
                onPressed: () => _showCardInfo(_queue[_index]),
              ),
          ],
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Study settings',
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: _queue.isEmpty
            ? _buildMessage(isDarkMode, "No cards are due for review right now.")
            : (_index >= _queue.length || _endedEarly)
                ? _buildSummaryScreen(isDarkMode)
                : _buildCard(isDarkMode),
      ),
    );
  }

  Widget _buildMessage(bool isDarkMode, String message) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 20),
            _buildContinuePrompt(isDarkMode),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A00FE),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Done"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryScreen(bool isDarkMode) {
    final total = _results.length;
    final profile = _userProfile;
    final leveledUp = profile != null && profile.level > _levelAtStart;
    final startXpNeeded = UserProfile.xpForLevel(_levelAtStart);
    final startFraction = startXpNeeded > 0 ? (_xpAtStart / startXpNeeded).clamp(0.0, 1.0) : 0.0;
    final endXpNeeded = profile != null ? UserProfile.xpForLevel(profile.level) : startXpNeeded;
    final endFraction = profile != null && endXpNeeded > 0 ? (profile.xp / endXpNeeded).clamp(0.0, 1.0) : startFraction;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: Color(0xFF9A00FE), size: 64),
          const SizedBox(height: 12),
          Text(
            "Session Complete!",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            total == 0 ? "No cards graded" : "$_correctCount / $total correct",
            style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white70 : Colors.black54),
          ),
          if (profile != null) ...[
            const SizedBox(height: 24),
            _LevelProgressAnimation(
              startLevel: _levelAtStart,
              endLevel: profile.level,
              startFraction: leveledUp ? 0.0 : startFraction,
              endFraction: endFraction,
              leveledUp: leveledUp,
              xpEarned: _xpEarnedThisSession,
              isDarkMode: isDarkMode,
            ),
          ],
          if (total > 0) ...[
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Studied cards",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ..._results.map((r) => Card(
                  color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      r.correct ? Icons.check_circle : Icons.cancel,
                      color: r.correct ? Colors.green : Colors.redAccent,
                    ),
                    title: Text(
                      r.card.japanese,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      r.card.english,
                      style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                    ),
                  ),
                )),
          ],
          if (!_endedEarly) _buildContinuePrompt(isDarkMode),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A00FE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Done", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // Offers to keep the session going once its queue runs out naturally:
  // more new cards (up to the deck's daily amount) for an ordinary deck, or
  // - for the day-scheduled 90 Day Kanji Challenge - the next day's kanji
  // early, for a user working through it faster than one day at a time.
  Widget _buildContinuePrompt(bool isDarkMode) {
    final String message;
    final String buttonLabel;
    final VoidCallback onPressed;

    if (widget.deck.challengeStartDate != null) {
      final nextDay = _nextEarlyChallengeDay();
      if (nextDay == null) return const SizedBox.shrink();
      message = "Working fast! Want to learn Day $nextDay's content early?";
      buttonLabel = "Learn Day $nextDay Now";
      onPressed = () => _continueWithChallengeDay(nextDay);
    } else {
      final more = _unqueuedNewCards();
      final take = more.length < widget.deck.newCardsPerDay ? more.length : widget.deck.newCardsPerDay;
      if (take <= 0) return const SizedBox.shrink();
      message = "Want to keep going with $take more new card${take == 1 ? '' : 's'}?";
      buttonLabel = "Continue";
      onPressed = _continueWithMoreCards;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF9A00FE).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF9A00FE).withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 15),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
                onPressed: onPressed,
                child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradingButtons() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _answer(false),
              child: const Text("Incorrect", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _answer(true),
              child: const Text("Correct", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _revealBlock(StudyCard card, bool isDarkMode, bool frontIsEnglish) {
    return Column(
      children: [
        if (frontIsEnglish)
          Text(
            card.japanese,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        Text(
          card.hiragana,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        if (_settings.enableRomaji && card.romaji.isNotEmpty)
          Text(
            card.romaji,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white54 : Colors.black54),
          ),
        if (!frontIsEnglish) ...[
          const SizedBox(height: 12),
          Text(
            card.english,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
        _audioButton(
          frontIsEnglish ? _japaneseText(card) : card.english,
          frontIsEnglish ? 'Japanese' : 'English',
        ),
        _memoryTechniqueSection(card, isDarkMode),
      ],
    );
  }

  // Scales the drawing canvas to fit the screen without needing to scroll
  // down to reach the grading buttons - the old width-only heuristic looked
  // fine on a normal phone but left no room for the buttons on shorter
  // screens, since it never accounted for available height at all.
  double _drawCanvasScale(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final widthScale = (size.width / 600).clamp(0.6, 1.2) * 0.8;
    // Rough estimate of everything else in the card (counter, prompt,
    // audio button, padding, Show Answer/grading buttons) plus the
    // canvas's own non-drawing-area chrome (hint/answer text) at scale 1.0 -
    // not exact, but close enough to keep the whole card on one screen.
    const reservedHeight = 260.0;
    const canvasNaturalHeight = 400.0 + 90.0;
    final heightScale = ((size.height - reservedHeight) / canvasNaturalHeight).clamp(0.45, 1.2);
    return widthScale < heightScale ? widthScale : heightScale;
  }

  Widget _buildCard(bool isDarkMode) {
    final card = _queue[_index];
    final frontIsEnglish = card.englishFirst;
    final mode = _effectiveMode(card);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Card ${_index + 1} of ${_queue.length}',
            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 24),
          Text(
            frontIsEnglish ? card.english : card.japanese,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: frontIsEnglish ? 32 : 48,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          card.cardType == 'Kana'
              ? _audioButton(_japaneseText(card), 'Japanese')
              : _audioButton(
                  frontIsEnglish ? card.english : _japaneseText(card),
                  frontIsEnglish ? 'English' : 'Japanese',
                ),
          const SizedBox(height: 16),

          if (mode == 'basic' && _showAnswer) ...[
            _revealBlock(card, isDarkMode, frontIsEnglish),
            const SizedBox(height: 24),
          ],

          if (mode == 'draw') ...[
            WritingPracticeCanvas(
              key: ValueKey('draw-$_index-$_drawResetCounter'),
              kanjiVGCodes: card.kanjiVGCodes,
              isDarkMode: isDarkMode,
              kanji: card.japanese,
              translation: card.english,
              hideButtons: true,
              compactStrokeControls: true,
              showAnswerOverride: _drawAnswerRevealed,
              resetCounter: _drawResetCounter,
              scale: _drawCanvasScale(context),
            ),
            const SizedBox(height: 16),
            if (!_drawAnswerRevealed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9A00FE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _revealDrawAnswer(card, isDarkMode),
                  child: const Text("Show Answer", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              )
            else
              TextButton.icon(
                onPressed: () => showStrokeOrderDialogFor(context, card, isDarkMode),
                icon: const Icon(Icons.gesture, color: Color(0xFF9A00FE)),
                label: const Text("View stroke order again", style: TextStyle(color: Color(0xFF9A00FE))),
              ),
            if (_drawAnswerRevealed) _memoryTechniqueSection(card, isDarkMode),
            const SizedBox(height: 16),
          ],

          if (mode == 'type' && !_typeMismatched) ...[
            TextField(
              controller: _typeController,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 18),
              decoration: InputDecoration(
                hintText: frontIsEnglish ? 'Type the Japanese' : 'Type the English',
                hintStyle: TextStyle(color: isDarkMode ? Colors.white38 : Colors.black38),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _submitTypedAnswer(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A00FE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _submitTypedAnswer,
                child: const Text("Submit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (mode == 'type' && _typeMismatched) ...[
            _revealBlock(card, isDarkMode, frontIsEnglish),
            const SizedBox(height: 24),
          ],

          if (mode == 'basic' && !_showAnswer)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A00FE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _showAnswerNow,
                child: const Text("Show Answer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          else if (_isAnswerRevealed(mode))
            _gradingButtons(),
        ],
      ),
    );
  }
}

// Animated level/XP display for the session summary: the progress bar
// smoothly fills from the session's starting fraction to its ending one,
// and a "LEVEL UP" badge pops in if a level was gained during the session.
class _LevelProgressAnimation extends StatelessWidget {
  final int startLevel;
  final int endLevel;
  final double startFraction;
  final double endFraction;
  final bool leveledUp;
  final int xpEarned;
  final bool isDarkMode;

  const _LevelProgressAnimation({
    required this.startLevel,
    required this.endLevel,
    required this.startFraction,
    required this.endFraction,
    required this.leveledUp,
    required this.xpEarned,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (leveledUp) ...[
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF9A00FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "LEVEL UP! $startLevel → $endLevel",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          "Level $endLevel",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 260,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: startFraction, end: endFraction),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 14,
                backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9A00FE)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "+$xpEarned XP earned",
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        ),
      ],
    );
  }
}
