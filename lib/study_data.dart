import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'sets_data.dart';

const String _studyDecksPrefsKey = 'study_decks';

Future<List<StudyDeck>> loadStudyDecks() async {
  final prefs = await SharedPreferences.getInstance();
  final encoded = prefs.getString(_studyDecksPrefsKey);
  if (encoded == null) return [];
  final decoded = jsonDecode(encoded) as List<dynamic>;
  return decoded.map((d) => StudyDeck.fromMap(Map<String, dynamic>.from(d))).toList();
}

Future<void> saveStudyDecks(List<StudyDeck> decks) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_studyDecksPrefsKey, jsonEncode(decks.map((d) => d.toMap()).toList()));
}

const String _readingTextsPrefsKey = 'reading_texts';

// A piece of imported Japanese text for the Study > Reading tab - read like
// Listening's sentences, but as a whole passage the user supplies themselves
// rather than Tatoeba example sentences.
class ReadingText {
  String id;
  String title;
  String content;

  ReadingText({required this.id, required this.title, required this.content});

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'content': content};

  factory ReadingText.fromMap(Map<String, dynamic> map) => ReadingText(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    content: map['content'] ?? '',
  );
}

Future<List<ReadingText>> loadReadingTexts() async {
  final prefs = await SharedPreferences.getInstance();
  final encoded = prefs.getString(_readingTextsPrefsKey);
  if (encoded == null) return [];
  final decoded = jsonDecode(encoded) as List<dynamic>;
  return decoded.map((d) => ReadingText.fromMap(Map<String, dynamic>.from(d))).toList();
}

Future<void> saveReadingTexts(List<ReadingText> texts) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_readingTextsPrefsKey, jsonEncode(texts.map((t) => t.toMap()).toList()));
}

// Extracts the unique kanji/kana characters from a Japanese string, in order.
List<String> extractKanjiCharacters(String text) {
  final chars = <String>[];
  for (int i = 0; i < text.length; i++) {
    final char = text[i];
    final code = char.codeUnitAt(0);
    if ((code >= 0x4E00 && code <= 0x9FFF) || // CJK Unified Ideographs
        (code >= 0x3400 && code <= 0x4DBF) || // CJK Extension A
        (code >= 0x3040 && code <= 0x309F) || // Hiragana
        (code >= 0x30A0 && code <= 0x30FF)) { // Katakana
      if (!chars.contains(char)) chars.add(char);
    }
  }
  return chars;
}

// Looks up the KanjiVG stroke order code for a single character, reusing
// whatever the dictionary already knows about it, falling back to a
// generated code for hiragana/katakana.
String? findKanjiVGCodeFor(String char) {
  for (final set in setsData.values) {
    for (final item in set.items) {
      if (item.japanese == char && item.kanjiVGCode != null) {
        return item.kanjiVGCode;
      }
    }
  }

  final code = char.codeUnitAt(0);
  if ((code >= 0x3040 && code <= 0x309F) || // Hiragana
      (code >= 0x30A0 && code <= 0x30FF)) { // Katakana
    return code.toRadixString(16).padLeft(5, '0');
  }

  return null;
}

// Resolves stroke order codes for every kanji/kana character in a word,
// pulling from the existing dictionary data where available.
List<String> findKanjiVGCodesForWord(String text) {
  return extractKanjiCharacters(text)
      .map(findKanjiVGCodeFor)
      .whereType<String>()
      .toList();
}

// Searches every dictionary set for items whose Japanese text, reading, or
// translation matches the query, for autocompleting the Add Card fields.
List<Item> searchDictionaryItems(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return [];

  final results = <Item>[];
  final seen = <String>{};
  for (final set in setsData.values) {
    for (final item in set.items) {
      final key = '${item.japanese}|${item.translation}|${item.itemType}';
      if (seen.contains(key)) continue;

      final matches = item.japanese.toLowerCase().contains(q) ||
          item.translation.toLowerCase().contains(q) ||
          item.reading.toLowerCase().contains(q);
      if (matches) {
        results.add(item);
        seen.add(key);
        if (results.length >= 20) return results;
      }
    }
  }
  return results;
}

// The same kanji often has more than one Kanji-type entry across different
// sets - e.g. an early "Essential Radicals" entry with no reading data at
// all, alongside a later JLPT entry that has the real on'yomi/kun'yomi -
// so rather than stopping at the first match (which could easily be the
// empty one), this merges the on'yomi/kun'yomi found across every matching
// entry into one synthetic Item with the fullest picture available. Returns
// null only if the character isn't in the dictionary as a Kanji-type entry
// at all.
Item? dictionaryEntryForKanji(String kanji) {
  Item? best;
  final onYomiSet = <String>{};
  final kunYomiSet = <String>{};
  for (final set in setsData.values) {
    for (final item in set.items) {
      if (item.itemType != 'Kanji' || item.japanese != kanji) continue;
      best ??= item;
      for (final r in item.onYomi.split(',')) {
        final trimmed = r.trim();
        if (trimmed.isNotEmpty) onYomiSet.add(trimmed);
      }
      for (final r in item.kunYomi.split(',')) {
        final trimmed = r.trim();
        if (trimmed.isNotEmpty) kunYomiSet.add(trimmed);
      }
    }
  }
  if (best == null) return null;
  return Item(
    japanese: best.japanese,
    translation: best.translation,
    strokeOrder: best.strokeOrder,
    kanjiVGCode: best.kanjiVGCode,
    onYomi: onYomiSet.join(', '),
    kunYomi: kunYomiSet.join(', '),
    tags: best.tags,
  );
}

// Dictionary Vocab words containing [kanji] (excluding the bare kanji
// itself), in setsData's own iteration order - the curated/JLPT sets are
// inserted before the bulk JMdict import, so those naturally surface first
// as the "best" examples, with the rest available for "more examples".
List<Item> exampleWordsContaining(String kanji, {int limit = 20}) {
  final results = <Item>[];
  final seen = <String>{};
  for (final set in setsData.values) {
    for (final item in set.items) {
      if (item.itemType != 'Vocab') continue;
      if (item.japanese == kanji || !item.japanese.contains(kanji)) continue;
      if (!seen.add(item.japanese)) continue;
      results.add(item);
      if (results.length >= limit) return results;
    }
  }
  return results;
}

// A dictionary/deck entry surfaced for a highlighted word inside a sentence:
// its reading, meaning, romaji and memory technique, plus whether it's
// already a card in the current study set (drawn from the dictionary Item
// when it came from there).
class HighlightEntry {
  final String japanese;
  String reading;
  String meaning;
  String romaji;
  String memoryTechnique;
  final Item? item;
  bool isDeckWord;
  // The actual deck card this word came from, when isDeckWord is true - the
  // same object still referenced by whatever deck is showing it elsewhere,
  // so editing it here (e.g. its memory technique) is reflected there too.
  StudyCard? card;

  HighlightEntry({
    required this.japanese,
    required this.reading,
    required this.meaning,
    this.romaji = '',
    this.memoryTechnique = '',
    this.item,
    this.isDeckWord = false,
    this.card,
  });
}

// Indexes every Vocab/Kanji dictionary entry - skipping the bare hiragana/
// katakana practice tables, which would otherwise match almost every single
// character in a sentence - plus every card already in [deckCards], keyed by
// their exact Japanese text. Used to spot known words inside a sentence.
//
// When a word exists both in the dictionary and as a deck card, the card's
// own hiragana/romaji/memory technique/meaning win over the dictionary's
// (falling back to the dictionary's where the card left a field blank),
// since that's the user's own curated version of the word.
Map<String, HighlightEntry> buildHighlightIndex(List<StudyCard> deckCards) {
  final index = <String, HighlightEntry>{};
  for (final set in setsData.values) {
    for (final item in set.items) {
      if (item.itemType != 'Vocab' && item.itemType != 'Kanji') continue;
      final key = item.japanese;
      if (key.isEmpty) continue;
      index.putIfAbsent(
        key,
        () => HighlightEntry(
          japanese: key,
          reading: item.itemType == 'Vocab'
              ? item.reading
              : (item.kunYomi.isNotEmpty ? item.kunYomi : item.onYomi),
          meaning: item.translation,
          item: item,
        ),
      );
    }
  }
  for (final card in deckCards) {
    // A bare hiragana/katakana character deck (e.g. the Hiragana Beginner
    // deck) would otherwise mark nearly every character in any sentence as
    // a "known word" - excessive and not useful, so these are excluded the
    // same way the dictionary's own kana tables already are above.
    if (card.cardType == 'Kana') continue;
    final key = card.japanese.trim();
    if (key.isEmpty) continue;
    final existing = index[key];
    if (existing != null) {
      existing.isDeckWord = true;
      existing.card = card;
      if (card.hiragana.isNotEmpty) existing.reading = card.hiragana;
      if (card.romaji.isNotEmpty) existing.romaji = card.romaji;
      if (card.memoryTechnique.isNotEmpty) existing.memoryTechnique = card.memoryTechnique;
      if (card.english.isNotEmpty) existing.meaning = card.english;
    } else {
      index[key] = HighlightEntry(
        japanese: key,
        reading: card.hiragana,
        meaning: card.english,
        romaji: card.romaji,
        memoryTechnique: card.memoryTechnique,
        isDeckWord: true,
        card: card,
      );
    }
  }
  return index;
}

class SentenceToken {
  final String text;
  final HighlightEntry? entry;
  SentenceToken(this.text, this.entry);
}

// Greedy longest-match tokenizer: splits [text] into runs that exist in
// [index] (highlightable) and runs that don't (plain), always preferring the
// longest match starting at each position - capped to the longest key
// actually in the index (rather than a fixed length), so a longer deck
// phrase or compound word is never skipped in favor of a shorter word it
// happens to contain. Not full word segmentation, but good enough since it
// only needs to catch words the dictionary or deck already knows about.
List<SentenceToken> tokenizeSentence(String text, Map<String, HighlightEntry> index) {
  final maxWordLength = index.keys.isEmpty ? 1 : index.keys.map((k) => k.length).reduce((a, b) => a > b ? a : b);
  final tokens = <SentenceToken>[];
  int i = 0;
  while (i < text.length) {
    HighlightEntry? found;
    int matchedLen = 0;
    final maxLen = (text.length - i).clamp(1, maxWordLength);
    for (int len = maxLen; len >= 1; len--) {
      final sub = text.substring(i, i + len);
      final entry = index[sub];
      if (entry != null) {
        found = entry;
        matchedLen = len;
        break;
      }
    }
    if (found != null) {
      tokens.add(SentenceToken(text.substring(i, i + matchedLen), found));
      i += matchedLen;
    } else {
      tokens.add(SentenceToken(text[i], null));
      i += 1;
    }
  }
  return tokens;
}

// Kanji characters only (not hiragana/katakana) appearing in [text], in
// order, deduplicated - for showing the individual kanji making up a word.
List<String> extractKanjiOnly(String text) {
  final chars = <String>[];
  for (final rune in text.runes) {
    if ((rune >= 0x4E00 && rune <= 0x9FFF) || (rune >= 0x3400 && rune <= 0x4DBF)) {
      final char = String.fromCharCode(rune);
      if (!chars.contains(char)) chars.add(char);
    }
  }
  return chars;
}

class StudyCard {
  String japanese;
  String hiragana;
  String romaji;
  String english;
  List<String> kanjiVGCodes;

  // Spaced repetition state (simplified SM-2, correct/incorrect only).
  int repetitions; // consecutive correct answers since the last lapse
  double easeFactor;
  int intervalDays;
  String? nextReviewDate; // ISO date (YYYY-MM-DD); null means "new, due now"
  int progress; // 0-100 mastery score shown to the user

  // Which side of the card is shown as the prompt. True (the default) shows
  // English first and asks for the Japanese; false shows Japanese first.
  bool englishFirst;

  // How this card is answered during spaced repetition: 'basic' (reveal and
  // mark yourself), 'draw' (draw the Japanese, using stroke hints), or
  // 'type' (type the answer, auto-marked on an exact match).
  String answerMode;

  // Optional mnemonic/memory aid, revealed on demand during study.
  String memoryTechnique;

  // Starred in one of the Games (Writing/Reading practice).
  bool isStarred;

  // Which day of a day-scheduled challenge deck (e.g. the 90 Day Kanji
  // Challenge) this card unlocks on. Null for ordinary cards, which are
  // never gated by a challenge day.
  int? challengeDay;

  // How this card is classified: 'Kanji', 'Kana', or 'Vocab' - independent
  // of answerMode, for features that need to treat a deck's cards
  // differently by kind rather than just study-mode mechanics.
  String cardType;

  StudyCard({
    required this.japanese,
    required this.hiragana,
    this.romaji = '',
    required this.english,
    List<String>? kanjiVGCodes,
    this.repetitions = 0,
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.nextReviewDate,
    this.progress = 0,
    this.englishFirst = true,
    this.answerMode = 'basic',
    this.memoryTechnique = '',
    this.isStarred = false,
    this.challengeDay,
    this.cardType = 'Vocab',
  }) : kanjiVGCodes = kanjiVGCodes ?? [];

  Map<String, dynamic> toMap() => {
    'japanese': japanese,
    'hiragana': hiragana,
    'romaji': romaji,
    'english': english,
    'kanjiVGCodes': kanjiVGCodes,
    'repetitions': repetitions,
    'easeFactor': easeFactor,
    'intervalDays': intervalDays,
    'nextReviewDate': nextReviewDate,
    'progress': progress,
    'englishFirst': englishFirst,
    'answerMode': answerMode,
    'memoryTechnique': memoryTechnique,
    'isStarred': isStarred,
    'challengeDay': challengeDay,
    'cardType': cardType,
  };

  factory StudyCard.fromMap(Map<String, dynamic> map) => StudyCard(
    japanese: map['japanese'] ?? '',
    hiragana: map['hiragana'] ?? '',
    romaji: map['romaji'] ?? '',
    english: map['english'] ?? '',
    kanjiVGCodes: List<String>.from(map['kanjiVGCodes'] ?? const []),
    repetitions: map['repetitions'] ?? 0,
    easeFactor: (map['easeFactor'] ?? 2.5).toDouble(),
    intervalDays: map['intervalDays'] ?? 0,
    nextReviewDate: map['nextReviewDate'],
    progress: map['progress'] ?? 0,
    englishFirst: map['englishFirst'] ?? true,
    memoryTechnique: map['memoryTechnique'] ?? '',
    answerMode: map['answerMode'] ?? 'basic',
    isStarred: map['isStarred'] ?? false,
    challengeDay: map['challengeDay'],
    cardType: map['cardType'] ?? 'Vocab',
  );
}

// Finds every card across every saved deck whose japanese text matches
// [japanese] and applies [mutate] to each, then persists if anything
// changed. Needed because a card shown in a game launched from Mistakes is
// rebuilt fresh from log data (MistakeEntry.toStudyCard()), not the same
// object as whatever deck it came from, so edits can't rely on identity.
Future<void> updateCardInAllDecks(String japanese, void Function(StudyCard card) mutate) async {
  final decks = await loadStudyDecks();
  var changed = false;
  for (final deck in decks) {
    for (final card in deck.cards) {
      if (card.japanese.trim() == japanese.trim()) {
        mutate(card);
        changed = true;
      }
    }
  }
  if (changed) await saveStudyDecks(decks);
}

// Reverts a card's spaced repetition state back to "new".
void resetCardProgress(StudyCard card) {
  card.repetitions = 0;
  card.easeFactor = 2.5;
  card.intervalDays = 0;
  card.nextReviewDate = null;
  card.progress = 0;
}

String todayStamp() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

DateTime _parseStamp(String stamp) {
  final parts = stamp.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

// A card is due if it's new (never reviewed) or its scheduled date has arrived.
bool isCardDue(StudyCard card) {
  if (card.nextReviewDate == null) return true;
  final today = _parseStamp(todayStamp());
  return !_parseStamp(card.nextReviewDate!).isAfter(today);
}

// Simplified SM-2: only two grades (correct/incorrect) instead of 0-5 quality.
// Correct grows the interval using the ease factor (1 day -> 6 days -> interval*ease)
// and nudges ease up slightly; incorrect resets the streak, shortens the interval
// back to 1 day, and penalizes ease more heavily, mirroring Anki's "lapse" behaviour.
void recordReview(StudyCard card, bool correct) {
  if (correct) {
    card.repetitions += 1;
    if (card.repetitions == 1) {
      card.intervalDays = 1;
    } else if (card.repetitions == 2) {
      card.intervalDays = 6;
    } else {
      card.intervalDays = (card.intervalDays * card.easeFactor).round();
    }
    card.easeFactor = (card.easeFactor + 0.1).clamp(1.3, 3.0);
    card.progress = (card.progress + 15).clamp(0, 100);
  } else {
    card.repetitions = 0;
    card.intervalDays = 1;
    card.easeFactor = (card.easeFactor - 0.2).clamp(1.3, 3.0);
    card.progress = (card.progress - 20).clamp(0, 100);
  }

  final next = DateTime.now().add(Duration(days: card.intervalDays));
  card.nextReviewDate =
      '${next.year.toString().padLeft(4, '0')}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
}

// Human-readable due date for the card list view.
String dueLabel(StudyCard card) {
  if (card.nextReviewDate == null) return 'New';
  final today = _parseStamp(todayStamp());
  final due = _parseStamp(card.nextReviewDate!);
  if (!due.isAfter(today)) return 'Due now';
  final daysAway = due.difference(today).inDays;
  return daysAway == 1 ? 'Due in 1 day' : 'Due in $daysAway days';
}

class StudyDeck {
  String name;
  final List<StudyCard> cards;

  // Spaced Repetition: how many never-before-seen cards to introduce per
  // day, adjustable in the deck's settings.
  int newCardsPerDay;
  // How many new cards have already been introduced today, and which day
  // that count is for (ISO date) - reset automatically once the date rolls
  // over. Tracked here (rather than globally) since the cap is per-deck.
  String? newCardsIntroducedDate;
  int newCardsIntroducedToday;

  // Non-null marks this as a day-scheduled challenge deck (e.g. the 90 Day
  // Kanji Challenge): new cards unlock by their own StudyCard.challengeDay
  // reaching the number of days elapsed since this date, instead of being
  // capped by newCardsPerDay.
  String? challengeStartDate;

  // Which challenge days' lesson recap (see lesson_data.dart) have already
  // been completed - so the lesson only gates the start of Spaced
  // Repetition once per day, whether it was completed there or opened
  // manually from Study > Lessons.
  List<int> completedLessonDays;

  // Which lesson curriculum (see lesson_data.dart's trackId constants) this
  // deck's lessons come from, or null for an ordinary deck with none.
  String? lessonSetId;
  // When this deck was created (ISO date) - used to compute which lesson
  // day it's on for decks that follow a lesson curriculum but *aren't* a
  // day-scheduled challenge deck (i.e. challengeStartDate is unset), such as
  // the Essential Vocabulary Challenge, whose cards are introduced at the
  // user's own configured daily rate rather than a fixed schedule.
  String? deckCreatedDate;

  // Whether the "how answering flashcards works" explainer has already been
  // shown for this deck - it's shown once, automatically, right before the
  // very first card of the deck is ever drilled (see
  // spaced_repetition_standard.dart's _maybeShowAnswerIntro), for special
  // decks and ordinary custom ones alike.
  bool hasShownAnswerIntro;

  StudyDeck({
    required this.name,
    List<StudyCard>? cards,
    this.newCardsPerDay = 10,
    this.newCardsIntroducedDate,
    this.newCardsIntroducedToday = 0,
    this.challengeStartDate,
    List<int>? completedLessonDays,
    this.lessonSetId,
    this.deckCreatedDate,
    this.hasShownAnswerIntro = false,
  }) : cards = cards ?? [],
       completedLessonDays = completedLessonDays ?? [];

  Map<String, dynamic> toMap() => {
    'name': name,
    'cards': cards.map((c) => c.toMap()).toList(),
    'newCardsPerDay': newCardsPerDay,
    'newCardsIntroducedDate': newCardsIntroducedDate,
    'newCardsIntroducedToday': newCardsIntroducedToday,
    'challengeStartDate': challengeStartDate,
    'completedLessonDays': completedLessonDays,
    'lessonSetId': lessonSetId,
    'deckCreatedDate': deckCreatedDate,
    'hasShownAnswerIntro': hasShownAnswerIntro,
  };

  factory StudyDeck.fromMap(Map<String, dynamic> map) {
    final cards = (map['cards'] as List? ?? [])
        .map((c) => StudyCard.fromMap(Map<String, dynamic>.from(c)))
        .toList();
    return StudyDeck(
      name: map['name'] ?? '',
      cards: cards,
      newCardsPerDay: map['newCardsPerDay'] ?? 10,
      newCardsIntroducedDate: map['newCardsIntroducedDate'],
      newCardsIntroducedToday: map['newCardsIntroducedToday'] ?? 0,
      challengeStartDate: map['challengeStartDate'],
      completedLessonDays: List<int>.from(map['completedLessonDays'] ?? const []),
      lessonSetId: map['lessonSetId'],
      deckCreatedDate: map['deckCreatedDate'],
      // A deck saved before this field existed that already has review
      // history is clearly not "first use" - default it to already-shown
      // rather than surprising a returning user with a tutorial slide.
      hasShownAnswerIntro: map['hasShownAnswerIntro'] ?? cards.any((c) => c.nextReviewDate != null),
    );
  }
}

// Deep-copies [original] (its cards included, exactly as they currently
// stand - progress and all) under a name that doesn't collide with any deck
// in [existingDecks].
StudyDeck duplicateDeck(StudyDeck original, List<StudyDeck> existingDecks) {
  String name = '${original.name} (Copy)';
  int copy = 2;
  while (existingDecks.any((d) => d.name == name)) {
    name = '${original.name} (Copy $copy)';
    copy++;
  }
  return StudyDeck(
    name: name,
    cards: original.cards.map((c) => StudyCard.fromMap(c.toMap())).toList(),
    newCardsPerDay: original.newCardsPerDay,
    newCardsIntroducedDate: original.newCardsIntroducedDate,
    newCardsIntroducedToday: original.newCardsIntroducedToday,
    challengeStartDate: original.challengeStartDate,
    completedLessonDays: List<int>.from(original.completedLessonDays),
    lessonSetId: original.lessonSetId,
    deckCreatedDate: original.deckCreatedDate,
    hasShownAnswerIntro: original.hasShownAnswerIntro,
  );
}

// Reverts every card in [deck] to "new" and clears the deck's own
// daily/challenge tracking - a full "reset deck progress." A challenge
// deck's schedule restarts from day 1 as of today.
void resetDeckProgress(StudyDeck deck) {
  for (final card in deck.cards) {
    resetCardProgress(card);
  }
  deck.newCardsIntroducedDate = null;
  deck.newCardsIntroducedToday = 0;
  if (deck.challengeStartDate != null) {
    deck.challengeStartDate = todayStamp();
    deck.completedLessonDays.clear();
  } else if (deck.deckCreatedDate != null) {
    deck.deckCreatedDate = todayStamp();
    deck.completedLessonDays.clear();
  }
}
