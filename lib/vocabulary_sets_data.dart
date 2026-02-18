class VocabularyItem {
  String japanese;
  String reading;
  String translation;
  String itemType; // 'Kanji' or 'Vocab'
  String? strokeOrder; // Used when itemType is 'Kanji'
  String? kanjiVGCode; // Used when itemType is 'Kanji'

  VocabularyItem({
    required this.japanese,
    required this.reading,
    required this.translation,
    this.itemType = 'Vocab',
    this.strokeOrder,
    this.kanjiVGCode,
  });
}

class VocabularySet {
  String name;
  final List<VocabularyItem> items;
  List<String> tags;
  bool displayInDictionary;
  String setType;
  bool displayInWritingArcade;
  bool displayInReadingArcade;

  VocabularySet({
    required this.name,
    required this.items,
    this.tags = const [],
    this.displayInDictionary = true,
    this.setType = 'Uncategorised',
    this.displayInWritingArcade = true,
    this.displayInReadingArcade = true,
  });
}

final Map<String, VocabularySet> vocabularySetsData = {
  'Essential Vocabulary': VocabularySet(
    name: 'Essential Vocabulary',
    setType: 'Vocab',
    displayInWritingArcade: false,
    items: [
      VocabularyItem(japanese: 'こんにちは', reading: 'konnichiwa', translation: 'Hello/Good afternoon'),
      VocabularyItem(japanese: 'ありがとう', reading: 'arigatou', translation: 'Thank you'),
      VocabularyItem(japanese: 'すみません', reading: 'sumimasen', translation: 'Excuse me/Sorry'),
      VocabularyItem(japanese: 'おはよう', reading: 'ohayou', translation: 'Good morning'),
      VocabularyItem(japanese: 'こんばんは', reading: 'konbanwa', translation: 'Good evening'),
    ],
  ),
  'JLPT N5 Vocabulary': VocabularySet(
    name: 'JLPT N5 Vocabulary',
    tags: ['JLPT N5'],
    setType: 'Vocab',
    displayInWritingArcade: false,
    items: [
      VocabularyItem(japanese: '学生', reading: 'がくせい (gakusei)', translation: 'Student'),
      VocabularyItem(japanese: '先生', reading: 'せんせい (sensei)', translation: 'Teacher'),
      VocabularyItem(japanese: '本', reading: 'ほん (hon)', translation: 'Book'),
      VocabularyItem(japanese: '食べる', reading: 'たべる (taberu)', translation: 'To eat'),
      VocabularyItem(japanese: '飲む', reading: 'のむ (nomu)', translation: 'To drink'),
    ],
  ),
  'JLPT N4 Vocabulary': VocabularySet(
    name: 'JLPT N4 Vocabulary',
    tags: ['JLPT N4'],
    setType: 'Vocab',
    displayInWritingArcade: false,
    items: [
      VocabularyItem(japanese: '準備', reading: 'じゅんび (junbi)', translation: 'Preparation'),
      VocabularyItem(japanese: '経験', reading: 'けいけん (keiken)', translation: 'Experience'),
      VocabularyItem(japanese: '説明', reading: 'せつめい (setsumei)', translation: 'Explanation'),
    ],
  ),
  'JLPT N3 Vocabulary': VocabularySet(
    name: 'JLPT N3 Vocabulary',
    tags: ['JLPT N3'],
    setType: 'Vocab',
    displayInWritingArcade: false,
    items: [
      VocabularyItem(japanese: '確認', reading: 'かくにん (kakunin)', translation: 'Confirmation'),
      VocabularyItem(japanese: '印象', reading: 'いんしょう (inshou)', translation: 'Impression'),
      VocabularyItem(japanese: '影響', reading: 'えいきょう (eikyou)', translation: 'Influence'),
    ],
  ),
  'JLPT N2 Vocabulary': VocabularySet(
    name: 'JLPT N2 Vocabulary',
    tags: ['JLPT N2'],
    setType: 'Vocab',
    displayInWritingArcade: false,
    items: [
      VocabularyItem(japanese: '把握', reading: 'はあく (haaku)', translation: 'Grasp/Understanding'),
      VocabularyItem(japanese: '傾向', reading: 'けいこう (keikou)', translation: 'Tendency'),
      VocabularyItem(japanese: '著しい', reading: 'いちじるしい (ichijirushii)', translation: 'Remarkable/Notable'),
    ],
  ),
  'Keigo Verbs': VocabularySet(
    name: 'Keigo Verbs',
    setType: 'Vocab',
    displayInWritingArcade: false,
    items: [
      VocabularyItem(japanese: 'いらっしゃる', reading: 'irassharu', translation: 'To be/go/come (honorific)'),
      VocabularyItem(japanese: 'おっしゃる', reading: 'ossharu', translation: 'To say (honorific)'),
      VocabularyItem(japanese: 'いただく', reading: 'itadaku', translation: 'To receive (humble)'),
      VocabularyItem(japanese: '申し上げる', reading: 'もうしあげる (moushiageru)', translation: 'To say (humble)'),
      VocabularyItem(japanese: '伺う', reading: 'うかがう (ukagau)', translation: 'To visit/ask (humble)'),
    ],
  ),
};

