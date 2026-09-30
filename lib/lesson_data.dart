import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'study_data.dart';
import 'sets_data.dart';
import 'kanji_challenge_data.dart';
import 'deck_detail.dart';
import 'skool_activity_screen.dart';

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

  const Lesson({
    this.trackId = kKanjiChallengeTrackId,
    required this.day,
    required this.title,
    required this.introSubtitle,
    this.steps = const [],
    this.activityBuilder,
    this.endOfDay,
  });
}

Lesson? lessonForTrackAndDay(String trackId, int day) {
  for (final l in lessons) {
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
Widget withFurigana(String furigana, String word, bool isDarkMode, {double wordSize = 44, Color? wordColor}) {
  return lessonCol([
    Text(furigana, style: TextStyle(fontSize: wordSize * 0.32, color: isDarkMode ? Colors.white54 : Colors.black45)),
    const SizedBox(height: 2),
    Text(word, style: TextStyle(fontSize: wordSize, fontWeight: FontWeight.w900, color: wordColor ?? (isDarkMode ? Colors.white : Colors.black))),
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
        after: (dark) => withFurigana('かわい', '可愛い', dark, wordSize: 44),
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
];
