import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'study_data.dart';
import 'sets_data.dart';
import 'kanji_challenge_data.dart';
import 'deck_detail.dart';
import 'skool_activity_screen.dart';
import 'grammar_activities.dart';
import 'grammar_data.dart';
import 'ruby_text.dart';

// One step of an interactive lesson journey. Every step shows [before]
// first; if [question] is set, the learner has to pick an answer from
// [options] (0-indexed, [correctIndex] marks the right one) before [after]
// and [explanation] reveal - a small "think about it first" moment standing
// in for a presenter pausing to ask the room. If [question] is null, [after]
// and [explanation] simply reveal immediately with an entrance animation.
class LessonStep {
  final String? kickerPlain;
  final String? kickerHighlight;
  final Widget Function(bool isDarkMode) before;
  final String? question;
  final List<String>? options;
  final int? correctIndex;
  final Widget Function(bool isDarkMode)? after;
  final String? explanation;

  const LessonStep({
    this.kickerPlain,
    this.kickerHighlight,
    required this.before,
    this.question,
    this.options,
    this.correctIndex,
    this.after,
    this.explanation,
  });
}

// Identifies which curriculum a lesson (and the deck that triggers it)
// belongs to - so two different day-scheduled decks (e.g. the 90 Day Kanji
// Challenge and the Essential Vocabulary Challenge) can each have their own
// "Day 1" lesson without colliding.
const kKanjiChallengeTrackId = 'kanji_challenge';
const kEssentialVocabTrackId = 'essential_vocab';
const kHiraganaTrackId = 'hiragana_challenge';

// One authored lesson - an interactive slideshow recapping background
// material for a day of a curriculum that isn't already covered by that
// day's flashcards. Day 1's Kanji Challenge lesson recaps the Japanese
// writing system overview that opens that video, before the individual
// kanji begin; the Essential Vocabulary Challenge has its own Day 1 lesson
// on how to learn a word effectively.
class Lesson {
  final String trackId;
  final int day;
  final String title;
  final String introSubtitle;
  final List<LessonStep> steps;
  // An optional free-form activity shown in place of the ordinary step list,
  // for a lesson that needs real interaction beyond a think-first quiz
  // question - e.g. the Hiragana Challenge's end-of-day-1 sentence-building
  // exercise. Only supported for a lesson with an empty [steps] list; builds
  // its own widget, calling [onDone] once the learner's finished so
  // LessonViewerScreen can move on to its closing screen.
  final Widget Function(BuildContext context, bool isDarkMode, VoidCallback onDone)? activityBuilder;
  // Set when this lesson is conceptually a recap/capstone for the day BEFORE
  // [day] rather than new material for [day] itself - e.g. the Hiragana
  // Challenge's "Introduce Yourself" lesson wraps up day 6 (its new
  // vocabulary's own flashcards are what day 7 actually starts with), so it
  // triggers exactly like a day-7 lesson (right before day 7's cards) but
  // should be labelled as day 6's, not day 7's. Purely a display concern -
  // [day] still governs unlocking/triggering either way; only set when it
  // differs from [day] - 1 in meaning (i.e. never for an ordinary lesson).
  final int? endOfDay;
  // Lets an activity step back a slide itself. Returns false once it's on
  // its first slide, so the lesson can go back to its intro instead.
  final bool Function()? activityBack;
  // How far through the activity it is, 0 to 1, so the lesson's bar moves
  // with every press inside it rather than only when it changes phase.
  final ValueNotifier<double>? activityProgress;

  const Lesson({
    this.trackId = kKanjiChallengeTrackId,
    required this.day,
    required this.title,
    required this.introSubtitle,
    this.steps = const [],
    this.activityBuilder,
    this.endOfDay,
    this.activityBack,
    this.activityProgress,
  });
}

// The Grammar deck's lessons, one per grammar point (see grammar_data.dart).
final List<Lesson> grammarLessons = [for (final point in grammarPoints) _grammarLesson(point)];

Lesson _grammarLesson(GrammarPoint point) {
  final activityKey = GlobalKey<GrammarLessonActivityState>();
  final progress = ValueNotifier<double>(0);
  return Lesson(
    trackId: kGrammarTrackId,
    day: point.day,
    title: point.title,
    introSubtitle: "Today's grammar point",
    activityBuilder: (context, isDarkMode, onDone) => GrammarLessonActivity(
      key: activityKey,
      point: point,
      isDarkMode: isDarkMode,
      onDone: onDone,
      progress: progress,
    ),
    activityBack: () => activityKey.currentState?.goBack() ?? false,
    activityProgress: progress,
  );
}

Lesson? lessonForTrackAndDay(String trackId, int day) {
  for (final l in [...lessons, ...grammarLessons]) {
    if (l.trackId == trackId && l.day == day) return l;
  }
  return null;
}

int? _dayFromStartDate(String? startDateStamp) {
  if (startDateStamp == null) return null;
  final start = DateTime.parse(startDateStamp);
  final day = DateTime.now().difference(start).inDays + 1;
  return day < 1 ? 1 : day;
}

// The 90 Day Kanji Challenge deck's current day (1-based, clamped to the
// range of authored days), or 0 if [deck] isn't a challenge deck
// (challengeStartDate unset). Used for both its card-unlock schedule and its
// lesson gating.
int currentChallengeDayFor(StudyDeck deck) {
  final day = _dayFromStartDate(deck.challengeStartDate);
  if (day == null) return 0;
  return day > kanjiChallengeDays.length ? kanjiChallengeDays.length : day;
}

// Which day a deck is on for LESSON-gating purposes only - works for a
// day-scheduled challenge deck (via challengeStartDate) just as well as an
// ordinary deck that's simply tracking lessons from its own creation date
// (deckCreatedDate), e.g. the Essential Vocabulary Challenge, whose cards
// are otherwise introduced at the user's own configured daily rate rather
// than a fixed per-day schedule.
int lessonDayFor(StudyDeck deck) {
  return _dayFromStartDate(deck.challengeStartDate) ?? _dayFromStartDate(deck.deckCreatedDate) ?? 0;
}

const kLessonPurple = Color(0xFF9A00FE);
const kLessonHiraganaColor = Color(0xFF2E7DD7); // blue
const kLessonKatakanaColor = Color(0xFFE0742F); // orange

TextStyle lessonBodyStyle(bool isDarkMode, {double size = 24, FontWeight weight = FontWeight.w800}) => TextStyle(
  fontSize: size,
  fontWeight: weight,
  color: isDarkMode ? Colors.white : Colors.black87,
  height: 1.3,
);

Widget lessonCol(List<Widget> children) =>
    Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: children);
Widget lessonRow(List<Widget> children) =>
    Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: children);

// A character (or short run of characters) with a small colored arrow +
// label above it, pointing down into the character - used to call out
// which writing system a part of a word belongs to, the way a presenter
// would gesture at it while explaining. Always the same size across
// kanji/hiragana/katakana so nothing looks visually "less important".
Widget labeledChar(String char, String label, Color color, {double size = 44}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: lessonCol([
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      Icon(Icons.arrow_downward, size: 14, color: color),
      Text(char, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: color)),
    ]),
  );
}

// A kanji/word with small furigana tucked tightly above it, the way real
// furigana is typeset - not a loose caption floating above the word.
// The reading goes over the kanji only (see rubyWord), so pass the reading of
// the whole word, okurigana included (私の趣味 is わたしのしゅみ).
Widget withFurigana(String furigana, String word, bool isDarkMode, {double wordSize = 44, Color? wordColor}) {
  return lessonCol([
    rubyWord(
      text: word,
      reading: furigana,
      fontSize: wordSize,
      textColor: wordColor ?? (isDarkMode ? Colors.white : Colors.black),
      rubyColor: isDarkMode ? Colors.white54 : Colors.black45,
      fontWeight: FontWeight.w900,
      rubyScale: 0.32,
    ),
  ]);
}

// An optional link to a Skool classroom video, shown inline in a lesson step
// for material that has a companion video the learner can watch for more
// depth - purely optional, so it's a plain text button rather than something
// blocking progress through the lesson.
Widget skoolVideoLink(String url) {
  return TextButton.icon(
    onPressed: () async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    },
    icon: const Icon(Icons.play_circle_outline, color: kLessonPurple),
    label: const Text('Optional: watch on Skool', style: TextStyle(color: kLessonPurple, fontWeight: FontWeight.bold)),
  );
}

// The full "combined sound" (youon) reference chart - every consonant kana
// paired with small ゃ/ゅ/ょ, shown as a browsable grid of tiles rather than
// flashcards, since these aren't new characters to drill so much as a
// reference to get familiar with (see the "Small や, ゆ, よ" lesson).
Widget youonChart(bool isDarkMode) {
  const pairs = [
    ['kya', 'きゃ'], ['kyu', 'きゅ'], ['kyo', 'きょ'],
    ['sha', 'しゃ'], ['shu', 'しゅ'], ['sho', 'しょ'],
    ['cha', 'ちゃ'], ['chu', 'ちゅ'], ['cho', 'ちょ'],
    ['nya', 'にゃ'], ['nyu', 'にゅ'], ['nyo', 'にょ'],
    ['hya', 'ひゃ'], ['hyu', 'ひゅ'], ['hyo', 'ひょ'],
    ['mya', 'みゃ'], ['myu', 'みゅ'], ['myo', 'みょ'],
    ['rya', 'りゃ'], ['ryu', 'りゅ'], ['ryo', 'りょ'],
    ['gya', 'ぎゃ'], ['gyu', 'ぎゅ'], ['gyo', 'ぎょ'],
    ['ja', 'じゃ'], ['ju', 'じゅ'], ['jo', 'じょ'],
    ['bya', 'びゃ'], ['byu', 'びゅ'], ['byo', 'びょ'],
    ['pya', 'ぴゃ'], ['pyu', 'ぴゅ'], ['pyo', 'ぴょ'],
  ];
  return Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final p in pairs)
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(p[1], style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : Colors.black)),
              Text(p[0], style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.white54 : Colors.black45)),
            ],
          ),
        ),
    ],
  );
}

// Builds the Essential Vocabulary Challenge deck's cards fresh from the
// Essential Vocabulary dictionary set - the same mapping and name-collision
// handling used when creating it from Study's "Choose a Premade Set" picker
// (see study.dart's _createEssentialVocabDeck), extracted here so a lesson
// step can create it too without depending on that screen's private state.
StudyDeck buildEssentialVocabDeck(List<StudyDeck> existingDecks) {
  final set = setsData['Essential Vocabulary'];
  final cards = (set?.items ?? const <Item>[])
      .map((item) => StudyCard(
            japanese: item.japanese,
            hiragana: item.reading,
            english: item.translation,
            kanjiVGCodes: findKanjiVGCodesForWord(item.japanese),
            cardType: 'Vocab',
          ))
      .toList();
  String name = 'Essential Vocabulary Challenge';
  int copy = 1;
  while (existingDecks.any((d) => d.name == name)) {
    copy++;
    name = 'Essential Vocabulary Challenge ($copy)';
  }
  return StudyDeck(name: name, cards: cards, lessonSetId: kEssentialVocabTrackId, deckCreatedDate: todayStamp());
}

StudyDeck? _essentialVocabDeckIn(List<StudyDeck> decks) {
  for (final d in decks) {
    if (d.lessonSetId == kEssentialVocabTrackId) return d;
  }
  return null;
}

// The button shown at the end of the 90 Day Kanji Challenge's Day 2 lesson,
// encouraging the learner to start on vocabulary alongside their kanji.
// Reuses the Essential Vocabulary Challenge deck if one's already been
// started (rather than creating a duplicate) and opens it either way, same
// as tapping it from Study's own deck list.
class _StartVocabButton extends StatefulWidget {
  final bool isDarkMode;
  const _StartVocabButton({required this.isDarkMode});

  @override
  State<_StartVocabButton> createState() => _StartVocabButtonState();
}

class _StartVocabButtonState extends State<_StartVocabButton> {
  bool _busy = false;

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    final decks = await loadStudyDecks();
    var deck = _essentialVocabDeckIn(decks);
    final isNew = deck == null;
    deck ??= buildEssentialVocabDeck(decks);
    if (isNew) {
      decks.add(deck);
      await saveStudyDecks(decks);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    final targetDeck = deck;
    if (isNew) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Started "${targetDeck.name}" with ${targetDeck.cards.length} words')),
      );
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeckDetailScreen(
          deck: targetDeck,
          isDarkMode: widget.isDarkMode,
          onThemeChanged: (_) {},
          onChanged: () => saveStudyDecks(decks),
          onDelete: () async {
            decks.remove(targetDeck);
            await saveStudyDecks(decks);
          },
          onDuplicate: () async {
            decks.add(duplicateDeck(targetDeck, decks));
            await saveStudyDecks(decks);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _busy ? null : _open,
      style: ElevatedButton.styleFrom(
        backgroundColor: kLessonPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      icon: _busy
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.menu_book),
      label: const Text("Start Essential Vocabulary", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }
}

final List<Lesson> lessons = [
  Lesson(
    trackId: kHiraganaTrackId,
    day: 1,
    title: 'Welcome to Japanese',
    introSubtitle: "New to Japanese? Start here - a friendly overview of the language and its writing system, before we learn your first hiragana.",
    steps: [
      // 1. What Japanese is
      LessonStep(
        kickerPlain: 'WELCOME TO',
        kickerHighlight: 'JAPANESE',
        before: (dark) => withFurigana('にほんご', '日本語', dark, wordSize: 48),
        question: 'Roughly how many people do you think speak Japanese as their native language?',
        options: const ['About 1 million', 'About 125 million', 'About 1 billion'],
        correctIndex: 1,
        after: (dark) => Text(
          '日本語 (nihongo) - "the Japanese language"',
          textAlign: TextAlign.center,
          style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w600),
        ),
        explanation: "Japanese is spoken natively by around 125 million people, almost entirely in Japan - which "
            "also makes it one of the most self-contained major languages in the world, since nearly everyone who "
            "speaks it lives in one place with one shared culture behind it.",
      ),
      // 2. Three writing systems overview
      LessonStep(
        kickerPlain: 'WELCOME TO',
        kickerHighlight: 'JAPANESE',
        before: (dark) => lessonRow([
          lessonCol([Text('ひらがな', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kLessonHiraganaColor))]),
          const SizedBox(width: 14),
          lessonCol([Text('カタカナ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kLessonKatakanaColor))]),
          const SizedBox(width: 14),
          withFurigana('かんじ', '漢字', dark, wordSize: 26, wordColor: kLessonPurple),
        ]),
        question: 'Japanese text actually mixes three different writing systems together. Which one do you think this course starts with?',
        options: const ['Hiragana', 'Katakana', 'Kanji'],
        correctIndex: 0,
        after: (dark) => lessonCol([
          Text('ひらがな', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kLessonHiraganaColor)),
          const SizedBox(height: 6),
          Text('Native words & grammar endings', style: lessonBodyStyle(dark, size: 13, weight: FontWeight.w500)),
        ]),
        explanation: "Hiragana is the foundation everything else is built on - every single Japanese sound can be "
            "written in it, and it's how children in Japan learn to read and write first. Katakana (for foreign "
            "words) and kanji (for core meanings) both come later in your journey - hiragana is where every "
            "learner starts.",
      ),
      // 3. What hiragana actually is
      LessonStep(
        kickerPlain: 'WELCOME TO',
        kickerHighlight: 'JAPANESE',
        before: (dark) => Text('あ　い　う　え　お', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: "Unlike English letters, what does each hiragana character represent?",
        options: const ['A single letter sound, like B or C', 'A whole syllable, like "ka" or "shi"', 'A whole word'],
        correctIndex: 1,
        after: (dark) => Text(
          'か = "ka"　　し = "shi"　　ん = "n"',
          textAlign: TextAlign.center,
          style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w600),
        ),
        explanation: "Hiragana is a syllabary, not an alphabet - each character is a whole syllable rather than a "
            "single sound. There are 46 basic characters in total, and once you know them all, you can read any "
            "hiragana word out loud, even ones you don't yet know the meaning of.",
      ),
      // 4. Transition into today's hiragana (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('ひらがな', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: kLessonPurple,
            child: const Text('DAY 1 · HIRAGANA CHALLENGE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ]),
        explanation: "Let's meet your first hiragana: あ, い, う, え, お - the five vowel sounds - and か, き, く, "
            "け, こ, the five k-sounds built from them.",
      ),
    ],
  ),
  Lesson(
    trackId: kHiraganaTrackId,
    day: 2,
    endOfDay: 1,
    title: 'Build Your First Sentences',
    introSubtitle: "A fun, low-pressure creative activity to cap off Day 1 - no quiz this time, just a chance to "
        "play with what you already know before さ, し, す, せ, そ and more come next.",
    activityBuilder: (context, isDarkMode, onDone) => SkoolActivityScreen(
      isDarkMode: isDarkMode,
      onDone: onDone,
      kicker: 'DAY 1 CHALLENGE',
      title: 'Build 3 Sentences',
      instructions: "Fill in the blank with any word you already know - romaji, hiragana, or kanji, whatever "
          "you're comfortable with. There's no wrong answer here, just have a go!",
      prompts: const [
        SkoolPrompt(after: '　を　たべる', hint: 'taberu - to eat'),
        SkoolPrompt(after: '　に　いく', hint: 'iku - to go'),
        SkoolPrompt(after: '　を　みる', hint: 'miru - to watch / see'),
      ],
    ),
  ),
  Lesson(
    trackId: kHiraganaTrackId,
    day: 7,
    endOfDay: 6,
    title: 'Introduce Yourself',
    introSubtitle: "Your first real conversation phrases - how to greet someone new and say a little about "
        "yourself. These flashcards start right at the top of today's session.",
    steps: [
      // 1. はじめまして
      LessonStep(
        kickerPlain: 'INTRODUCE',
        kickerHighlight: 'YOURSELF',
        before: (dark) => Text('はじめまして', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: "When do you think you'd say this phrase?",
        options: const ['Only the first time you meet someone', 'Every time you say hello', 'When you say goodbye'],
        correctIndex: 0,
        after: (dark) => Text(
          'hajimemashite - "Nice to meet you" / "How do you do"',
          textAlign: TextAlign.center,
          style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600),
        ),
        explanation: "はじめまして (hajimemashite) is only ever used the very first time you meet someone - never "
            "again after that, even the next time you see the same person.",
      ),
      // 2. よろしく
      LessonStep(
        kickerPlain: 'INTRODUCE',
        kickerHighlight: 'YOURSELF',
        before: (dark) => Text('よろしく', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'よろしく is short for よろしくお願いします. What do you think it roughly means here?',
        options: const ['"Pleased to meet you" / "Please treat me well"', '"See you later"', '"I\'m sorry"'],
        correctIndex: 0,
        after: (dark) => Text(
          'yoroshiku - said right after introducing yourself',
          textAlign: TextAlign.center,
          style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600),
        ),
        explanation: "はじめまして and よろしく usually go together as a pair - はじめまして first, then a bit about "
            "yourself, then よろしく to close it off.",
      ),
      // 3. しゅみ
      LessonStep(
        kickerPlain: 'INTRODUCE',
        kickerHighlight: 'YOURSELF',
        before: (dark) => Text('しゅみ（趣味）', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'What do you think しゅみ means?',
        options: const ['Hobby', 'Name', 'Job'],
        correctIndex: 0,
        after: (dark) => Text('しゅみは＿です　-　"My hobby is ___"', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w600)),
        explanation: "しゅみ (shumi) means hobby. Slot any word you know into しゅみは＿です and you've got a real "
            "sentence about yourself - です just means \"is\".",
      ),
      // 4. Transition into the activity (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('はじめまして！', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        explanation: "Time to put it together - introduce yourself using what you just learned!",
      ),
    ],
    activityBuilder: (context, isDarkMode, onDone) => SkoolActivityScreen(
      isDarkMode: isDarkMode,
      onDone: onDone,
      kicker: 'INTRODUCE YOURSELF',
      title: 'Your Self-Introduction',
      instructions: "Fill in the blanks to introduce yourself - any script is fine, just have a go!",
      resultsHeading: 'Great introduction!',
      prompts: const [
        SkoolPrompt(before: 'はじめまして。', after: 'です。', hint: "Your name - e.g. Lloyd, ロイド, たろう"),
        SkoolPrompt(before: 'しゅみは', after: 'です。よろしく！', hint: "Your hobby - e.g. サッカー, ゲーム, おんがく"),
      ],
    ),
  ),
  Lesson(
    trackId: kHiraganaTrackId,
    day: 8,
    endOfDay: 7,
    title: 'Greetings & Basic Conversation',
    introSubtitle: "Everyday greetings for any time of day, plus how to ask someone how they're doing. These "
        "flashcards start right at the top of today's session.",
    steps: [
      // 1. Three greetings
      LessonStep(
        kickerPlain: 'GREETINGS &',
        kickerHighlight: 'CONVERSATION',
        before: (dark) => lessonCol([
          Text('おはようございます', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 6),
          Text('こんにちは', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 6),
          Text('こんばんは', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: 'Which of these three greetings do you think is used in the morning?',
        options: const ['おはようございます', 'こんにちは', 'こんばんは'],
        correctIndex: 0,
        after: (dark) => lessonCol([
          Text('おはようございます - good morning (polite)', style: lessonBodyStyle(dark, size: 14, weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('こんにちは - hello / good afternoon', style: lessonBodyStyle(dark, size: 14, weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('こんばんは - good evening', style: lessonBodyStyle(dark, size: 14, weight: FontWeight.w600)),
        ]),
        explanation: "Japanese greetings change with the time of day - おはようございます for morning, こんにちは "
            "for daytime, and こんばんは once evening comes around.",
      ),
      // 2. です recap
      LessonStep(
        kickerPlain: 'GREETINGS &',
        kickerHighlight: 'CONVERSATION',
        before: (dark) => Text('げんき　です', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'What job does です do in a sentence?',
        options: const ['It means "is / am / are"', 'It means "not"', 'It\'s a question mark'],
        correctIndex: 0,
        after: (dark) => Text('げんき (genki) + です = "healthy" / "I\'m well"', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "です (desu) is one of the most common words in Japanese - it links a word to the sentence, "
            "roughly like \"is/am/are\" in English.",
      ),
      // 3. Breaking down おげんきですか
      LessonStep(
        kickerPlain: 'GREETINGS &',
        kickerHighlight: 'CONVERSATION',
        before: (dark) => Text('お　げんき　です　か', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'か is added to the very end of a sentence. What do you think it does?',
        options: const ['Turns it into a question', 'Makes it past tense', 'Makes it negative'],
        correctIndex: 0,
        after: (dark) => lessonCol([
          Text('お + げんき + です + か', style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('= おげんきですか　-　"How are you?"', style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w700)),
        ]),
        explanation: "か (ka) at the end of a sentence turns it into a question - です becomes ですか, no word "
            "order changes needed, unlike English. お is just a polite prefix here.",
      ),
      // 4. 大丈夫
      LessonStep(
        kickerPlain: 'GREETINGS &',
        kickerHighlight: 'CONVERSATION',
        before: (dark) => Text('だいじょうぶ（大丈夫）', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'だいじょうぶですか is another way to check in on someone. What does 大丈夫 mean?',
        options: const ['Okay / alright / fine', 'Tired', 'Hungry'],
        correctIndex: 0,
        after: (dark) => Text('大丈夫ですか？　-　大丈夫です！', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 18, weight: FontWeight.w700)),
        explanation: "大丈夫 (daijoubu) works just like 元気 did - add ですか to ask \"are you okay?\", or です to "
            "answer \"I'm okay\".",
      ),
      // 5. Transition into the activity (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('こんにちは！', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        explanation: "Let's practice a real greeting exchange with what you just learned.",
      ),
    ],
    activityBuilder: (context, isDarkMode, onDone) => SkoolActivityScreen(
      isDarkMode: isDarkMode,
      onDone: onDone,
      kicker: 'GREETINGS & CONVERSATION',
      title: 'Practice a Greeting',
      instructions: "Write out a short greeting exchange using today's phrases - any script is fine, just have a go!",
      resultsHeading: 'Nicely greeted!',
      prompts: const [
        SkoolPrompt(hint: "Write a greeting for right now (morning/afternoon/evening) - おはようございます, こんにちは, or こんばんは"),
        SkoolPrompt(hint: "Someone asks 元気ですか？(how are you?) - answer with げんきです or だいじょうぶです"),
      ],
    ),
  ),
  Lesson(
    trackId: kHiraganaTrackId,
    // Just a unique bookkeeping number - never shown anywhere (the title,
    // closing screen, and lessons-tab gating all read endOfDay instead once
    // it's set). Kept distinct from day 9 so "Introducing Katakana" below
    // can legitimately own day 9 as an ordinary, start-of-day-9 lesson.
    day: 11,
    endOfDay: 8,
    title: 'Me, My Name Is...',
    introSubtitle: "Talking about yourself in more detail - who you are and what belongs to you. These flashcards "
        "start right at the top of today's session.",
    steps: [
      // 1. 私 vs 僕
      LessonStep(
        kickerPlain: 'ME, MY NAME',
        kickerHighlight: 'IS...',
        before: (dark) => lessonRow([
          withFurigana('わたし', '私', dark, wordSize: 40),
          const SizedBox(width: 20),
          withFurigana('ぼく', '僕', dark, wordSize: 40),
        ]),
        question: '私 (watashi) and 僕 (boku) both mean "I / me". What\'s the difference?',
        options: const ['僕 is typically used by males, 私 works for anyone', 'They mean completely different things', 'Only 私 is correct'],
        correctIndex: 0,
        after: (dark) => Text('わたし (私)　·　ぼく (僕)', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 18, weight: FontWeight.w700)),
        explanation: "私 (watashi) is neutral and safe for anyone to use; 僕 (boku) is a more casual "
            "\"I\" typically used by males.",
      ),
      // 2. 名前 / 何
      LessonStep(
        kickerPlain: 'ME, MY NAME',
        kickerHighlight: 'IS...',
        before: (dark) => lessonRow([
          withFurigana('なまえ', '名前', dark, wordSize: 32),
          const SizedBox(width: 16),
          withFurigana('なに', '何', dark, wordSize: 32),
        ]),
        question: '名前は何ですか literally asks about your name. What does 何 mean on its own?',
        options: const ['What', 'Who', 'Where'],
        correctIndex: 0,
        after: (dark) => Text('名前 (namae) = name　·　何 (nani) = what', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "名前は何ですか (namae wa nan desu ka) literally reads \"as for [your] name, what is it?\" - "
            "です recap: です still just means \"is\", and か still turns it into a question.",
      ),
      // 3. 私の
      LessonStep(
        kickerPlain: 'ME, MY NAME',
        kickerHighlight: 'IS...',
        before: (dark) => withFurigana('わたしの', '私の', dark, wordSize: 36),
        question: 'の attaches to 私 to make 私の. What do you think it means?',
        options: const ['"My"', '"You"', '"Not"'],
        correctIndex: 0,
        after: (dark) => lessonCol([
          lessonRow([
            withFurigana('わたしのしゅみ', '私の趣味', dark, wordSize: 22),
            const SizedBox(width: 8),
            Text('-　my hobby', style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          lessonRow([
            withFurigana('わたしのなまえ', '私の名前', dark, wordSize: 22),
            const SizedBox(width: 8),
            Text('-　my name', style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w600)),
          ]),
        ]),
        explanation: "の (no) is a possessive particle - stick it after 私 to get 私の, \"my\", then attach any "
            "noun you like: 私の趣味 (my hobby), 私の名前 (my name), and so on.",
      ),
      // 4. Transition into the activity (no question)
      LessonStep(
        before: (dark) => withFurigana('わたしのなまえは…', '私の名前は…', dark, wordSize: 32),
        explanation: "One more round of self-introduction practice, this time with わたしの (私の).",
      ),
    ],
    activityBuilder: (context, isDarkMode, onDone) => SkoolActivityScreen(
      isDarkMode: isDarkMode,
      onDone: onDone,
      kicker: 'ME, MY NAME IS...',
      title: 'My Name Is...',
      instructions: "Fill in the blanks using わたしの (私の) - any script is fine, just have a go!",
      resultsHeading: 'Well introduced!',
      prompts: const [
        SkoolPrompt(before: 'わたしのなまえは', after: 'です。', hint: "Your name - e.g. Lloyd, ロイド"),
        SkoolPrompt(before: 'わたしのしゅみは', after: 'です。', hint: "Your hobby again - e.g. サッカー, ゲーム"),
      ],
    ),
  ),
  Lesson(
    trackId: kHiraganaTrackId,
    // An ordinary day-9 lesson (no endOfDay) - unlike the end-of-day-N
    // lessons above, this is genuinely day 9's own content, so it triggers
    // the normal way: when day 9 itself actually begins (either the real
    // calendar day arriving, or "Learn Day 9 Now" from the previous day's
    // summary screen), never chained onto day 8's finish.
    day: 9,
    title: 'Introducing Katakana',
    introSubtitle: "A second script for a second job - what katakana is for, and why it's easier than it looks. "
        "These flashcards start right at the top of today's session.",
    steps: [
      // 1. What katakana is for
      LessonStep(
        kickerPlain: 'INTRODUCING',
        kickerHighlight: 'KATAKANA',
        before: (dark) => lessonRow([
          Text('ア', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: kLessonKatakanaColor)),
          const SizedBox(width: 20),
          Text('あ', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: kLessonHiraganaColor)),
        ]),
        question: 'What do you think katakana is mainly used for?',
        options: const ['Foreign loanwords, names & emphasis', 'Native Japanese grammar endings', 'Numbers and counting'],
        correctIndex: 0,
        after: (dark) => Text(
          'カタカナ (katakana) - the "other" phonetic script',
          textAlign: TextAlign.center,
          style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600),
        ),
        explanation: "Katakana covers the same sounds as hiragana, just in different-looking characters - it's "
            "mainly reserved for words borrowed from other languages, foreign names, and the occasional bit of "
            "emphasis (a bit like italics in English).",
      ),
      // 2. Examples of loanwords
      LessonStep(
        kickerPlain: 'INTRODUCING',
        kickerHighlight: 'KATAKANA',
        before: (dark) => lessonCol([
          Text('ピザ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text('コーヒー', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: 'Which languages do you think ピザ (piza) and コーヒー (koohii) were borrowed from?',
        options: const ['English - "pizza" and "coffee"', 'They\'re original Japanese words', 'Chinese'],
        correctIndex: 0,
        after: (dark) => Text(
          'ピザ = pizza　　コーヒー = coffee',
          textAlign: TextAlign.center,
          style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w600),
        ),
        explanation: "The moment you see katakana, you can usually guess a word is borrowed from another language "
            "- often you can sound it out and hear the original English word hiding inside.",
      ),
      // 3. Same sound, different script
      LessonStep(
        kickerPlain: 'INTRODUCING',
        kickerHighlight: 'KATAKANA',
        before: (dark) => lessonRow([
          Text('ア', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: kLessonKatakanaColor)),
          const SizedBox(width: 16),
          Icon(Icons.compare_arrows, color: kLessonPurple, size: 26),
          const SizedBox(width: 16),
          Text('あ', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: kLessonHiraganaColor)),
        ]),
        question: 'ア and あ are both read "a". Are you learning a brand new sound here?',
        options: const ['No - same sound, just a new shape for it', 'Yes, a completely new sound'],
        correctIndex: 0,
        after: (dark) => Text(
          "Every katakana character has a hiragana twin with the exact same sound.",
          textAlign: TextAlign.center,
          style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600),
        ),
        explanation: "This is the good news about katakana: you already know every sound in it from hiragana. "
            "You're just learning new shapes to write sounds you can already say - each new character will show "
            "you its hiragana match for comparison as you go.",
      ),
      // 4. Transition into today's katakana (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('カタカナ', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: kLessonPurple,
            child: const Text('DAY 9 · KATAKANA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ]),
        explanation: "Let's meet your first katakana: ア, イ, ウ, エ, オ - the five vowel sounds - and カ, キ, ク, "
            "ケ, コ, the five k-sounds built from them. Sound familiar? That's the idea!",
      ),
    ],
  ),
  Lesson(
    trackId: kHiraganaTrackId,
    day: 17,
    title: 'Small や, ゆ, よ',
    introSubtitle: "A quick one today - no new flashcards, just a look at how kana combine to make new sounds. "
        "Take your time with this one; it'll click once real words start using it.",
    steps: [
      // 1. What small ya/yu/yo do
      LessonStep(
        kickerPlain: 'SMALL',
        kickerHighlight: 'や・ゆ・よ',
        before: (dark) => Text('や　ゆ　よ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'These same three kana also come in a small size: ゃ ゅ ょ. What do you think that small size means?',
        options: const ['They combine with another kana to blend into one new sound', 'Nothing - just a smaller font', 'They make the sentence a question'],
        correctIndex: 0,
        after: (dark) => Text(
          'や・ゆ・よ (full size)　vs　ゃ・ゅ・ょ (small)',
          textAlign: TextAlign.center,
          style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600),
        ),
        explanation: "Written small and tucked right after certain kana (き, し, ち, に, ひ, み, り and their "
            "dakuten versions), ゃ/ゅ/ょ fuse the two into a single blended syllable - these combinations are "
            "called youon.",
      ),
      // 2. One syllable, not two
      LessonStep(
        kickerPlain: 'SMALL',
        kickerHighlight: 'や・ゆ・よ',
        before: (dark) => Text('き　＋　ゃ　＝　きゃ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'How many syllables/beats is きゃ (kya) pronounced as?',
        options: const ['One - "kya"', 'Two - "ki" then "ya"'],
        correctIndex: 0,
        after: (dark) => Text('きゃ = "kya" (one beat)', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w700)),
        explanation: "Combined kana like this are always pronounced as one single beat, never as two separate "
            "sounds - き and ゃ blend into exactly one syllable.",
      ),
      // 3. Reference chart (no question)
      LessonStep(
        kickerPlain: 'SMALL',
        kickerHighlight: 'や・ゆ・よ',
        before: (dark) => youonChart(dark),
        explanation: "Here's the full set for reference - you don't need to memorize this chart right now, just "
            "know it exists. You'll naturally pick these up as real words introduce them.",
      ),
      // 4. Katakana note
      LessonStep(
        kickerPlain: 'SMALL',
        kickerHighlight: 'や・ゆ・よ',
        before: (dark) => Text('キャンプ', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'キャンプ (kyanpu) uses a small ャ. What do you think it borrows from English?',
        options: const ['"Camp"', '"Cat"', '"Cap"'],
        correctIndex: 0,
        after: (dark) => Text('キャンプ = camp', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w600)),
        explanation: "Katakana has the exact same small ャ/ュ/ョ combinations, and they show up constantly in "
            "loanwords - キャ, シャ, チョ, and so on.",
      ),
      // 5. Closing (no question) + optional video
      LessonStep(
        before: (dark) => lessonCol([
          Text('ゃ・ゅ・ょ', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 16),
          skoolVideoLink('https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=2570e6d7da834d0daf76b44c7dca5f00'),
        ]),
        explanation: "No flashcards today - just let this sink in. You'll meet these combinations naturally as "
            "you keep going.",
      ),
    ],
  ),
  Lesson(
    trackId: kHiraganaTrackId,
    day: 18,
    title: 'Small っ and ー',
    introSubtitle: "Two more quick building blocks - no new flashcards today either, just two symbols you'll see "
        "everywhere once real words start appearing.",
    steps: [
      // 1. Small tsu doubles the consonant
      LessonStep(
        kickerPlain: 'SMALL',
        kickerHighlight: 'っ・ッ',
        before: (dark) => Text('がっこう', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'What do you think the small っ in がっこう (school) does?',
        options: const ['Briefly holds/doubles the next consonant sound', 'Makes the word negative', "It's silent and does nothing"],
        correctIndex: 0,
        after: (dark) => Text('がっこう = "ga-kkou", not "ga-kou"', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "A small っ (sokuon) creates a tiny pause before the next consonant, effectively doubling it "
            "- it's never pronounced on its own.",
      ),
      // 2. Katakana version
      LessonStep(
        kickerPlain: 'SMALL',
        kickerHighlight: 'っ・ッ',
        before: (dark) => Text('サッカー', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'Katakana has a small ッ too, working exactly the same way. What sport do you think サッカー (sakkaa) is?',
        options: const ['Soccer', 'Basketball', 'Tennis'],
        correctIndex: 0,
        after: (dark) => Text('サッカー = soccer', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w600)),
        explanation: "Small っ/ッ look identical in shape to the full-size つ/ツ, just noticeably smaller and "
            "shifted slightly - that's the only visual difference.",
      ),
      // 3. The long vowel mark ー
      LessonStep(
        kickerPlain: 'SMALL',
        kickerHighlight: 'っ・ッ',
        before: (dark) => Text('コーヒー', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'What do you think the ー mark does in katakana words like コーヒー?',
        options: const ['Stretches/holds the vowel sound right before it', "It's the number 1", 'Marks a small tsu'],
        correctIndex: 0,
        after: (dark) => Text('コーヒー = "ko-o-hii" (koohii)', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w600)),
        explanation: "ー (chōonpu) simply extends the vowel sound right before it - it only appears in katakana; "
            "hiragana stretches vowels by writing the actual vowel again instead (e.g. おかあさん).",
      ),
      // 4. Telling them apart (no question)
      LessonStep(
        kickerPlain: 'SMALL',
        kickerHighlight: 'っ・ッ',
        before: (dark) => lessonRow([
          lessonCol([
            Text('ー', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
            Text('long vowel', style: lessonBodyStyle(dark, size: 11, weight: FontWeight.w500)),
          ]),
          const SizedBox(width: 20),
          lessonCol([
            Text('1', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
            Text('the number one', style: lessonBodyStyle(dark, size: 11, weight: FontWeight.w500)),
          ]),
          const SizedBox(width: 20),
          lessonCol([
            Text('っ', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
            Text('small tsu', style: lessonBodyStyle(dark, size: 11, weight: FontWeight.w500)),
          ]),
        ]),
        explanation: "Easy to mix up at a glance, but each is distinct: ー is a plain dash that only ever appears "
            "inside a katakana word; 1 is a number, never mixed in with kana; っ (or katakana ッ) is a small, "
            "tsu-shaped character, not a straight line at all.",
      ),
      // 5. Closing (no question) + optional video
      LessonStep(
        before: (dark) => lessonCol([
          Text('っ・ー', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 16),
          skoolVideoLink('https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=db9359bf6dd54f2da1d8c88b79fa5c4c'),
        ]),
        explanation: "No flashcards today either - both of these will show up constantly once we get to real "
            "words, so just get familiar with the idea. Tomorrow you'll drill a few real words that use small っ.",
      ),
    ],
  ),
  Lesson(
    day: 1,
    title: 'Kanji Essentials',
    introSubtitle: "A quick, friendly primer on how Japanese writing works, before we meet today's kanji.",
    steps: [
      // 1. Three systems overview
      LessonStep(
        kickerPlain: 'THE JAPANESE',
        kickerHighlight: 'WRITING SYSTEM',
        before: (dark) => lessonRow([
          lessonCol([Text('ひらがな', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kLessonHiraganaColor))]),
          const SizedBox(width: 20),
          lessonCol([Text('カタカナ', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kLessonKatakanaColor))]),
          const SizedBox(width: 20),
          lessonCol([Text('漢字', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kLessonPurple))]),
        ]),
        question: 'Which of these do you think is used for foreign words like pizza or coffee?',
        options: const ['ひらがな', 'カタカナ', '漢字'],
        correctIndex: 1,
        after: (dark) => lessonRow([
          lessonCol([
            Text('ひらがな', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kLessonHiraganaColor)),
            const SizedBox(height: 4),
            SizedBox(width: 92, child: Text('Native words &\ngrammar endings', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 12, weight: FontWeight.w500))),
          ]),
          const SizedBox(width: 14),
          lessonCol([
            Text('カタカナ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kLessonKatakanaColor)),
            const SizedBox(height: 4),
            SizedBox(width: 92, child: Text('Foreign words,\nnames & emphasis', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 12, weight: FontWeight.w500))),
          ]),
          const SizedBox(width: 14),
          lessonCol([
            Text('漢字', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kLessonPurple)),
            const SizedBox(height: 4),
            SizedBox(width: 92, child: Text('Core meanings,\ntaken from China', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 12, weight: FontWeight.w500))),
          ]),
        ]),
        explanation: "Japanese text mixes all three together in the same sentence - you're about to see how.",
      ),
      // 2. 食べる breakdown
      LessonStep(
        kickerPlain: 'THE JAPANESE',
        kickerHighlight: 'WRITING SYSTEM',
        before: (dark) => Text('食べる', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'Which part do you think changes depending on tense or politeness?',
        options: const ['食', 'べる'],
        correctIndex: 1,
        after: (dark) => lessonRow([
          labeledChar('食', 'kanji', kLessonPurple),
          const SizedBox(width: 10),
          labeledChar('べる', 'hiragana', kLessonHiraganaColor),
        ]),
        explanation: "The kanji carries the core meaning (eat); the hiragana ending changes with tense and politeness "
            "- 食べた (ate), 食べます (eat, polite), and so on.",
      ),
      // 3. Furigana
      LessonStep(
        kickerPlain: 'THE JAPANESE',
        kickerHighlight: 'WRITING SYSTEM',
        before: (dark) => Text('可愛い', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'What do you think small hiragana written above a kanji is for?',
        options: const ['Shows the meaning', 'Shows how to say it', "It's just decoration"],
        correctIndex: 1,
        after: (dark) => withFurigana('かわいい', '可愛い', dark, wordSize: 44),
        explanation: "It's called furigana, and it simply shows how to pronounce the kanji next to it - handy for "
            "rare readings, or for learners.",
      ),
      // 4. Katakana loanwords
      LessonStep(
        kickerPlain: 'THE JAPANESE',
        kickerHighlight: 'WRITING SYSTEM',
        before: (dark) => lessonRow([
          Text('すし', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(width: 24),
          Text('ピザ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: 'Which of these do you think is originally a Japanese word?',
        options: const ['すし (sushi)', 'ピザ (pizza)'],
        correctIndex: 0,
        after: (dark) => Text('ピザ　コーヒー　ビル', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kLessonKatakanaColor)),
        explanation: "Loanwords from other languages are written in katakana - even ones that don't look foreign "
            "at first, like アベック (from French 'avec') or アルバイト (from German 'Arbeit').",
      ),
      // 5. Katakana names/emphasis
      LessonStep(
        kickerPlain: 'THE JAPANESE',
        kickerHighlight: 'WRITING SYSTEM',
        before: (dark) => Text('Lloyd, Cameron...', style: lessonBodyStyle(dark, size: 22)),
        question: 'Do you think foreign names are written in kanji, hiragana, or katakana?',
        options: const ['Kanji', 'Hiragana', 'Katakana'],
        correctIndex: 2,
        after: (dark) => Text('ロイド　カメロン', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kLessonKatakanaColor)),
        explanation: "Foreign names too. Katakana can also add emphasis to a native word, similar to italics or "
            "ALL CAPS in English.",
      ),
      // 6. All three systems in one word
      LessonStep(
        kickerPlain: 'THE JAPANESE',
        kickerHighlight: 'WRITING SYSTEM',
        before: (dark) => Text('消しゴム', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'Tap the part you think is katakana.',
        options: const ['消', 'し', 'ゴム'],
        correctIndex: 2,
        after: (dark) => lessonRow([
          labeledChar('消', 'kanji', kLessonPurple),
          const SizedBox(width: 6),
          labeledChar('し', 'hiragana', kLessonHiraganaColor),
          const SizedBox(width: 6),
          labeledChar('ゴム', 'katakana', kLessonKatakanaColor),
        ]),
        explanation: "消 (kanji) means 'erase', し is a hiragana grammar link, and ゴム (katakana) comes from the "
            "Dutch word for rubber, 'gom'. Three systems, one everyday word: eraser.",
      ),
      // 7. Readability
      LessonStep(
        kickerPlain: 'THE JAPANESE',
        kickerHighlight: 'WRITING SYSTEM',
        before: (dark) => Text('Which is easier to read?', style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w600)),
        question: 'Which sentence do you think is easier to scan at a glance?',
        options: const ['寿司を食べるのが好きです。', 'すしをたべるのがすきです。'],
        correctIndex: 0,
        after: (dark) => lessonCol([
          Text('寿司を食べるのが好きです。', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 14),
          Text('すしをたべるのがすきです。', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: dark ? Colors.white54 : Colors.black45)),
        ]),
        explanation: "Kanji breaks a sentence into meaningful chunks, a bit like the spaces between English words - "
            "the all-hiragana version is technically correct, just much harder to scan.",
      ),
      // 8. History / simplification
      LessonStep(
        kickerPlain: 'THE JAPANESE',
        kickerHighlight: 'WRITING SYSTEM',
        before: (dark) => Text('賣  /  売', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'Which do you think is the modern, simplified form?',
        options: const ['賣', '売'],
        correctIndex: 1,
        after: (dark) => lessonRow([
          lessonCol([
            Text('賣', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
            Text('旧字体', style: lessonBodyStyle(dark, size: 13, weight: FontWeight.w500)),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(Icons.arrow_forward, size: 28, color: dark ? Colors.white54 : Colors.black45),
          ),
          lessonCol([
            Text('売', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
            Text('新字体', style: lessonBodyStyle(dark, size: 13, weight: FontWeight.w500)),
          ]),
        ]),
        explanation: "Kanji were originally taken from China. After WWII, Japan simplified thousands of complex "
            "kanji to make them faster to write - the old forms (旧字体) now mostly show up in names and old texts.",
      ),
      // 9. Transition into today's kanji (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('漢字', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: kLessonPurple,
            child: const Text('DAY 1 · 90 DAY CHALLENGE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ]),
        explanation: "Now let's meet today's kanji: 日, 王, 玉, 口, 人, 入, 火 and more!",
      ),
    ],
  ),
  Lesson(
    // Just a unique bookkeeping number, past the challenge's real 90 days so
    // it can never collide with a genuine future day lesson - never shown
    // anywhere (endOfDay drives the title, closing screen, and gating).
    day: 91,
    endOfDay: 1,
    title: 'Introduce Yourself',
    introSubtitle: "A quick break from kanji to put 言 (the one you just met today) to use - how to introduce "
        "yourself in Japanese.",
    steps: [
      // 1. Greetings recap
      LessonStep(
        kickerPlain: 'INTRODUCE',
        kickerHighlight: 'YOURSELF',
        before: (dark) => lessonCol([
          Text('はじめまして', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text('こんにちは', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: 'はじめまして and こんにちは can both open an introduction. When specifically is はじめまして used?',
        options: const ['Only the first time you meet someone', 'Any time you say hello', 'Only when saying goodbye'],
        correctIndex: 0,
        after: (dark) => Text(
          'はじめまして - "nice to meet you"　·　こんにちは - "hello"',
          textAlign: TextAlign.center,
          style: lessonBodyStyle(dark, size: 14, weight: FontWeight.w600),
        ),
        explanation: "Either works to open a self-introduction - はじめまして if it's genuinely the first time you're "
            "meeting someone, こんにちは as a general hello any time.",
      ),
      // 2. 言う
      LessonStep(
        kickerPlain: 'INTRODUCE',
        kickerHighlight: 'YOURSELF',
        before: (dark) => withFurigana('いう', '言う', dark, wordSize: 40),
        question: "You just met 言 (say) today. What do you think 言う (iu) means as a whole word?",
        options: const ['To say', 'To eat', 'To go'],
        correctIndex: 0,
        after: (dark) => Text('言う (iu) = "to say"', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w700)),
        explanation: "言う (iu) literally means \"to say\". Attach it right after a name and you get \"[name] という\", "
            "literally \"is said as [name]\" - a common way to introduce yourself.",
      ),
      // 3. という / といいます formula
      LessonStep(
        kickerPlain: 'INTRODUCE',
        kickerHighlight: 'YOURSELF',
        before: (dark) => Text('［name］　と　いいます', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'といいます is the polite version of という. Which is more appropriate when meeting someone new?',
        options: const ['といいます (polite)', 'という (casual)'],
        correctIndex: 0,
        after: (dark) => lessonCol([
          Text('［name］という　-　casual', style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('［name］といいます　-　polite', style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        ]),
        explanation: "Slot your name in before either one: ロイドといいます (\"I'm called Lloyd\") is a safe, polite "
            "way to introduce yourself. Foreign names are usually written in katakana, even inside a Japanese "
            "sentence.",
      ),
      // 4. Transition into the activity (no question) + optional video
      LessonStep(
        before: (dark) => lessonCol([
          Text('はじめまして！', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 16),
          skoolVideoLink('https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=9c4f322efb4a4e74aee3a55446237a26'),
        ]),
        explanation: "Time to put it together - introduce yourself using what you just learned!",
      ),
    ],
    activityBuilder: (context, isDarkMode, onDone) => SkoolActivityScreen(
      isDarkMode: isDarkMode,
      onDone: onDone,
      kicker: 'INTRODUCE YOURSELF',
      title: 'Your Self-Introduction',
      instructions: "Fill in the blanks to introduce yourself - your name is best written in katakana, but any "
          "script is fine, just have a go!",
      resultsHeading: 'Great introduction!',
      prompts: const [
        SkoolPrompt(after: '。', hint: "Choose a greeting: はじめまして or こんにちは"),
        SkoolPrompt(after: 'といいます。', hint: "Your name - try it in katakana, e.g. ロイド"),
      ],
    ),
  ),
  Lesson(
    day: 2,
    title: 'Kanji Structure & Stroke Order',
    introSubtitle: "How kanji are built, and how to write them - a few ideas that'll help for the rest of the challenge.",
    steps: [
      // 1. Pictographs
      LessonStep(
        kickerPlain: 'KANJI STRUCTURE',
        kickerHighlight: 'AND STROKE ORDER',
        before: (dark) => lessonRow([
          Text('日', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(width: 16),
          Text('木', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(width: 16),
          Text('人', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: 'How do you think kanji like these first came about?',
        options: const ['As pictures of the real thing', 'As random shapes', 'Borrowed from the alphabet'],
        correctIndex: 0,
        after: (dark) => lessonCol([
          Text("日 = sun, 木 = tree, 人 = person", style: lessonBodyStyle(dark, size: 18, weight: FontWeight.w600)),
        ]),
        explanation: "These are pictographs - kanji that started as simple drawings of the thing they represent, "
            "then got simplified and squared off over thousands of years into the shapes we use today.",
      ),
      // 2. Radicals help with meaning
      LessonStep(
        kickerPlain: 'KANJI STRUCTURE',
        kickerHighlight: 'AND STROKE ORDER',
        before: (dark) => lessonRow([
          labeledChar('炎', 'flame', kLessonPurple),
          const SizedBox(width: 10),
          labeledChar('煙', 'smoke', kLessonPurple),
          const SizedBox(width: 10),
          labeledChar('燃', 'burn', kLessonPurple),
        ]),
        question: 'These all share a hidden piece related to one basic kanji. Which one?',
        options: const ['水 (water)', '火 (fire)', '木 (tree)'],
        correctIndex: 1,
        after: (dark) => Text(
          '火 → 炎・煙・燃',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black),
        ),
        explanation: "火 (fire) shows up inside all three, sometimes reshaped into 灬 (four little dots) at the "
            "bottom. Spotting a radical like this instantly tells you the kanji is probably fire or heat related "
            "- that's the first big reason radicals are useful.",
      ),
      // 3. Radicals help with reading
      LessonStep(
        kickerPlain: 'KANJI STRUCTURE',
        kickerHighlight: 'AND STROKE ORDER',
        before: (dark) => lessonRow([
          Text('儀', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(width: 14),
          Text('犠', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(width: 14),
          Text('議', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: '儀, 犠, and 議 all share a component (義) that hints at their reading. Which reading do you think they share?',
        options: const ['gi', 'ka', 'ren'],
        correctIndex: 0,
        after: (dark) => Text(
          '儀 (ぎ)　犠 (ぎ)　議 (ぎ)',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: dark ? Colors.white : Colors.black),
        ),
        explanation: "All three are read with ぎ (gi), inherited from the shared 義 component. This is the second "
            "reason radicals are useful - they can hint at the reading, not just the meaning.",
      ),
      // 4. Similar-looking kanji
      LessonStep(
        kickerPlain: 'KANJI STRUCTURE',
        kickerHighlight: 'AND STROKE ORDER',
        before: (dark) => lessonRow([
          Text('王', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(width: 20),
          Text('玉', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: 'King (王) and ball (玉) look almost identical. Can you spot the difference?',
        options: const ['A dot', 'An extra line across the top', "There isn't one"],
        correctIndex: 0,
        after: (dark) => lessonCol([
          Text('王 (king)　玉 (ball)', style: lessonBodyStyle(dark, size: 20)),
          const SizedBox(height: 14),
          Text('人 (person)　入 (enter)', style: lessonBodyStyle(dark, size: 20)),
        ]),
        explanation: "玉 has a tiny extra dot that 王 doesn't. Kanji like these - and 人 vs 入 - are easy to mix up "
            "at a glance, so it pays to look closely at the small details.",
      ),
      // 5. Why stroke order matters
      LessonStep(
        kickerPlain: 'KANJI STRUCTURE',
        kickerHighlight: 'AND STROKE ORDER',
        before: (dark) => Text('書き順', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'Besides making your kanji look neater, why else do you think stroke order matters?',
        options: const ['It builds muscle memory, so writing becomes automatic', "It doesn't - it's just tradition", "It changes the kanji's meaning"],
        correctIndex: 0,
        after: (dark) => Text(
          "書き順 (kakijun) - stroke order",
          textAlign: TextAlign.center,
          style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w600),
        ),
        explanation: "Following the standard stroke order helps your kanji look right, and over time builds the "
            "same kind of muscle memory as learning to type - your hand starts to \"know\" the kanji.",
      ),
      // 6. Stroke order exceptions
      LessonStep(
        kickerPlain: 'KANJI STRUCTURE',
        kickerHighlight: 'AND STROKE ORDER',
        before: (dark) => lessonRow([
          Text('週', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(width: 20),
          Text('延', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: "These both have a 'walking' shape wrapping around the left and bottom. Drawn first or last?",
        options: const ['First', 'Last'],
        correctIndex: 1,
        after: (dark) => lessonCol([
          Text('週 (week)　延 (extend)', style: lessonBodyStyle(dark, size: 18)),
          const SizedBox(height: 10),
          Text(
            'kakijun.com is a great way to check stroke order for any kanji - you build intuition for it over time.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: dark ? Colors.white54 : Colors.black45),
          ),
        ]),
        explanation: "This is one of the main exceptions to the usual rules: that wrapping 'walking' radical (辶/廴) "
            "is drawn last, even though it looks like it should come first.",
      ),
      // 7. Transition into today's kanji (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('漢字', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: kLessonPurple,
            child: const Text('DAY 2 · 90 DAY CHALLENGE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ]),
        explanation: "Now let's meet today's kanji: 大, 力, 刀, 木, 水, 父, 田, 雨, 月, 女!",
      ),
      // 8. Start building vocabulary too (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('単語', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 14),
          Text(
            "You've got the building blocks down - why not start learning some real vocabulary too?",
            textAlign: TextAlign.center,
            style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w600),
          ),
        ]),
        after: (dark) => _StartVocabButton(isDarkMode: dark),
        explanation: "Kanji and vocabulary reinforce each other - the Essential Vocabulary Challenge introduces new "
            "words at your own pace alongside the kanji you're already learning here. Tap above whenever you're "
            "ready to begin (or just carry on with today's kanji for now).",
      ),
    ],
  ),
  Lesson(
    trackId: kEssentialVocabTrackId,
    day: 1,
    title: 'Learning Vocabulary Effectively',
    introSubtitle: "A quick primer on how to actually learn a word - not just recognize it - before we start building your Essential Vocabulary.",
    steps: [
      // 0. Reassurance about unfamiliar kanji (no question)
      LessonStep(
        kickerPlain: 'LEARNING VOCABULARY',
        kickerHighlight: 'EFFECTIVELY',
        before: (dark) => lessonCol([
          Text('新しい漢字？', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        explanation: "Some of these words use kanji you haven't learned yet - don't worry about that for now. "
            "They'll come naturally as you work through the 90 Day Kanji Challenge and get more immersed in the "
            "language. For today, just focus on the words themselves.",
      ),
      // 1. The parts of a vocab card
      LessonStep(
        kickerPlain: 'LEARNING VOCABULARY',
        kickerHighlight: 'EFFECTIVELY',
        before: (dark) => Text('必要', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'Which part of this word tells you HOW to say it out loud?',
        options: const ['The kanji itself', 'The kana reading above it', 'The English meaning'],
        correctIndex: 1,
        after: (dark) => lessonRow([
          withFurigana('ひつ', '必', dark, wordSize: 40),
          const SizedBox(width: 4),
          withFurigana('よう', '要', dark, wordSize: 40),
        ]),
        explanation: "必要 (ひつよう) means 'necessary'. A word has three things worth learning: what it means, "
            "how it's written (kanji/kana), and how it's pronounced.",
      ),
      // 2. The fourth aspect: context
      LessonStep(
        kickerPlain: 'LEARNING VOCABULARY',
        kickerHighlight: 'EFFECTIVELY',
        before: (dark) => Text('Aspects of learning vocabulary:', style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w600)),
        question: "Besides meaning, written form, and pronunciation, what's the fourth thing worth learning about a word?",
        options: const ['Its stroke count', 'The context you\'d use it in', 'Nothing else matters'],
        correctIndex: 1,
        after: (dark) => lessonCol([
          Text('1. Translation/meaning', style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('2. Written structure (kanji/kana)', style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('3. Pronunciation', style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('4. Context', style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w700)),
        ]),
        explanation: "Truly knowing a word means being solid on all four - not just being able to recognize its meaning "
            "when you see it.",
      ),
      // 3. Mnemonics for 私
      LessonStep(
        kickerPlain: 'LEARNING VOCABULARY',
        kickerHighlight: 'EFFECTIVELY',
        before: (dark) => Text('私', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'Can you guess how 私 (I/me) is read?',
        options: const ['わたし', 'ぼく', 'おれ'],
        correctIndex: 0,
        after: (dark) => withFurigana('わたし', '私', dark, wordSize: 44),
        explanation: "An invented memory aid: imagine yourself with a water mustache (わた- sounds like 'water'), or "
            "picture yourself as a tree (禾) thinking about something personal (ム) - private thoughts. A vivid, "
            "even silly image sticks far better than the word alone.",
      ),
      // 4. Context in action - formality register
      LessonStep(
        kickerPlain: 'LEARNING VOCABULARY',
        kickerHighlight: 'EFFECTIVELY',
        before: (dark) => lessonRow([
          Text('私', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(width: 14),
          Text('僕', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(width: 14),
          Text('俺', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: '私, 僕, and 俺 all mean "I/me" - so what actually differs between them?',
        options: const ['Formality and gender register', 'Nothing, they\'re identical', 'Their meaning'],
        correctIndex: 0,
        after: (dark) => lessonRow([
          lessonCol([Text('わたし', style: lessonBodyStyle(dark, size: 13)), Text('私', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)), Text('neutral', style: lessonBodyStyle(dark, size: 11, weight: FontWeight.w500))]),
          const SizedBox(width: 16),
          lessonCol([Text('ぼく', style: lessonBodyStyle(dark, size: 13)), Text('僕', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)), Text('masculine', style: lessonBodyStyle(dark, size: 11, weight: FontWeight.w500))]),
          const SizedBox(width: 16),
          lessonCol([Text('おれ', style: lessonBodyStyle(dark, size: 13)), Text('俺', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)), Text('very masculine', style: lessonBodyStyle(dark, size: 11, weight: FontWeight.w500))]),
        ]),
        explanation: "This is context in action - picking the right word for the social situation, not just knowing "
            "a dictionary meaning.",
      ),
      // 5. Literal vs natural translation
      LessonStep(
        kickerPlain: 'LEARNING VOCABULARY',
        kickerHighlight: 'EFFECTIVELY',
        before: (dark) => Text('私はロイドと言います。', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: dark ? Colors.white : Colors.black)),
        question: "A literal, word-for-word translation often sounds awkward in English. Is that a problem?",
        options: const ["No - it shows you what each word/particle is doing", "Yes, literal translations are useless", "It means the sentence is wrong"],
        correctIndex: 0,
        after: (dark) => lessonCol([
          Text('"My name is Lloyd."', style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Literally: "Speaking of me, Lloyd is what I\'m called."', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: dark ? Colors.white54 : Colors.black45)),
        ]),
        explanation: "Seeing a literal breakdown next to the natural translation helps you understand what each "
            "particle is doing - Tangorin is a great free resource for finding real example sentences like this.",
      ),
      // 6. Writing vs typing
      LessonStep(
        kickerPlain: 'LEARNING VOCABULARY',
        kickerHighlight: 'EFFECTIVELY',
        before: (dark) => Text('Writing vs typing', style: lessonBodyStyle(dark, size: 20)),
        question: 'Do you think writing a word out by hand teaches you something typing doesn\'t?',
        options: const ['Yes - it builds muscle memory for recall', 'No, they\'re the same'],
        correctIndex: 0,
        after: (dark) => const Icon(Icons.edit, size: 48, color: kLessonPurple),
        explanation: "Typing (or tapping a flashcard) is fast for daily review, but writing by hand builds a deeper, "
            "more physical kind of memory - that's what this app's Practice Writing and stroke-order tools are for.",
      ),
      // 7. Everyday exposure
      LessonStep(
        kickerPlain: 'LEARNING VOCABULARY',
        kickerHighlight: 'EFFECTIVELY',
        before: (dark) => Text('Everyday exposure', style: lessonBodyStyle(dark, size: 20)),
        question: 'Which do you think helps a word stick best in the long run?',
        options: const ['Flashcards alone', 'Flashcards plus real exposure (reading, listening, media)'],
        correctIndex: 1,
        after: (dark) => const Icon(Icons.menu_book, size: 48, color: kLessonPurple),
        explanation: "Meeting a word again naturally - in a story, a song, a sentence you're reading or listening to "
            "- reinforces it far more than drilling it in isolation. That's exactly what this app's Reading and "
            "Listening tabs are for.",
      ),
      // 8. Transition into flashcards (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('単語', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: kLessonPurple,
            child: const Text('ESSENTIAL VOCABULARY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ]),
        explanation: "Time to start building your Essential Vocabulary - keep all four aspects in mind as you go!",
      ),
    ],
  ),

  // Grammar deck, Section 2: Verb Fundamentals (see grammarSections in
  // grammar_data.dart). Unlike the particle-based days above, these three
  // teach a concept by example verb rather than a single fill-in-the-blank
  // form, so they're authored directly as ordinary step lessons rather than
  // through GrammarPoint - their example verbs still become cards, via
  // buildGrammarCards' _verbGroupExamples.
  Lesson(
    trackId: kGrammarTrackId,
    day: 19,
    title: '一段動詞 - Ichidan Verbs',
    introSubtitle: "The first of three verb groups. Every Ichidan verb changes the exact same way, no exceptions "
        "once you've spotted one.",
    steps: [
      // 1. What Ichidan verbs have in common
      LessonStep(
        kickerPlain: 'VERB GROUPS',
        kickerHighlight: 'ICHIDAN',
        before: (dark) => lessonCol([
          Text('食べる', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text('たべる - to eat', style: lessonBodyStyle(dark, size: 14, weight: FontWeight.w500)),
        ]),
        question: 'Every Ichidan verb ends in る. What comes right before that る in 食べる?',
        options: const ['An e-sound (be)', 'An i-sound', 'A consonant'],
        correctIndex: 0,
        after: (dark) => Text('た・べ・る　→　an "e" sound before る', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "一段動詞 (ichidan doushi) literally means \"one-step verb\". Every one of them has an e or i "
            "sound right before る, and they all conjugate the exact same way: just swap out the る.",
      ),
      // 2. More genuine examples
      LessonStep(
        kickerPlain: 'VERB GROUPS',
        kickerHighlight: 'ICHIDAN',
        before: (dark) => lessonRow([
          lessonCol([Text('生きる', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: dark ? Colors.white : Colors.black)), Text('いきる', style: lessonBodyStyle(dark, size: 12, weight: FontWeight.w500))]),
          const SizedBox(width: 16),
          lessonCol([Text('居る', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: dark ? Colors.white : Colors.black)), Text('いる', style: lessonBodyStyle(dark, size: 12, weight: FontWeight.w500))]),
          const SizedBox(width: 16),
          lessonCol([Text('寝る', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: dark ? Colors.white : Colors.black)), Text('ねる', style: lessonBodyStyle(dark, size: 12, weight: FontWeight.w500))]),
        ]),
        question: '生きる (to live), 居る (to exist), and 寝る (to sleep). Do they all have an e or i sound right before る?',
        options: const ['Yes - い, い, and え', 'No, only one of them does'],
        correctIndex: 0,
        after: (dark) => Text('いき・る　居(い)・る　ね・る', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "生きる (ikiru), 居る (iru), and 寝る (neru) are all genuine Ichidan verbs. い, い, and え are "
            "all fine i/e sounds right before る.",
      ),
      // 3. The trap: not every る verb like this is Ichidan
      LessonStep(
        kickerPlain: 'VERB GROUPS',
        kickerHighlight: 'ICHIDAN',
        before: (dark) => lessonCol([
          Text('走る', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text('はしる - to run', style: lessonBodyStyle(dark, size: 14, weight: FontWeight.w500)),
        ]),
        question: '走る (hashiru) has an i-sound right before る too. So is it an Ichidan verb?',
        options: const ["No - it's actually a Godan verb", 'Yes, it must be'],
        correctIndex: 0,
        after: (dark) => const Icon(Icons.warning_amber_rounded, size: 40, color: kLessonPurple),
        explanation: "Not every verb ending in an e/i sound + る is Ichidan. 走る (to run) looks exactly like one "
            "but is actually Godan. There's no shortcut that covers every verb; a few just have to be "
            "memorised as exceptions.",
      ),
      // 4. ます - polite present/future
      LessonStep(
        kickerPlain: 'VERB GROUPS',
        kickerHighlight: 'ICHIDAN',
        before: (dark) => lessonCol([
          Text('食べる　→　食べます', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: 'Every Ichidan verb makes its polite form the same way. Drop る, add ます. What does 食べます mean?',
        options: const ['I eat / will eat (polite)', 'I ate (polite)', "I don't eat (polite)"],
        correctIndex: 0,
        after: (dark) => Text('食べ・ます　-　just drop る, add ます', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "ます is the polite present/future ending. Every Ichidan verb takes it the exact same way, "
            "no exceptions.",
      ),
      // 5. ません - polite negative
      LessonStep(
        kickerPlain: 'VERB GROUPS',
        kickerHighlight: 'ICHIDAN',
        before: (dark) => lessonCol([
          Text('見る　→　見ません', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: '見る becomes 見ません in polite speech. What does it mean?',
        options: const ["I won't watch / don't watch (polite)", 'I watched (polite)', 'I want to watch'],
        correctIndex: 0,
        after: (dark) => Text('見・ません　-　drop る, add ません', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "ません is the polite negative, the opposite of ます, built the exact same way.",
      ),
      // 6. ました - polite past
      LessonStep(
        kickerPlain: 'VERB GROUPS',
        kickerHighlight: 'ICHIDAN',
        before: (dark) => lessonCol([
          Text('寝る　→　寝ました', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: '寝ました is the polite past of 寝る. What does it mean?',
        options: const ['I slept (polite)', "I won't sleep (polite)", 'I am sleeping (polite)'],
        correctIndex: 0,
        after: (dark) => Text('寝・ました　-　drop る, add ました', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "ました is the polite past. Swap ます for ました and you're done.",
      ),
      // 7. ませんでした - polite past negative
      LessonStep(
        kickerPlain: 'VERB GROUPS',
        kickerHighlight: 'ICHIDAN',
        before: (dark) => lessonCol([
          Text('起きる　→　起きませんでした', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: '起きませんでした is the polite past negative of 起きる. What does it mean?',
        options: const ["I didn't wake up (polite)", 'I woke up (polite)', 'I will wake up (polite)'],
        correctIndex: 0,
        after: (dark) => Text('起き・ませんでした　-　drop る, add ませんでした', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 13, weight: FontWeight.w600)),
        explanation: "ます, ません, ました, ませんでした are the present, negative, past, and past negative, all built "
            "the exact same way for every Ichidan verb: just drop る.",
      ),
      // 8. Preview of what's still to come (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('食べて・食べた・食べない...', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: dark ? Colors.white : Colors.black)),
        ]),
        explanation: "There's more to Ichidan verbs than ます forms: て (and/doing), た (did), ない (won't do), and "
            "plenty more are all on their way in later lessons.",
      ),
      // 9. Transition (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('一段動詞', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: kLessonPurple,
            child: const Text('ICHIDAN VERBS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ]),
        explanation: "Next up: Godan verbs, the group with five different ways their ending can change.",
      ),
    ],
  ),
  Lesson(
    trackId: kGrammarTrackId,
    day: 20,
    title: '五段動詞 - Godan Verbs',
    introSubtitle: "The second verb group. Godan verbs change in five different ways depending on how they end.",
    steps: [
      // 1. Intro
      LessonStep(
        kickerPlain: 'VERB GROUPS',
        kickerHighlight: 'GODAN',
        before: (dark) => lessonRow([
          lessonCol([Text('書く', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)), Text('かく', style: lessonBodyStyle(dark, size: 12, weight: FontWeight.w500))]),
          const SizedBox(width: 14),
          lessonCol([Text('読む', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)), Text('よむ', style: lessonBodyStyle(dark, size: 12, weight: FontWeight.w500))]),
          const SizedBox(width: 14),
          lessonCol([Text('買う', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)), Text('かう', style: lessonBodyStyle(dark, size: 12, weight: FontWeight.w500))]),
        ]),
        question: '書く (kaku), 読む (yomu), and 買う (kau) all end differently: く, む, う. Is that normal for Godan verbs?',
        options: const ['Yes - Godan verbs can end in several different sounds', 'No, they should all end the same way'],
        correctIndex: 0,
        after: (dark) => Text('五段動詞 - "five-step verb"', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "五段動詞 (godan doushi) means \"five-step verb\". Their ending changes in five different ways "
            "depending on the grammar, and unlike Ichidan verbs, that ending isn't always る. Most Japanese "
            "verbs are Godan.",
      ),
      // 2. The exception that looks Ichidan
      LessonStep(
        kickerPlain: 'VERB GROUPS',
        kickerHighlight: 'GODAN',
        before: (dark) => lessonCol([
          Text('走る', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text('はしる - to run', style: lessonBodyStyle(dark, size: 14, weight: FontWeight.w500)),
        ]),
        question: 'Remember 走る from the last lesson? Even though it ends in an i-sound + る, which group is it actually in?',
        options: const ['Godan', 'Ichidan'],
        correctIndex: 0,
        after: (dark) => Text('走る is Godan, despite looking like Ichidan', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 14, weight: FontWeight.w600)),
        explanation: "走る (hashiru, \"to run\") is a Godan verb hiding in Ichidan's clothing, one of a handful of "
            "る verbs worth just memorising rather than guessing from the ending alone.",
      ),
      // 3. ます - polite present/future (the u -> i sound shift)
      LessonStep(
        kickerPlain: 'VERB GROUPS',
        kickerHighlight: 'GODAN',
        before: (dark) => lessonCol([
          Text('書く　→　書きます', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: 'To make 書く (to write) polite, く changes to き before ます. What does 書きます mean?',
        options: const ['I will write (polite)', 'I wrote (polite)', "I won't write (polite)"],
        correctIndex: 0,
        after: (dark) => Text('か・き・く・け・こ　→　書き・ます', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "Unlike Ichidan verbs, a Godan verb's ending swaps to its row's い-sound before ます: "
            "く→き, む→み, う→い, and so on for every row.",
      ),
      // 4. ません - polite negative
      LessonStep(
        kickerPlain: 'VERB GROUPS',
        kickerHighlight: 'GODAN',
        before: (dark) => lessonCol([
          Text('読む　→　読みません', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: '読みません is the polite negative of 読む. What does it mean?',
        options: const ["I won't read / don't read (polite)", 'I read it (polite)', 'I want to read'],
        correctIndex: 0,
        after: (dark) => Text('読・み・ません　-　む→み, then add ません', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "ません is the polite negative, the same い-sound shift as ます, just with ません on the end instead.",
      ),
      // 5. ました - polite past
      LessonStep(
        kickerPlain: 'VERB GROUPS',
        kickerHighlight: 'GODAN',
        before: (dark) => lessonCol([
          Text('買う　→　買いました', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: '買いました is the polite past of 買う. What does it mean?',
        options: const ['I bought it (polite)', "I won't buy it (polite)", 'I am buying it (polite)'],
        correctIndex: 0,
        after: (dark) => Text('買・い・ました　-　う→い, then add ました', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "ました is the polite past. う becomes い here too, just like every other row does before ます.",
      ),
      // 6. ませんでした - polite past negative
      LessonStep(
        kickerPlain: 'VERB GROUPS',
        kickerHighlight: 'GODAN',
        before: (dark) => lessonCol([
          Text('走る　→　走りませんでした', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: 'Remember 走る, the Godan verb that looks like Ichidan? 走りませんでした is its polite past negative. What does it mean?',
        options: const ["I didn't run (polite)", 'I ran (polite)', 'I will run (polite)'],
        correctIndex: 0,
        after: (dark) => Text('走・り・ませんでした　-　る→り, then add ませんでした', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 13, weight: FontWeight.w600)),
        explanation: "ます, ません, ました, ませんでした are present, negative, past, and past negative. The ending "
            "changes with the row, but the ます/ません/ました/ませんでした part is always the same.",
      ),
      // 7. Preview of what's still to come (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('書いて・書いた・書かない...', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: dark ? Colors.white : Colors.black)),
        ]),
        explanation: "There's more to Godan verbs than ます forms too: て (and/doing), た (did), ない (won't do), "
            "and more are all on their way in later lessons.",
      ),
      // 8. Transition (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('五段動詞', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: kLessonPurple,
            child: const Text('GODAN VERBS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ]),
        explanation: "Last for this section: the two Irregular verbs that don't follow either pattern.",
      ),
    ],
  ),
  Lesson(
    trackId: kGrammarTrackId,
    day: 21,
    title: '不規則動詞 - Irregular Verbs',
    introSubtitle: "Just two verbs left outside Ichidan and Godan. You already use both of them constantly.",
    steps: [
      // 1. The only two
      LessonStep(
        kickerPlain: 'VERB GROUPS',
        kickerHighlight: 'IRREGULAR',
        before: (dark) => lessonRow([
          lessonCol([Text('する', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)), Text('to do', style: lessonBodyStyle(dark, size: 12, weight: FontWeight.w500))]),
          const SizedBox(width: 24),
          lessonCol([Text('来る', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)), Text('くる - to come', style: lessonBodyStyle(dark, size: 12, weight: FontWeight.w500))]),
        ]),
        question: "する and 来る don't conjugate like Ichidan or Godan verbs at all. How many irregular verbs are there in Japanese?",
        options: const ['Just these two', 'Dozens', 'Hundreds'],
        correctIndex: 0,
        after: (dark) => Text('不規則動詞 - only する and 来る', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "する (to do) and 来る (kuru, to come) are the only two irregular verbs in Japanese. "
            "Everything else is Ichidan or Godan. Because they're used so often, their odd conjugations are "
            "worth memorising directly rather than deriving them from a rule.",
      ),
      // 2. Compound する verbs inherit the irregularity
      LessonStep(
        kickerPlain: 'VERB GROUPS',
        kickerHighlight: 'IRREGULAR',
        before: (dark) => lessonCol([
          Text('勉強する', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text('べんきょうする - to study', style: lessonBodyStyle(dark, size: 13, weight: FontWeight.w500)),
        ]),
        question: 'Lots of Japanese verbs are a noun + する, like 勉強する (to study). Do those conjugate like する too?',
        options: const ['Yes - only the する part changes', 'No, they conjugate differently each time'],
        correctIndex: 0,
        after: (dark) => Text('勉強する → 勉強します・勉強した・勉強しない...', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 13, weight: FontWeight.w600)),
        explanation: "Once you know how する conjugates, you already know how to conjugate every noun+する verb. "
            "The noun in front never changes, only する does.",
      ),
      // 3. Preview of what's still to come (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('します・来ます', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text('して・来て・した・来た・しない・来ない...', style: lessonBodyStyle(dark, size: 14, weight: FontWeight.w600)),
        ]),
        explanation: "Because する and 来る are used constantly, you'll meet their ます, て, た, ない forms and more "
            "throughout the lessons to come. Each one just has to be learned directly.",
      ),
      // 4. Transition (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('不規則動詞', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: kLessonPurple,
            child: const Text('THREE VERB GROUPS DONE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ]),
        explanation: "That's all three verb groups: Ichidan, Godan, and Irregular. Next time: how to build the "
            "て-form for any of them.",
      ),
    ],
  ),
  Lesson(
    trackId: kGrammarTrackId,
    day: 22,
    title: 'て形の作り方 - "How to Build the Te-Form"',
    introSubtitle: "Before more て-form grammar, here's exactly how to build て from a verb's dictionary form, for "
        "every verb type.",
    steps: [
      // 1. Ichidan
      LessonStep(
        kickerPlain: 'TE-FORM',
        kickerHighlight: 'ICHIDAN',
        before: (dark) => Text('食べる　→　食べて', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: "Ichidan verbs build て the same way they build every other form. Just drop る. What is 食べる's て-form?",
        options: const ['食べて', '食べった', '食べいて'],
        correctIndex: 0,
        after: (dark) => Text('食べ・て　-　just drop る, add て', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "Every Ichidan verb builds て the exact same way: drop る, add て. No exceptions.",
      ),
      // 2. Godan う/つ/る
      LessonStep(
        kickerPlain: 'TE-FORM',
        kickerHighlight: 'GODAN',
        before: (dark) => Text('買う　→　買って', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'Godan verbs ending in う, つ, or る all change the same way for て. What is 買う\'s て-form?',
        options: const ['買って', '買いて', '買んで'],
        correctIndex: 0,
        after: (dark) => Text('う・つ・る　→　って', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "う, つ, and る verbs all swap their final kana for って: 買う→買って, 待つ→待って, 乗る→乗って.",
      ),
      // 3. Godan む/ぬ/ぶ
      LessonStep(
        kickerPlain: 'TE-FORM',
        kickerHighlight: 'GODAN',
        before: (dark) => Text('読む　→　読んで', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'む, ぬ, and ぶ verbs take a different ending for て. What is 読む\'s て-form?',
        options: const ['読んで', '読んて', '読って'],
        correctIndex: 0,
        after: (dark) => Text('む・ぬ・ぶ　→　んで', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "む, ぬ, and ぶ verbs all swap their final kana for んで (a voiced で, not て): 読む→読んで, 遊ぶ→遊んで.",
      ),
      // 4. Godan く (with the 行く exception)
      LessonStep(
        kickerPlain: 'TE-FORM',
        kickerHighlight: 'GODAN',
        before: (dark) => Text('書く　→　書いて', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'く verbs swap their ending for いて. What is 書く\'s て-form?',
        options: const ['書いて', '書て', '書って'],
        correctIndex: 0,
        after: (dark) => Text('く　→　いて　（exception: 行く → 行って）', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 13, weight: FontWeight.w600)),
        explanation: "く verbs swap く for いて. Except 行く (to go), which irregularly becomes 行って instead of "
            "行いて. It's one of the few verbs worth memorising as an exception.",
      ),
      // 5. Godan ぐ
      LessonStep(
        kickerPlain: 'TE-FORM',
        kickerHighlight: 'GODAN',
        before: (dark) => Text('泳ぐ　→　泳いで', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'ぐ verbs work just like く verbs, but voiced. What is 泳ぐ\'s て-form?',
        options: const ['泳いで', '泳いて', '泳って'],
        correctIndex: 0,
        after: (dark) => Text('ぐ　→　いで', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "ぐ verbs swap ぐ for いで, the voiced counterpart of く's いて.",
      ),
      // 6. Godan す
      LessonStep(
        kickerPlain: 'TE-FORM',
        kickerHighlight: 'GODAN',
        before: (dark) => Text('話す　→　話して', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'す verbs are the simplest Godan group. What is 話す\'s て-form?',
        options: const ['話して', '話いて', '話んで'],
        correctIndex: 0,
        after: (dark) => Text('す　→　して', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "す verbs just swap す for して. No euphonic change needed, unlike the other rows.",
      ),
      // 7. Irregular
      LessonStep(
        kickerPlain: 'TE-FORM',
        kickerHighlight: 'IRREGULAR',
        before: (dark) => lessonRow([
          lessonCol([Text('する', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)), Text('して', style: lessonBodyStyle(dark, size: 14, weight: FontWeight.w600))]),
          const SizedBox(width: 24),
          lessonCol([Text('来る', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)), Text('来て', style: lessonBodyStyle(dark, size: 14, weight: FontWeight.w600))]),
        ]),
        question: 'する and 来る have their own て-forms, just like everywhere else. What is する\'s て-form?',
        options: const ['して', 'すて', 'しんで'],
        correctIndex: 0,
        after: (dark) => Text('する　→　して　　来る　→　来て', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "する becomes して, and 来る becomes 来て (the reading changes from くる to きて). Both just "
            "have to be memorised directly.",
      ),
      // 8. Summary + transition (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text(
            'る→て　う・つ・る→って\nむ・ぬ・ぶ→んで　く→いて\nぐ→いで　す→して',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: dark ? Colors.white : Colors.black, height: 1.6),
          ),
        ]),
        explanation: "Now that you can build て yourself, let's put it to use, starting with asking someone to "
            "do something.",
      ),
    ],
  ),

  // Section 3: Adjectives and Describing (see grammarSections). な-adjectives,
  // い-adjectives, and the 小さい/小さな exception are concept recap lessons
  // like Section 2's Ichidan/Godan/Irregular trio, authored directly here
  // rather than through GrammarPoint. なる, とても, 一番, and すぎる (days
  // 45-48) are single-form GrammarPoints in grammar_data.dart instead.
  Lesson(
    trackId: kGrammarTrackId,
    day: 43,
    title: 'な-adjectives',
    introSubtitle: "A recap of the adjectives that borrow a な before a noun, and how they turn negative and past.",
    steps: [
      // 1. What makes a な-adjective different
      LessonStep(
        kickerPlain: 'ADJECTIVES',
        kickerHighlight: 'な-ADJECTIVES',
        before: (dark) => lessonCol([
          Text('静か', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text('しずか - quiet', style: lessonBodyStyle(dark, size: 14, weight: FontWeight.w500)),
        ]),
        question: 'To describe a noun directly with 静か (quiet), what do you need to add between them?',
        options: const ['な - 静かな町 (a quiet town)', 'Nothing - 静か町', 'の - 静かの町'],
        correctIndex: 0,
        after: (dark) => Text('静かな町　-　a quiet town', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w600)),
        explanation: "な-adjectives borrow な only when they come directly before a noun they're describing. On "
            "their own, or before です, they drop it: 静かです (it's quiet), not 静かなです.",
      ),
      // 2. Negative recap. じゃない/ではない
      LessonStep(
        kickerPlain: 'ADJECTIVES',
        kickerHighlight: 'な-ADJECTIVES',
        before: (dark) => lessonCol([
          Text('静かじゃない', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: 'You already met じゃない and ではない for nouns. Do な-adjectives turn negative the exact same way?',
        options: const ['Yes - 静かじゃない / 静かではない (not quiet)', 'No, they use a different ending'],
        correctIndex: 0,
        after: (dark) => Text('静か　→　静かじゃない / 静かではない', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 14, weight: FontWeight.w600)),
        explanation: "な-adjectives behave just like nouns for negatives and です. じゃない/ではない, formal or "
            "casual, works exactly the same way you already learned.",
      ),
      // 3. Past tense recap. だった/でした
      LessonStep(
        kickerPlain: 'ADJECTIVES',
        kickerHighlight: 'な-ADJECTIVES',
        before: (dark) => lessonCol([
          Text('静かでした', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: 'What about the past? How would you say 静か (quiet) "was quiet"?',
        options: const ['静かでした / 静かだった (was quiet)', '静かました', '静かいた'],
        correctIndex: 0,
        after: (dark) => Text('静か　→　静かでした / 静かだった', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 14, weight: FontWeight.w600)),
        explanation: "Past and past-negative for な-adjectives also follow the noun pattern exactly: でした/だった "
            "for \"was\", and じゃなかった/ではなかった for \"was not\". Nothing new to learn here.",
      ),
      // 4. Transition (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('な形容詞', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: kLessonPurple,
            child: const Text('な-ADJECTIVES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ]),
        explanation: "Next up: い-adjectives. The other adjective group, with its own negative and past endings.",
      ),
    ],
  ),
  Lesson(
    trackId: kGrammarTrackId,
    day: 44,
    title: 'い-adjectives',
    introSubtitle: "A recap of the adjectives that end in い, and how they turn negative and past.",
    steps: [
      // 1. What makes an い-adjective different
      LessonStep(
        kickerPlain: 'ADJECTIVES',
        kickerHighlight: 'い-ADJECTIVES',
        before: (dark) => lessonCol([
          Text('寒い', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text('さむい - cold', style: lessonBodyStyle(dark, size: 14, weight: FontWeight.w500)),
        ]),
        question: 'Unlike な-adjectives, how does 寒い (cold) go directly before a noun it describes?',
        options: const ['No change needed - 寒い日 (a cold day)', 'Add な - 寒いな日', 'Add の - 寒いの日'],
        correctIndex: 0,
        after: (dark) => Text('寒い日　-　a cold day', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w600)),
        explanation: "い-adjectives never need な or any other connector before a noun. The い ending does that "
            "job on its own.",
      ),
      // 2. Negative recap. くない
      LessonStep(
        kickerPlain: 'ADJECTIVES',
        kickerHighlight: 'い-ADJECTIVES',
        before: (dark) => lessonCol([
          Text('寒くない', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: 'You already learned くない for this. How do you make 寒い (cold) negative?',
        options: const ['Drop い, add くない - 寒くない (not cold)', 'Add じゃない - 寒いじゃない', 'Add ません - 寒いません'],
        correctIndex: 0,
        after: (dark) => Text('寒い　→　寒くない', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "い-adjectives never take じゃない/ではない. Only nouns and な-adjectives do. For い-adjectives "
            "it's always drop い, add くない.",
      ),
      // 3. Past tense recap. かった/くなかった
      LessonStep(
        kickerPlain: 'ADJECTIVES',
        kickerHighlight: 'い-ADJECTIVES',
        before: (dark) => lessonCol([
          Text('寒かった・寒くなかった', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        question: 'What are the past and past-negative of 寒い (cold)?',
        options: const ['寒かった (was cold) and 寒くなかった (was not cold)', '寒いでした and 寒いじゃなかった', '寒ました and 寒ませんでした'],
        correctIndex: 0,
        after: (dark) => Text('寒い　→　寒かった　→　寒くなかった', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 13, weight: FontWeight.w600)),
        explanation: "Drop い, add かった for \"was\", or くなかった for \"was not\". い-adjectives build all four "
            "forms (is/isn't/was/wasn't) from their own い ending, never from です/じゃない.",
      ),
      // 4. Transition (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('い形容詞', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: kLessonPurple,
            child: const Text('い-ADJECTIVES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ]),
        explanation: "Next up: two very common い-adjectives that break their own rule in front of a noun.",
      ),
    ],
  ),
  Lesson(
    trackId: kGrammarTrackId,
    day: 45,
    title: '小さい・小さな and 大きい・大きな',
    introSubtitle: "Two everyday い-adjectives that also have a special な-only form for right before a noun.",
    steps: [
      // 1. 小さい is normal
      LessonStep(
        kickerPlain: 'ADJECTIVES',
        kickerHighlight: '小さい・大きい',
        before: (dark) => lessonCol([
          Text('小さい猫', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text('ちいさいねこ - a small cat', style: lessonBodyStyle(dark, size: 13, weight: FontWeight.w500)),
        ]),
        question: '小さい (small) is an ordinary い-adjective. Does it conjugate like every other one you\'ve met (くない, かった...)?',
        options: const ['Yes - exactly like 寒い does', 'No, it has its own special endings'],
        correctIndex: 0,
        after: (dark) => Text('小さい　→　小さくない・小さかった', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 14, weight: FontWeight.w600)),
        explanation: "小さい (chiisai, small) and 大きい (ookii, big) both conjugate completely normally as "
            "い-adjectives: 小さくない (not small), 大きかった (was big), and so on.",
      ),
      // 2. 小さな / 大きな only before a noun
      LessonStep(
        kickerPlain: 'ADJECTIVES',
        kickerHighlight: '小さな・大きな',
        before: (dark) => lessonCol([
          Text('小さな猫', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text('ちいさなねこ - a small cat', style: lessonBodyStyle(dark, size: 13, weight: FontWeight.w500)),
        ]),
        question: '小さな猫 means the same thing as 小さい猫. Can you also say 猫は小さなです (the cat is small) with 小さな?',
        options: const ['No - 小さな only ever goes directly before a noun', 'Yes, it works anywhere 小さい does'],
        correctIndex: 0,
        after: (dark) => const Icon(Icons.info_outline, size: 40, color: kLessonPurple),
        explanation: "小さな and 大きな look like な-adjectives, but they're a special exception: they ONLY appear "
            "directly in front of a noun, and never conjugate. No 小さなです, no 小さなかった. For everything "
            "else, use 小さい/大きい instead.",
      ),
      // 3. Transition (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('小さい・小さな', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          Text('大きい・大きな', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: kLessonPurple,
            child: const Text('SMALL & BIG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ]),
        explanation: "Next up: なる, how to say something \"becomes\" a certain way.",
      ),
    ],
  ),

  // Section 8: Questions, day 88 (see grammarSections). てください already
  // has its own full GrammarPoint lesson on day 23 - this is just a short
  // recap bridging into をください and お願いします, two more ways to ask
  // for something.
  Lesson(
    trackId: kGrammarTrackId,
    day: 88,
    title: 'てください (Recap) - "Please Do"',
    introSubtitle: "A quick recap before two more ways to ask for something: てください, をください, and お願いします.",
    steps: [
      // 1. Recap quiz
      LessonStep(
        kickerPlain: 'QUESTIONS',
        kickerHighlight: 'REQUESTS',
        before: (dark) => Text('待ってください', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'Remember てください from day 23? How is it built?',
        options: const ["Verb て-form + ください", 'Verb dictionary form + ください', 'Noun + ください'],
        correctIndex: 0,
        after: (dark) => Text('待っ・てください', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 16, weight: FontWeight.w600)),
        explanation: "てください asks someone to DO something. Attach it to a verb's て-form, exactly like you learned "
            "back on day 23.",
      ),
      // 2. Three ways to say please (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('てください・をください・お願いします', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: dark ? Colors.white : Colors.black, height: 1.6)),
        ]),
        explanation: "てください asks someone to do an action, をください asks for a THING, and お願いします is the "
            "simplest, most all-purpose way to just say \"please\". Next: をください.",
      ),
    ],
  ),

  // Section 9: Things You Have To Do, day 98 (see grammarSections). なくても
  // いい already has its own full GrammarPoint on day 29 - this is just a
  // short recap bridging the obligation forms (ないといけない, なくちゃ...)
  // back to the one case where you DON'T have to.
  Lesson(
    trackId: kGrammarTrackId,
    day: 98,
    title: 'なくてもいい (Recap) - "Don\'t Have To"',
    introSubtitle: "A quick recap, now that you know several ways to say \"must\", and the one case where you don't have to.",
    steps: [
      // 1. Recap quiz
      LessonStep(
        kickerPlain: 'OBLIGATION',
        kickerHighlight: 'RECAP',
        before: (dark) => Text('焦らなくてもいいですよ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'Remember なくてもいい from day 29? What does it mean?',
        options: const ["You don't have to do something", 'You must do something', "You're not allowed to do something"],
        correctIndex: 0,
        after: (dark) => Text('焦らない・くてもいい - no need to hurry', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 14, weight: FontWeight.w600)),
        explanation: "なくてもいい is the flip side of everything in this section: ないといけない, なくちゃ, "
            "なくてはいけない, and なくてはならない all say something IS required; なくてもいい says it isn't.",
      ),
      // 2. Transition (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('ないといけない　⇔　なくてもいい', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: dark ? Colors.white : Colors.black, height: 1.6)),
        ]),
        explanation: "Required vs optional, now you have both sides covered. Next up: Section 10, starting with "
            "how to talk about your plans.",
      ),
    ],
  ),

  // Section 10: Experiencing, Listing, and Nuance, day 105 (see
  // grammarSections). まだ～ていません already has its own full GrammarPoint
  // on day 62. This is a short recap between てある and だけ/しか.
  Lesson(
    trackId: kGrammarTrackId,
    day: 105,
    title: 'まだ～ていません (Recap) - "Have Not Yet"',
    introSubtitle: "A quick recap of まだ～ていません before two ways to say \"only\".",
    steps: [
      // 1. Recap quiz
      LessonStep(
        kickerPlain: 'RECAP',
        kickerHighlight: 'NOT YET',
        before: (dark) => Text('まだ決めていません', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        question: 'Remember まだ～ていません from day 62? What does it mean?',
        options: const ["Haven't done something yet", 'Have already done something', 'Are currently doing something'],
        correctIndex: 0,
        after: (dark) => Text('まだ・決め・ていません', textAlign: TextAlign.center, style: lessonBodyStyle(dark, size: 15, weight: FontWeight.w600)),
        explanation: "まだ signals \"not yet\" early in the sentence, and ていません confirms it at the end, exactly "
            "like you learned back on day 62.",
      ),
      // 2. Transition (no question)
      LessonStep(
        before: (dark) => lessonCol([
          Text('だけ・しか～ない', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black)),
        ]),
        explanation: "Next up: two ways to say \"only\": だけ and しか～ない.",
      ),
    ],
  ),
];
