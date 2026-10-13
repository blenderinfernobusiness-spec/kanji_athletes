import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_sync_page.dart';
import 'hiragana_challenge_data.dart';
import 'kanji_challenge_data.dart';
import 'lesson_data.dart';
import 'lesson_viewer_screen.dart';
import 'study_data.dart';
import 'study_mode.dart';
import 'writing_practice_canvas.dart';

const Color _accent = Color(0xFF9A00FE);

// Cumulative kanji count once a given JLPT level (and everything below it)
// is known - each level's own count comes from practice_sets_data.dart's
// own JLPT kanji lists (N5 80, N4 170, N3 370, N2 380, N1 71), summed
// because a learner who already knows N4 also knows N5.
const Map<String, int> _jlptCumulativeKanjiCounts = {
  'N5': 80,
  'N4': 250,
  'N3': 620,
  'N2': 1000,
  'N1': 1071,
};

// Walks the 90 Day Kanji Challenge's own day-by-day kanji counts (not a
// fixed per-day number - see kanji_challenge_data.dart) to find which day
// introduces the [targetCount]th kanji, so a learner who already knows that
// many kanji can skip straight past the days that would just reteach them.
int _challengeDayForKnownCount(int targetCount) {
  if (targetCount <= 0) return 0;
  var cumulative = 0;
  for (var i = 0; i < kanjiChallengeDays.length; i++) {
    cumulative += kanjiChallengeDays[i].length;
    if (cumulative >= targetCount) return i + 1;
  }
  return kanjiChallengeDays.length;
}

// Shown once, before HomeScreen, to a brand new install that isn't signed
// in yet (see main.dart's _StartupGate for when that is). Signing in just
// finishes onboarding straight to the home screen, like a returning user;
// creating a new account instead continues to a self-reported experience
// level question. Answering "brand new" leads into a short hiragana
// explainer, a taste of writing practice, then auto-adds the Kana Course
// deck and drops the user straight into studying it; "knows kana already"
// finishes onboarding immediately, same as signing in.
class OnboardingFlow extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onFinished;
  // Shows a "Skip" button on the sign-in/create-account slide that pretends
  // account creation succeeded (continuing to the slides after it) without
  // needing real credentials - only set by main.dart's testing-only "Try
  // tutorial" button, so real first-time users always go through
  // sign-in/sign-up. Remove along with that button once onboarding is
  // finished.
  final bool testMode;
  const OnboardingFlow({super.key, required this.isDarkMode, required this.onFinished, this.testMode = false});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0;
  bool _startingKanaCourse = false;
  bool _startingKanjiChallenge = false;

  // 'brand_new' continues into the kana slides below; 'knows_kana' finishes
  // onboarding immediately, same as signing in. Either way the choice is
  // saved (nothing else reads it yet - here purely to pick the next slide).
  Future<void> _handleExperienceChoice(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onboarding_japanese_level', level);
    if (!mounted) return;
    if (level == 'brand_new') {
      setState(() => _step = 3);
    } else {
      setState(() => _step = 6);
    }
  }

  // 'grammar'/'vocab' aren't built out yet - finish onboarding same as
  // before this slide existed. 'kanji' continues to the kanji-knowledge
  // question.
  void _handleFocusChoice(String focus) {
    if (focus == 'kanji') {
      setState(() => _step = 7);
    } else {
      widget.onFinished();
    }
  }

  // Adds a fresh Kana Course deck (same de-duped-name pattern as
  // study.dart's _createHiraganaChallengeDeck, since a "brand new" learner
  // could in principle already have one from a previous visit), finishes
  // onboarding, then drops the user straight into studying it via the same
  // entry point the Study screen itself uses (study_mode.dart's
  // startSpacedRepetition) - so day 1's lesson recap shows first, same as
  // it would from the normal UI.
  Future<void> _startKanaCourse() async {
    if (_startingKanaCourse) return;
    setState(() => _startingKanaCourse = true);
    final decks = await loadStudyDecks();
    final deck = buildHiraganaChallengeDeck();
    String name = deck.name;
    int copy = 1;
    while (decks.any((d) => d.name == name)) {
      copy++;
      name = '${deck.name} ($copy)';
    }
    deck.name = name;
    deck.lessonSetId = kHiraganaTrackId;
    decks.add(deck);
    await saveStudyDecks(decks);
    if (!mounted) return;
    widget.onFinished();
    await startSpacedRepetition(context, deck, widget.isDarkMode, () {});
  }

  // targetKanjiCount is cumulative, from _jlptCumulativeKanjiCounts (0 for
  // "none yet"). Builds a fresh 90 Day Kanji Challenge deck and backdates
  // its progress past the days that'd just reteach kanji the user already
  // knows (study_data.dart's applyImportedChallengeProgress - the same
  // mechanism the normal "Already done some of this challenge?" prompt
  // uses). That backdating means the deck's own day-elapsed lesson check
  // would never naturally land on day 1 or day 2 again (a deck only has one
  // start date, with no persisted notion of a custom lesson schedule), so
  // for anyone who isn't starting completely fresh, both intro lessons are
  // shown here during onboarding instead, back to back, right before the
  // deck opens, rather than the second being deferred to a real day later.
  Future<void> _startKanjiChallenge(int targetKanjiCount) async {
    if (_startingKanjiChallenge) return;
    setState(() => _startingKanjiChallenge = true);
    final completedDay = _challengeDayForKnownCount(targetKanjiCount);

    final decks = await loadStudyDecks();
    final deck = buildKanjiChallengeDeck();
    String name = deck.name;
    int copy = 1;
    while (decks.any((d) => d.name == name)) {
      copy++;
      name = '${deck.name} ($copy)';
    }
    deck.name = name;
    deck.lessonSetId = kKanjiChallengeTrackId;

    if (completedDay > 0) {
      for (final day in [1, 2]) {
        final lesson = lessonForTrackAndDay(kKanjiChallengeTrackId, day);
        if (lesson == null) continue;
        if (!mounted) return;
        final completed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => LessonViewerScreen(lesson: lesson, isDarkMode: widget.isDarkMode, deck: deck),
          ),
        );
        if (completed != true) {
          if (mounted) setState(() => _startingKanjiChallenge = false);
          return;
        }
        deck.completedLessonDays.add(day);
      }
      applyImportedChallengeProgress(deck, completedDay);
    }

    decks.add(deck);
    await saveStudyDecks(decks);
    if (!mounted) return;
    widget.onFinished();
    await startSpacedRepetition(context, deck, widget.isDarkMode, () {});
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case 0:
        return _WelcomeSlide(isDarkMode: widget.isDarkMode, onContinue: () => setState(() => _step = 1));
      case 1:
        return _AuthSlide(
          isDarkMode: widget.isDarkMode,
          onBack: () => setState(() => _step = 0),
          onSignedIn: widget.onFinished,
          onAccountCreated: () => setState(() => _step = 2),
          // Pretends account creation succeeded (continues to the next
          // slide) rather than ending the flow outright, so "Try tutorial"
          // can preview everything after auth without real credentials.
          onSkip: widget.testMode ? () => setState(() => _step = 2) : null,
        );
      case 2:
        return _ExperienceSlide(
          isDarkMode: widget.isDarkMode,
          onBack: () => setState(() => _step = 1),
          onChoice: _handleExperienceChoice,
        );
      case 3:
        return _HiraganaIntroSlide(isDarkMode: widget.isDarkMode, onContinue: () => setState(() => _step = 4));
      case 4:
        return _DrawHiraganaSlide(isDarkMode: widget.isDarkMode, onContinue: () => setState(() => _step = 5));
      case 5:
        return _KanaCourseReadySlide(
          isDarkMode: widget.isDarkMode,
          busy: _startingKanaCourse,
          onStart: _startKanaCourse,
        );
      case 6:
        return _FocusSlide(
          isDarkMode: widget.isDarkMode,
          onBack: () => setState(() => _step = 2),
          onChoice: _handleFocusChoice,
        );
      default:
        return _KanjiKnowledgeSlide(
          isDarkMode: widget.isDarkMode,
          busy: _startingKanjiChallenge,
          onBack: () => setState(() => _step = 6),
          onChoice: _startKanjiChallenge,
        );
    }
  }
}

class _WelcomeSlide extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onContinue;
  const _WelcomeSlide({required this.isDarkMode, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final fg = isDarkMode ? Colors.white : Colors.black87;
    final fgMuted = isDarkMode ? Colors.white70 : Colors.black54;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Same bold-kanji-over-a-purple-banner treatment as the
                  // lesson category art (assets/lessonskanjiscreen.png etc)
                  // - built as text/a Container rather than another baked
                  // image, so it reflows for any string and still contrasts
                  // in dark mode (where a baked-black-text image wouldn't).
                  Text(
                    '漢字',
                    style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: fg, height: 1),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    color: _accent,
                    child: const Text(
                      'WELCOME!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ready to start learning Japanese?',
                    style: TextStyle(fontSize: 16, color: fgMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: onContinue,
                      child: const Text("Let's go", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExperienceSlide extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onBack;
  final void Function(String level) onChoice;
  const _ExperienceSlide({required this.isDarkMode, required this.onBack, required this.onChoice});

  @override
  State<_ExperienceSlide> createState() => _ExperienceSlideState();
}

class _ExperienceSlideState extends State<_ExperienceSlide> {
  bool _showKanaInfo = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.isDarkMode ? Colors.white : Colors.black87;
    final fgMuted = widget.isDarkMode ? Colors.white70 : Colors.black54;
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'How much Japanese do you know?',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: fg),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      _ChoiceCard(
                        label: 'Brand new, still learning kana (hiragana and katakana)',
                        isDarkMode: widget.isDarkMode,
                        onTap: () => widget.onChoice('brand_new'),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() => _showKanaInfo = !_showKanaInfo),
                          icon: Icon(_showKanaInfo ? Icons.expand_less : Icons.expand_more, size: 18, color: fgMuted),
                          label: Text('What is kana?', style: TextStyle(color: fgMuted, fontSize: 13)),
                        ),
                      ),
                      if (_showKanaInfo)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
                          child: Text(
                            "Kana are Japanese's two phonetic alphabets - hiragana (ひらがな) for native words and "
                            "grammar, and katakana (カタカナ) mostly for foreign loanwords. Together they're the "
                            "foundation everything else, including kanji, builds on.",
                            style: TextStyle(color: fgMuted, fontSize: 13),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _ChoiceCard(
                        label: 'I know kana already!',
                        isDarkMode: widget.isDarkMode,
                        onTap: () => widget.onChoice('knows_kana'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: fgMuted),
                onPressed: widget.onBack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final bool isDarkMode;
  final VoidCallback onTap;
  // Small accent-colored tag shown above the label, e.g. "RECOMMENDED".
  final String? badge;
  const _ChoiceCard({required this.label, required this.isDarkMode, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    final fg = isDarkMode ? Colors.white : Colors.black87;
    final cardBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100]!;
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accent.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge != null) ...[
                Text(
                  badge!,
                  style: const TextStyle(color: _accent, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                label,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HiraganaIntroSlide extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onContinue;
  const _HiraganaIntroSlide({required this.isDarkMode, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final fg = isDarkMode ? Colors.white : Colors.black87;
    final fgMuted = isDarkMode ? Colors.white70 : Colors.black54;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ひらがな', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: fg, height: 1)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    color: _accent,
                    child: const Text(
                      'STEP ONE: HIRAGANA',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Hiragana is the first alphabet you'll learn in Japanese - every word, grammar "
                    "point, and eventually kanji builds on it, so it's the natural place to start.",
                    style: TextStyle(fontSize: 16, color: fgMuted, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: onContinue,
                      child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawHiraganaSlide extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onContinue;
  const _DrawHiraganaSlide({required this.isDarkMode, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final fg = isDarkMode ? Colors.white : Colors.black87;
    final fgMuted = isDarkMode ? Colors.white70 : Colors.black54;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Let's try writing your first one",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: fg),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'あ - "a"',
                    style: TextStyle(fontSize: 14, color: fgMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Codepoint 3042 (hex) is あ - KanjiVG's stroke data is
                  // keyed by codepoint for kana just as much as kanji, see
                  // hiragana_challenge_data.dart's _kanjiVGCodeFor, which
                  // already uses this exact code for every drawing card in
                  // the real Kana Course deck.
                  WritingPracticeCanvas(
                    kanjiVGCodes: const ['03042'],
                    kanji: 'あ',
                    translation: 'a',
                    isDarkMode: isDarkMode,
                    scale: 0.7,
                    showHintByDefault: true,
                    compactStrokeControls: true,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: onContinue,
                      child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KanaCourseReadySlide extends StatelessWidget {
  final bool isDarkMode;
  final bool busy;
  final VoidCallback onStart;
  const _KanaCourseReadySlide({required this.isDarkMode, required this.busy, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final fg = isDarkMode ? Colors.white : Colors.black87;
    final fgMuted = isDarkMode ? Colors.white70 : Colors.black54;
    Widget bullet(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 15)),
          Expanded(child: Text(text, style: TextStyle(color: fgMuted, fontSize: 14, height: 1.4))),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Let's get started with the Kana Course!",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: fg),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  bullet('Beginner friendly'),
                  bullet(
                    "Study as much or as little as you like - even two minutes a day can be great, "
                    "but the more you apply yourself, the faster you'll progress, of course.",
                  ),
                  bullet('All progress is saved when you exit, so you can come back to it later.'),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: busy ? null : onStart,
                      child: busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Let's go!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusSlide extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onBack;
  final void Function(String focus) onChoice;
  const _FocusSlide({required this.isDarkMode, required this.onBack, required this.onChoice});

  @override
  Widget build(BuildContext context) {
    final fg = isDarkMode ? Colors.white : Colors.black87;
    final fgMuted = isDarkMode ? Colors.white70 : Colors.black54;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "What would you like to focus on?",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: fg),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      _ChoiceCard(
                        label: "Let's learn some kanji",
                        badge: 'RECOMMENDED',
                        isDarkMode: isDarkMode,
                        onTap: () => onChoice('kanji'),
                      ),
                      const SizedBox(height: 16),
                      _ChoiceCard(
                        label: "Let's learn some grammar",
                        isDarkMode: isDarkMode,
                        onTap: () => onChoice('grammar'),
                      ),
                      const SizedBox(height: 16),
                      _ChoiceCard(
                        label: "Let's learn some vocab",
                        isDarkMode: isDarkMode,
                        onTap: () => onChoice('vocab'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'You can always study more than one later!',
                        style: TextStyle(color: fgMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: fgMuted),
                onPressed: onBack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KanjiKnowledgeSlide extends StatelessWidget {
  final bool isDarkMode;
  final bool busy;
  final VoidCallback onBack;
  // Cumulative kanji count known (0 for "none yet") - see
  // _jlptCumulativeKanjiCounts.
  final void Function(int targetKanjiCount) onChoice;
  const _KanjiKnowledgeSlide({
    required this.isDarkMode,
    required this.busy,
    required this.onBack,
    required this.onChoice,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDarkMode ? Colors.white : Colors.black87;
    final fgMuted = isDarkMode ? Colors.white70 : Colors.black54;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: busy
                  ? const CircularProgressIndicator(color: _accent)
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Do you know any kanji already?',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: fg),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "We'll start the 90 Day Kanji Challenge past whatever you already know, "
                              "so you're not reviewing kanji you've already learned.",
                              style: TextStyle(fontSize: 13, color: fgMuted),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            _ChoiceCard(
                              label: "None yet - I'm brand new to kanji",
                              isDarkMode: isDarkMode,
                              onTap: () => onChoice(0),
                            ),
                            const SizedBox(height: 12),
                            for (final entry in _jlptCumulativeKanjiCounts.entries) ...[
                              _ChoiceCard(
                                label: 'JLPT ${entry.key} - ${entry.value} '
                                    '${entry.key == 'N5' ? 'Beginner Kanji' : 'Kanji'}',
                                isDarkMode: isDarkMode,
                                onTap: () => onChoice(entry.value),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: fgMuted),
                onPressed: busy ? null : onBack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthSlide extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onBack;
  final VoidCallback onSignedIn;
  final VoidCallback onAccountCreated;
  // Non-null only in OnboardingFlow's testMode - see its doc comment.
  final VoidCallback? onSkip;
  const _AuthSlide({
    required this.isDarkMode,
    required this.onBack,
    required this.onSignedIn,
    required this.onAccountCreated,
    this.onSkip,
  });

  @override
  State<_AuthSlide> createState() => _AuthSlideState();
}

class _AuthSlideState extends State<_AuthSlide> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  child: CloudSignInForm(
                    isDarkMode: widget.isDarkMode,
                    busy: _busy,
                    onBusyChanged: (v) => setState(() => _busy = v),
                    onSignedIn: widget.onSignedIn,
                    onAccountCreated: widget.onAccountCreated,
                    initiallyCreatingAccount: true,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                onPressed: _busy ? null : widget.onBack,
              ),
            ),
            if (widget.onSkip != null)
              Positioned(
                top: 4,
                right: 4,
                child: TextButton(
                  onPressed: _busy ? null : widget.onSkip,
                  child: Text('Skip', style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
