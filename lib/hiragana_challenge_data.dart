import 'study_data.dart';

const String hiraganaChallengeDeckName = 'Hiragana Challenge';

// One example word shown for a Hiragana Challenge character: written in pure
// hiragana - all a beginner can actually read at this stage - with its
// common kanji spelling shown in brackets when it has one, as a preview of
// what they'll meet later in the 90 Day Kanji Challenge. Loanwords,
// onomatopoeia, and words whose kanji is rare or archaic in modern writing
// are left without one, since teaching a spelling nobody actually uses would
// do more harm than good.
class ChallengeKanaWord {
  final String hiragana;
  final String? kanji;
  final String romaji;
  final String english;

  const ChallengeKanaWord({
    required this.hiragana,
    this.kanji,
    required this.romaji,
    required this.english,
  });

  String get displayJapanese => kanji == null ? hiragana : '$hiragana（$kanji）';
}

// One kana character's authored content for the Hiragana Challenge: its
// reading and a couple of example words that use it. Despite the field name
// (kept as-is rather than mechanically renamed across ~500 lines of data),
// this holds a katakana character for every day from day 9 onward - see
// hiraganaChallengeDays below.
class ChallengeKana {
  final String hiragana;
  final String romaji;
  final List<ChallengeKanaWord> words;

  const ChallengeKana({
    required this.hiragana,
    required this.romaji,
    this.words = const [],
  });
}

// One "row" of hiragana introduced together within a day - e.g. the five
// vowels, then the k-row, each its own set. Every set is drilled as a whole
// unit before the next one starts: first every character in the set (as its
// own context slide, then a writing-practice flashcard prompted by its
// sound), then every example word for that whole set (context slide, then
// flashcard), then the next set. See buildHiraganaChallengeDeck.
class ChallengeKanaSet {
  final List<ChallengeKana> kana;
  const ChallengeKanaSet(this.kana);
}

// Each entry is one day's newly-introduced kana, grouped into the same
// row-based sets the lesson videos use (vowels then k-row on day 1, s-row
// then t-row on day 2, and so on through the dakuten/handakuten rows - a
// short row day only has one set). Days 1-8 are hiragana; day 9 onward is
// katakana, covering the exact same rows a second time in the second
// script (see ChallengeKana's own doc comment - the field is still named
// `hiragana` even where it holds a katakana character, to avoid a mechanical
// rename across this whole file).
final List<List<ChallengeKanaSet>> hiraganaChallengeDays = [
  // Day 1 - vowels & k-row
  [
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'あ', romaji: 'a', words: [
        ChallengeKanaWord(hiragana: 'あめ', kanji: '雨', romaji: 'a me', english: 'Rain'),
        ChallengeKanaWord(hiragana: 'あさ', kanji: '朝', romaji: 'a sa', english: 'Morning'),
      ]),
      ChallengeKana(hiragana: 'い', romaji: 'i', words: [
        ChallengeKanaWord(hiragana: 'いぬ', kanji: '犬', romaji: 'i nu', english: 'Dog'),
        ChallengeKanaWord(hiragana: 'いえ', kanji: '家', romaji: 'i e', english: 'House'),
      ]),
      ChallengeKana(hiragana: 'う', romaji: 'u', words: [
        ChallengeKanaWord(hiragana: 'うみ', kanji: '海', romaji: 'u mi', english: 'Sea'),
        ChallengeKanaWord(hiragana: 'うた', kanji: '歌', romaji: 'u ta', english: 'Song'),
      ]),
      ChallengeKana(hiragana: 'え', romaji: 'e', words: [
        ChallengeKanaWord(hiragana: 'えき', kanji: '駅', romaji: 'e ki', english: 'Station'),
        ChallengeKanaWord(hiragana: 'えんぴつ', kanji: '鉛筆', romaji: 'en pi tsu', english: 'Pencil'),
      ]),
      ChallengeKana(hiragana: 'お', romaji: 'o', words: [
        ChallengeKanaWord(hiragana: 'おかね', kanji: 'お金', romaji: 'o ka ne', english: 'Money'),
        ChallengeKanaWord(hiragana: 'おちゃ', kanji: 'お茶', romaji: 'o cha', english: 'Tea'),
      ]),
    ]),
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'か', romaji: 'ka', words: [
        ChallengeKanaWord(hiragana: 'かわ', kanji: '川', romaji: 'ka wa', english: 'River'),
        ChallengeKanaWord(hiragana: 'かさ', kanji: '傘', romaji: 'ka sa', english: 'Umbrella'),
      ]),
      ChallengeKana(hiragana: 'き', romaji: 'ki', words: [
        ChallengeKanaWord(hiragana: 'きた', kanji: '北', romaji: 'ki ta', english: 'North'),
        ChallengeKanaWord(hiragana: 'きく', kanji: '聞く', romaji: 'ki ku', english: 'To listen'),
      ]),
      ChallengeKana(hiragana: 'く', romaji: 'ku', words: [
        ChallengeKanaWord(hiragana: 'くるま', kanji: '車', romaji: 'ku ru ma', english: 'Car'),
        ChallengeKanaWord(hiragana: 'くも', kanji: '雲', romaji: 'ku mo', english: 'Cloud'),
      ]),
      ChallengeKana(hiragana: 'け', romaji: 'ke', words: [
        ChallengeKanaWord(hiragana: 'けむり', kanji: '煙', romaji: 'ke mu ri', english: 'Smoke'),
        ChallengeKanaWord(hiragana: 'けしき', kanji: '景色', romaji: 'ke shi ki', english: 'Scenery'),
      ]),
      ChallengeKana(hiragana: 'こ', romaji: 'ko', words: [
        ChallengeKanaWord(hiragana: 'こども', kanji: '子供', romaji: 'ko do mo', english: 'Child'),
        ChallengeKanaWord(hiragana: 'ことり', kanji: '小鳥', romaji: 'ko to ri', english: 'Little bird'),
      ]),
    ]),
  ],
  // Day 2 - s-row & t-row
  [
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'さ', romaji: 'sa', words: [
        ChallengeKanaWord(hiragana: 'さくら', kanji: '桜', romaji: 'sa ku ra', english: 'Cherry blossom'),
        ChallengeKanaWord(hiragana: 'さかな', kanji: '魚', romaji: 'sa ka na', english: 'Fish'),
      ]),
      ChallengeKana(hiragana: 'し', romaji: 'shi', words: [
        ChallengeKanaWord(hiragana: 'しろ', kanji: '白', romaji: 'shi ro', english: 'White'),
        ChallengeKanaWord(hiragana: 'しま', kanji: '島', romaji: 'shi ma', english: 'Island'),
      ]),
      ChallengeKana(hiragana: 'す', romaji: 'su', words: [
        ChallengeKanaWord(hiragana: 'すいか', romaji: 'su i ka', english: 'Watermelon'),
        ChallengeKanaWord(hiragana: 'すな', kanji: '砂', romaji: 'su na', english: 'Sand'),
      ]),
      ChallengeKana(hiragana: 'せ', romaji: 'se', words: [
        ChallengeKanaWord(hiragana: 'せかい', kanji: '世界', romaji: 'se ka i', english: 'World'),
        ChallengeKanaWord(hiragana: 'せんせい', kanji: '先生', romaji: 'sen sei', english: 'Teacher'),
      ]),
      ChallengeKana(hiragana: 'そ', romaji: 'so', words: [
        ChallengeKanaWord(hiragana: 'そら', kanji: '空', romaji: 'so ra', english: 'Sky'),
        ChallengeKanaWord(hiragana: 'そうじ', kanji: '掃除', romaji: 'sou ji', english: 'Cleaning'),
      ]),
    ]),
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'た', romaji: 'ta', words: [
        ChallengeKanaWord(hiragana: 'たまご', kanji: '卵', romaji: 'ta ma go', english: 'Egg'),
        ChallengeKanaWord(hiragana: 'たに', kanji: '谷', romaji: 'ta ni', english: 'Valley'),
      ]),
      ChallengeKana(hiragana: 'ち', romaji: 'chi', words: [
        ChallengeKanaWord(hiragana: 'ちず', kanji: '地図', romaji: 'chi zu', english: 'Map'),
        ChallengeKanaWord(hiragana: 'ちかてつ', kanji: '地下鉄', romaji: 'chi ka te tsu', english: 'Subway'),
      ]),
      ChallengeKana(hiragana: 'つ', romaji: 'tsu', words: [
        ChallengeKanaWord(hiragana: 'つき', kanji: '月', romaji: 'tsu ki', english: 'Moon'),
        ChallengeKanaWord(hiragana: 'つくえ', kanji: '机', romaji: 'tsu ku e', english: 'Desk'),
      ]),
      ChallengeKana(hiragana: 'て', romaji: 'te', words: [
        ChallengeKanaWord(hiragana: 'てがみ', kanji: '手紙', romaji: 'te ga mi', english: 'Letter'),
        ChallengeKanaWord(hiragana: 'てんき', kanji: '天気', romaji: 'ten ki', english: 'Weather'),
      ]),
      ChallengeKana(hiragana: 'と', romaji: 'to', words: [
        ChallengeKanaWord(hiragana: 'とり', kanji: '鳥', romaji: 'to ri', english: 'Bird'),
        ChallengeKanaWord(hiragana: 'とけい', kanji: '時計', romaji: 'to ke i', english: 'Clock'),
      ]),
    ]),
  ],
  // Day 3 - n-row & h-row
  [
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'な', romaji: 'na', words: [
        ChallengeKanaWord(hiragana: 'なつ', kanji: '夏', romaji: 'na tsu', english: 'Summer'),
        ChallengeKanaWord(hiragana: 'なまえ', kanji: '名前', romaji: 'na ma e', english: 'Name'),
      ]),
      ChallengeKana(hiragana: 'に', romaji: 'ni', words: [
        ChallengeKanaWord(hiragana: 'にく', kanji: '肉', romaji: 'ni ku', english: 'Meat'),
        ChallengeKanaWord(hiragana: 'にほん', kanji: '日本', romaji: 'ni hon', english: 'Japan'),
      ]),
      ChallengeKana(hiragana: 'ぬ', romaji: 'nu', words: [
        ChallengeKanaWord(hiragana: 'ぬの', kanji: '布', romaji: 'nu no', english: 'Cloth'),
        ChallengeKanaWord(hiragana: 'ぬりえ', kanji: '塗り絵', romaji: 'nu ri e', english: 'Coloring book'),
      ]),
      ChallengeKana(hiragana: 'ね', romaji: 'ne', words: [
        ChallengeKanaWord(hiragana: 'ねこ', kanji: '猫', romaji: 'ne ko', english: 'Cat'),
        ChallengeKanaWord(hiragana: 'ねだん', kanji: '値段', romaji: 'ne dan', english: 'Price'),
      ]),
      ChallengeKana(hiragana: 'の', romaji: 'no', words: [
        ChallengeKanaWord(hiragana: 'のり', kanji: '海苔', romaji: 'no ri', english: 'Seaweed'),
        ChallengeKanaWord(hiragana: 'のうえ', romaji: 'no u e', english: 'On top'),
      ]),
    ]),
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'は', romaji: 'ha', words: [
        ChallengeKanaWord(hiragana: 'はな', kanji: '花', romaji: 'ha na', english: 'Flower'),
        ChallengeKanaWord(hiragana: 'はれ', kanji: '晴れ', romaji: 'ha re', english: 'Sunny'),
      ]),
      ChallengeKana(hiragana: 'ひ', romaji: 'hi', words: [
        ChallengeKanaWord(hiragana: 'ひかり', kanji: '光', romaji: 'hi ka ri', english: 'Light'),
        ChallengeKanaWord(hiragana: 'ひつじ', kanji: '羊', romaji: 'hi tsu ji', english: 'Sheep'),
      ]),
      ChallengeKana(hiragana: 'ふ', romaji: 'fu', words: [
        ChallengeKanaWord(hiragana: 'ふね', kanji: '船', romaji: 'fu ne', english: 'Boat'),
        ChallengeKanaWord(hiragana: 'ふゆ', kanji: '冬', romaji: 'fu yu', english: 'Winter'),
      ]),
      ChallengeKana(hiragana: 'へ', romaji: 'he', words: [
        ChallengeKanaWord(hiragana: 'へや', kanji: '部屋', romaji: 'he ya', english: 'Room'),
        ChallengeKanaWord(hiragana: 'へび', kanji: '蛇', romaji: 'he bi', english: 'Snake'),
      ]),
      ChallengeKana(hiragana: 'ほ', romaji: 'ho', words: [
        ChallengeKanaWord(hiragana: 'ほし', kanji: '星', romaji: 'ho shi', english: 'Star'),
        ChallengeKanaWord(hiragana: 'ほね', kanji: '骨', romaji: 'ho ne', english: 'Bone'),
      ]),
    ]),
  ],
  // Day 4 - m-row & y-row
  [
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'ま', romaji: 'ma', words: [
        ChallengeKanaWord(hiragana: 'まど', kanji: '窓', romaji: 'ma do', english: 'Window'),
        ChallengeKanaWord(hiragana: 'まち', kanji: '町', romaji: 'ma chi', english: 'Town'),
      ]),
      ChallengeKana(hiragana: 'み', romaji: 'mi', words: [
        ChallengeKanaWord(hiragana: 'みず', kanji: '水', romaji: 'mi zu', english: 'Water'),
        ChallengeKanaWord(hiragana: 'みみ', kanji: '耳', romaji: 'mi mi', english: 'Ear'),
      ]),
      ChallengeKana(hiragana: 'む', romaji: 'mu', words: [
        ChallengeKanaWord(hiragana: 'むし', kanji: '虫', romaji: 'mu shi', english: 'Insect'),
        ChallengeKanaWord(hiragana: 'むね', kanji: '胸', romaji: 'mu ne', english: 'Chest'),
      ]),
      ChallengeKana(hiragana: 'め', romaji: 'me', words: [
        ChallengeKanaWord(hiragana: 'めがね', kanji: '眼鏡', romaji: 'me ga ne', english: 'Glasses'),
        ChallengeKanaWord(hiragana: 'め', kanji: '目', romaji: 'me', english: 'Eye'),
      ]),
      ChallengeKana(hiragana: 'も', romaji: 'mo', words: [
        ChallengeKanaWord(hiragana: 'もり', kanji: '森', romaji: 'mo ri', english: 'Forest'),
        ChallengeKanaWord(hiragana: 'もも', kanji: '桃', romaji: 'mo mo', english: 'Peach'),
      ]),
    ]),
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'や', romaji: 'ya', words: [
        ChallengeKanaWord(hiragana: 'やま', kanji: '山', romaji: 'ya ma', english: 'Mountain'),
        ChallengeKanaWord(hiragana: 'やさい', kanji: '野菜', romaji: 'ya sa i', english: 'Vegetable'),
      ]),
      ChallengeKana(hiragana: 'ゆ', romaji: 'yu', words: [
        ChallengeKanaWord(hiragana: 'ゆき', kanji: '雪', romaji: 'yu ki', english: 'Snow'),
        ChallengeKanaWord(hiragana: 'ゆめ', kanji: '夢', romaji: 'yu me', english: 'Dream'),
      ]),
      ChallengeKana(hiragana: 'よ', romaji: 'yo', words: [
        ChallengeKanaWord(hiragana: 'よる', kanji: '夜', romaji: 'yo ru', english: 'Night'),
        ChallengeKanaWord(hiragana: 'よこ', kanji: '横', romaji: 'yo ko', english: 'Side'),
      ]),
    ]),
  ],
  // Day 5 - r-row & w-row (incl. ん)
  [
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'ら', romaji: 'ra', words: [
        ChallengeKanaWord(hiragana: 'らいおん', romaji: 'ra i o n', english: 'Lion'),
        ChallengeKanaWord(hiragana: 'らん', kanji: '蘭', romaji: 'ran', english: 'Orchid'),
      ]),
      ChallengeKana(hiragana: 'り', romaji: 'ri', words: [
        ChallengeKanaWord(hiragana: 'りんご', romaji: 'rin go', english: 'Apple'),
        ChallengeKanaWord(hiragana: 'りす', romaji: 'ri su', english: 'Squirrel'),
      ]),
      ChallengeKana(hiragana: 'る', romaji: 'ru', words: [
        ChallengeKanaWord(hiragana: 'るす', kanji: '留守', romaji: 'ru su', english: 'Absence'),
        ChallengeKanaWord(hiragana: 'るり', kanji: '瑠璃', romaji: 'ru ri', english: 'Lapis lazuli'),
      ]),
      ChallengeKana(hiragana: 'れ', romaji: 're', words: [
        ChallengeKanaWord(hiragana: 'れいぞうこ', kanji: '冷蔵庫', romaji: 're i zou ko', english: 'Refrigerator'),
        ChallengeKanaWord(hiragana: 'れきし', kanji: '歴史', romaji: 're ki shi', english: 'History'),
      ]),
      ChallengeKana(hiragana: 'ろ', romaji: 'ro', words: [
        ChallengeKanaWord(hiragana: 'ろうそく', romaji: 'rou so ku', english: 'Candle'),
        ChallengeKanaWord(hiragana: 'ろば', romaji: 'ro ba', english: 'Donkey'),
      ]),
    ]),
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'わ', romaji: 'wa', words: [
        ChallengeKanaWord(hiragana: 'わに', romaji: 'wa ni', english: 'Crocodile'),
        ChallengeKanaWord(hiragana: 'わたし', kanji: '私', romaji: 'wa ta shi', english: 'I / Me'),
      ]),
      ChallengeKana(hiragana: 'を', romaji: 'wo (o)', words: [
        ChallengeKanaWord(hiragana: 'をかし', romaji: 'wo ka shi', english: 'Sweets (archaic spelling)'),
        ChallengeKanaWord(hiragana: 'をのこ', romaji: 'wo no ko', english: 'Boy (archaic spelling)'),
      ]),
      ChallengeKana(hiragana: 'ん', romaji: 'n', words: [
        ChallengeKanaWord(hiragana: 'ほん', kanji: '本', romaji: 'ho n', english: 'Book'),
        ChallengeKanaWord(hiragana: 'ねこ', kanji: '猫', romaji: 'ne ko', english: 'Cat'),
      ]),
    ]),
  ],
  // Day 6 - g-row & z-row (dakuten)
  [
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'が', romaji: 'ga', words: [
        ChallengeKanaWord(hiragana: 'がっこう', kanji: '学校', romaji: 'ga kko u', english: 'School'),
        ChallengeKanaWord(hiragana: 'がいこく', kanji: '外国', romaji: 'ga i ko ku', english: 'Foreign country'),
      ]),
      ChallengeKana(hiragana: 'ぎ', romaji: 'gi', words: [
        ChallengeKanaWord(hiragana: 'ぎゅうにゅう', kanji: '牛乳', romaji: 'gyuu nyuu', english: 'Milk'),
        ChallengeKanaWord(hiragana: 'ぎんこう', kanji: '銀行', romaji: 'gin kou', english: 'Bank'),
      ]),
      ChallengeKana(hiragana: 'ぐ', romaji: 'gu', words: [
        ChallengeKanaWord(hiragana: 'ぐん', kanji: '軍', romaji: 'gu n', english: 'Army'),
        ChallengeKanaWord(hiragana: 'ぐあい', kanji: '具合', romaji: 'gu a i', english: 'Condition'),
      ]),
      ChallengeKana(hiragana: 'げ', romaji: 'ge', words: [
        ChallengeKanaWord(hiragana: 'げんき', kanji: '元気', romaji: 'gen ki', english: 'Healthy'),
        ChallengeKanaWord(hiragana: 'げつようび', kanji: '月曜日', romaji: 'ge tsu you bi', english: 'Monday'),
      ]),
      ChallengeKana(hiragana: 'ご', romaji: 'go', words: [
        ChallengeKanaWord(hiragana: 'ごはん', kanji: 'ご飯', romaji: 'go ha n', english: 'Rice / Meal'),
        ChallengeKanaWord(hiragana: 'ごご', kanji: '午後', romaji: 'go go', english: 'Afternoon'),
      ]),
    ]),
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'ざ', romaji: 'za', words: [
        ChallengeKanaWord(hiragana: 'ざっし', kanji: '雑誌', romaji: 'za sshi', english: 'Magazine'),
        ChallengeKanaWord(hiragana: 'ざる', romaji: 'za ru', english: 'Bamboo basket'),
      ]),
      ChallengeKana(hiragana: 'じ', romaji: 'ji', words: [
        ChallengeKanaWord(hiragana: 'じかん', kanji: '時間', romaji: 'ji ka n', english: 'Time'),
        ChallengeKanaWord(hiragana: 'じしょ', kanji: '辞書', romaji: 'ji sho', english: 'Dictionary'),
      ]),
      ChallengeKana(hiragana: 'ず', romaji: 'zu', words: [
        ChallengeKanaWord(hiragana: 'ずぼん', romaji: 'zu bo n', english: 'Pants'),
        ChallengeKanaWord(hiragana: 'ずかん', kanji: '図鑑', romaji: 'zu ka n', english: 'Picture book'),
      ]),
      ChallengeKana(hiragana: 'ぜ', romaji: 'ze', words: [
        ChallengeKanaWord(hiragana: 'ぜんぶ', kanji: '全部', romaji: 'ze n bu', english: 'All / Everything'),
        ChallengeKanaWord(hiragana: 'ぜったい', kanji: '絶対', romaji: 'ze tta i', english: 'Absolutely'),
      ]),
      ChallengeKana(hiragana: 'ぞ', romaji: 'zo', words: [
        ChallengeKanaWord(hiragana: 'ぞう', kanji: '象', romaji: 'zo u', english: 'Elephant'),
        ChallengeKanaWord(hiragana: 'ぞく', kanji: '族', romaji: 'zo ku', english: 'Family / Tribe'),
      ]),
    ]),
  ],
  // Day 7 - d-row & b-row (dakuten)
  [
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'だ', romaji: 'da', words: [
        ChallengeKanaWord(hiragana: 'だいがく', kanji: '大学', romaji: 'da i ga ku', english: 'University'),
        ChallengeKanaWord(hiragana: 'だれ', kanji: '誰', romaji: 'da re', english: 'Who'),
      ]),
      ChallengeKana(hiragana: 'ぢ', romaji: 'ji (di)', words: [
        ChallengeKanaWord(hiragana: 'ぢかん', romaji: 'ji ka n', english: 'Time (rare use)'),
        ChallengeKanaWord(hiragana: 'はなぢ', kanji: '鼻血', romaji: 'ha na ji', english: 'Nosebleed'),
      ]),
      ChallengeKana(hiragana: 'づ', romaji: 'zu (du)', words: [
        ChallengeKanaWord(hiragana: 'つづく', kanji: '続く', romaji: 'tsu zu ku', english: 'To continue'),
        ChallengeKanaWord(hiragana: 'みづ', romaji: 'mi zu', english: 'Water (archaic spelling)'),
      ]),
      ChallengeKana(hiragana: 'で', romaji: 'de', words: [
        ChallengeKanaWord(hiragana: 'できる', romaji: 'de ki ru', english: 'Can / Able to'),
        ChallengeKanaWord(hiragana: 'でぐち', kanji: '出口', romaji: 'de gu chi', english: 'Exit'),
      ]),
      ChallengeKana(hiragana: 'ど', romaji: 'do', words: [
        ChallengeKanaWord(hiragana: 'どようび', kanji: '土曜日', romaji: 'do you bi', english: 'Saturday'),
        ChallengeKanaWord(hiragana: 'どあ', romaji: 'do a', english: 'Door'),
      ]),
    ]),
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'ば', romaji: 'ba', words: [
        ChallengeKanaWord(hiragana: 'ばら', romaji: 'ba ra', english: 'Rose'),
        ChallengeKanaWord(hiragana: 'ばす', romaji: 'ba su', english: 'Bus'),
      ]),
      ChallengeKana(hiragana: 'び', romaji: 'bi', words: [
        ChallengeKanaWord(hiragana: 'びょういん', kanji: '病院', romaji: 'byou in', english: 'Hospital'),
        ChallengeKanaWord(hiragana: 'びーる', romaji: 'bi i ru', english: 'Beer'),
      ]),
      ChallengeKana(hiragana: 'ぶ', romaji: 'bu', words: [
        ChallengeKanaWord(hiragana: 'ぶた', kanji: '豚', romaji: 'bu ta', english: 'Pig'),
        ChallengeKanaWord(hiragana: 'ぶんか', kanji: '文化', romaji: 'bun ka', english: 'Culture'),
      ]),
      ChallengeKana(hiragana: 'べ', romaji: 'be', words: [
        ChallengeKanaWord(hiragana: 'べんとう', kanji: '弁当', romaji: 'ben tou', english: 'Lunchbox'),
        ChallengeKanaWord(hiragana: 'べる', romaji: 'be ru', english: 'Bell'),
      ]),
      ChallengeKana(hiragana: 'ぼ', romaji: 'bo', words: [
        ChallengeKanaWord(hiragana: 'ぼうし', kanji: '帽子', romaji: 'bou shi', english: 'Hat'),
        ChallengeKanaWord(hiragana: 'ぼく', kanji: '僕', romaji: 'bo ku', english: 'I / Me (used by males)'),
      ]),
    ]),
  ],
  // Day 8 - p-row (handakuten) - just one row, no second set
  [
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'ぱ', romaji: 'pa', words: [
        ChallengeKanaWord(hiragana: 'ぱん', romaji: 'pa n', english: 'Bread'),
        ChallengeKanaWord(hiragana: 'ぱんだ', romaji: 'pa n da', english: 'Panda'),
      ]),
      ChallengeKana(hiragana: 'ぴ', romaji: 'pi', words: [
        ChallengeKanaWord(hiragana: 'ぴあの', romaji: 'pi a no', english: 'Piano'),
        ChallengeKanaWord(hiragana: 'ぴくにっく', romaji: 'pi ku nik ku', english: 'Picnic'),
      ]),
      ChallengeKana(hiragana: 'ぷ', romaji: 'pu', words: [
        ChallengeKanaWord(hiragana: 'ぷーる', romaji: 'pu u ru', english: 'Pool'),
        ChallengeKanaWord(hiragana: 'ぷりん', romaji: 'pu rin', english: 'Pudding'),
      ]),
      ChallengeKana(hiragana: 'ぺ', romaji: 'pe', words: [
        ChallengeKanaWord(hiragana: 'ぺん', romaji: 'pe n', english: 'Pen'),
        ChallengeKanaWord(hiragana: 'ぺこぺこ', romaji: 'pe ko pe ko', english: 'Hungry'),
      ]),
      ChallengeKana(hiragana: 'ぽ', romaji: 'po', words: [
        ChallengeKanaWord(hiragana: 'ぽけっと', romaji: 'po ke tto', english: 'Pocket'),
        ChallengeKanaWord(hiragana: 'ぽすと', romaji: 'po su to', english: 'Postbox'),
      ]),
    ]),
  ],
  // Day 9 - katakana vowels & k-row
  [
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'ア', romaji: 'a', words: [
        ChallengeKanaWord(hiragana: 'アイス', romaji: 'a i su', english: 'Ice / Ice cream'),
        ChallengeKanaWord(hiragana: 'アメリカ', romaji: 'a me ri ka', english: 'America'),
      ]),
      ChallengeKana(hiragana: 'イ', romaji: 'i', words: [
        ChallengeKanaWord(hiragana: 'インク', romaji: 'i n ku', english: 'Ink'),
        ChallengeKanaWord(hiragana: 'イギリス', romaji: 'i gi ri su', english: 'UK / England'),
      ]),
      ChallengeKana(hiragana: 'ウ', romaji: 'u', words: [
        ChallengeKanaWord(hiragana: 'ウサギ', romaji: 'u sa gi', english: 'Rabbit'),
        ChallengeKanaWord(hiragana: 'ウインドウ', romaji: 'u i n do u', english: 'Window'),
      ]),
      ChallengeKana(hiragana: 'エ', romaji: 'e', words: [
        ChallengeKanaWord(hiragana: 'エビ', romaji: 'e bi', english: 'Shrimp'),
        ChallengeKanaWord(hiragana: 'エンジン', romaji: 'e n ji n', english: 'Engine'),
      ]),
      ChallengeKana(hiragana: 'オ', romaji: 'o', words: [
        ChallengeKanaWord(hiragana: 'オレンジ', romaji: 'o re n ji', english: 'Orange'),
        ChallengeKanaWord(hiragana: 'オオカミ', kanji: '狼', romaji: 'o o ka mi', english: 'Wolf'),
      ]),
    ]),
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'カ', romaji: 'ka', words: [
        ChallengeKanaWord(hiragana: 'カメ', kanji: '亀', romaji: 'ka me', english: 'Turtle'),
        ChallengeKanaWord(hiragana: 'カレー', romaji: 'ka re e', english: 'Curry'),
      ]),
      ChallengeKana(hiragana: 'キ', romaji: 'ki', words: [
        ChallengeKanaWord(hiragana: 'キリン', romaji: 'ki ri n', english: 'Giraffe'),
        ChallengeKanaWord(hiragana: 'キッチン', romaji: 'ki tchin', english: 'Kitchen'),
      ]),
      ChallengeKana(hiragana: 'ク', romaji: 'ku', words: [
        ChallengeKanaWord(hiragana: 'クマ', kanji: '熊', romaji: 'ku ma', english: 'Bear'),
        ChallengeKanaWord(hiragana: 'クラス', romaji: 'ku ra su', english: 'Class'),
      ]),
      ChallengeKana(hiragana: 'ケ', romaji: 'ke', words: [
        ChallengeKanaWord(hiragana: 'ケーキ', romaji: 'ke e ki', english: 'Cake'),
        ChallengeKanaWord(hiragana: 'ケガ', kanji: '怪我', romaji: 'ke ga', english: 'Injury'),
      ]),
      ChallengeKana(hiragana: 'コ', romaji: 'ko', words: [
        ChallengeKanaWord(hiragana: 'コーヒー', romaji: 'ko o hii', english: 'Coffee'),
        ChallengeKanaWord(hiragana: 'コアラ', romaji: 'ko a ra', english: 'Koala'),
      ]),
    ]),
  ],
  // Day 10 - katakana s-row & t-row
  [
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'サ', romaji: 'sa', words: [
        ChallengeKanaWord(hiragana: 'サル', kanji: '猿', romaji: 'sa ru', english: 'Monkey'),
        ChallengeKanaWord(hiragana: 'サンドイッチ', romaji: 'sa n do i tchi', english: 'Sandwich'),
      ]),
      ChallengeKana(hiragana: 'シ', romaji: 'shi', words: [
        ChallengeKanaWord(hiragana: 'シカ', kanji: '鹿', romaji: 'shi ka', english: 'Deer'),
        ChallengeKanaWord(hiragana: 'シャツ', romaji: 'sha tsu', english: 'Shirt'),
      ]),
      ChallengeKana(hiragana: 'ス', romaji: 'su', words: [
        ChallengeKanaWord(hiragana: 'スイカ', romaji: 'su i ka', english: 'Watermelon'),
        ChallengeKanaWord(hiragana: 'スープ', romaji: 'su u pu', english: 'Soup'),
      ]),
      ChallengeKana(hiragana: 'セ', romaji: 'se', words: [
        ChallengeKanaWord(hiragana: 'セミ', romaji: 'se mi', english: 'Cicada'),
        ChallengeKanaWord(hiragana: 'セーター', romaji: 'se e taa', english: 'Sweater'),
      ]),
      ChallengeKana(hiragana: 'ソ', romaji: 'so', words: [
        ChallengeKanaWord(hiragana: 'ソファ', romaji: 'so fa', english: 'Sofa'),
        ChallengeKanaWord(hiragana: 'ソース', romaji: 'so o su', english: 'Sauce'),
      ]),
    ]),
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'タ', romaji: 'ta', words: [
        ChallengeKanaWord(hiragana: 'タコ', romaji: 'ta ko', english: 'Octopus'),
        ChallengeKanaWord(hiragana: 'タオル', romaji: 'ta o ru', english: 'Towel'),
      ]),
      ChallengeKana(hiragana: 'チ', romaji: 'chi', words: [
        ChallengeKanaWord(hiragana: 'チーズ', romaji: 'chi i zu', english: 'Cheese'),
        ChallengeKanaWord(hiragana: 'チカテツ', kanji: '地下鉄', romaji: 'chi ka te tsu', english: 'Subway'),
      ]),
      ChallengeKana(hiragana: 'ツ', romaji: 'tsu', words: [
        ChallengeKanaWord(hiragana: 'ツバメ', romaji: 'tsu ba me', english: 'Swallow (bird)'),
        ChallengeKanaWord(hiragana: 'ツリー', romaji: 'tsu rii', english: 'Tree'),
      ]),
      ChallengeKana(hiragana: 'テ', romaji: 'te', words: [
        ChallengeKanaWord(hiragana: 'テーブル', romaji: 'te e bu ru', english: 'Table'),
        ChallengeKanaWord(hiragana: 'テスト', romaji: 'te su to', english: 'Test'),
      ]),
      ChallengeKana(hiragana: 'ト', romaji: 'to', words: [
        ChallengeKanaWord(hiragana: 'トマト', romaji: 'to ma to', english: 'Tomato'),
        ChallengeKanaWord(hiragana: 'トリ', kanji: '鳥', romaji: 'to ri', english: 'Bird'),
      ]),
    ]),
  ],
  // Day 11 - katakana n-row & h-row
  [
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'ナ', romaji: 'na', words: [
        ChallengeKanaWord(hiragana: 'ナイフ', romaji: 'na i fu', english: 'Knife'),
        ChallengeKanaWord(hiragana: 'ナス', kanji: '茄子', romaji: 'na su', english: 'Eggplant'),
      ]),
      ChallengeKana(hiragana: 'ニ', romaji: 'ni', words: [
        ChallengeKanaWord(hiragana: 'ニワトリ', kanji: '鶏', romaji: 'ni wa to ri', english: 'Chicken'),
        ChallengeKanaWord(hiragana: 'ニュース', romaji: 'nyu u su', english: 'News'),
      ]),
      ChallengeKana(hiragana: 'ヌ', romaji: 'nu', words: [
        ChallengeKanaWord(hiragana: 'ヌードル', romaji: 'nu u do ru', english: 'Noodle'),
        ChallengeKanaWord(hiragana: 'ヌー', romaji: 'nu u', english: 'Gnu (animal)'),
      ]),
      ChallengeKana(hiragana: 'ネ', romaji: 'ne', words: [
        ChallengeKanaWord(hiragana: 'ネコ', kanji: '猫', romaji: 'ne ko', english: 'Cat'),
        ChallengeKanaWord(hiragana: 'ネズミ', romaji: 'ne zu mi', english: 'Mouse'),
      ]),
      ChallengeKana(hiragana: 'ノ', romaji: 'no', words: [
        ChallengeKanaWord(hiragana: 'ノート', romaji: 'no o to', english: 'Notebook'),
        ChallengeKanaWord(hiragana: 'ノド', kanji: '喉', romaji: 'no do', english: 'Throat'),
      ]),
    ]),
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'ハ', romaji: 'ha', words: [
        ChallengeKanaWord(hiragana: 'ハート', romaji: 'ha a to', english: 'Heart'),
        ChallengeKanaWord(hiragana: 'ハチ', kanji: '蜂', romaji: 'ha chi', english: 'Bee'),
      ]),
      ChallengeKana(hiragana: 'ヒ', romaji: 'hi', words: [
        ChallengeKanaWord(hiragana: 'ヒツジ', kanji: '羊', romaji: 'hi tsu ji', english: 'Sheep'),
        ChallengeKanaWord(hiragana: 'ヒマワリ', romaji: 'hi ma wa ri', english: 'Sunflower'),
      ]),
      ChallengeKana(hiragana: 'フ', romaji: 'fu', words: [
        ChallengeKanaWord(hiragana: 'フルーツ', romaji: 'fu ru u tsu', english: 'Fruit'),
        ChallengeKanaWord(hiragana: 'フネ', kanji: '船', romaji: 'fu ne', english: 'Boat'),
      ]),
      ChallengeKana(hiragana: 'ヘ', romaji: 'he', words: [
        ChallengeKanaWord(hiragana: 'ヘビ', kanji: '蛇', romaji: 'he bi', english: 'Snake'),
        ChallengeKanaWord(hiragana: 'ヘヤ', kanji: '部屋', romaji: 'he ya', english: 'Room'),
      ]),
      ChallengeKana(hiragana: 'ホ', romaji: 'ho', words: [
        ChallengeKanaWord(hiragana: 'ホテル', romaji: 'ho te ru', english: 'Hotel'),
        ChallengeKanaWord(hiragana: 'ホシ', kanji: '星', romaji: 'ho shi', english: 'Star'),
      ]),
    ]),
  ],
  // Day 12 - katakana m-row & y-row
  [
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'マ', romaji: 'ma', words: [
        ChallengeKanaWord(hiragana: 'マンガ', kanji: '漫画', romaji: 'ma n ga', english: 'Manga'),
        ChallengeKanaWord(hiragana: 'マスク', romaji: 'ma su ku', english: 'Mask'),
      ]),
      ChallengeKana(hiragana: 'ミ', romaji: 'mi', words: [
        ChallengeKanaWord(hiragana: 'ミルク', romaji: 'mi ru ku', english: 'Milk'),
        ChallengeKanaWord(hiragana: 'ミカン', romaji: 'mi ka n', english: 'Mandarin orange'),
      ]),
      ChallengeKana(hiragana: 'ム', romaji: 'mu', words: [
        ChallengeKanaWord(hiragana: 'ムシ', kanji: '虫', romaji: 'mu shi', english: 'Insect'),
        ChallengeKanaWord(hiragana: 'ムービー', romaji: 'mu u bii', english: 'Movie'),
      ]),
      ChallengeKana(hiragana: 'メ', romaji: 'me', words: [
        ChallengeKanaWord(hiragana: 'メガネ', kanji: '眼鏡', romaji: 'me ga ne', english: 'Glasses'),
        ChallengeKanaWord(hiragana: 'メロン', romaji: 'me ro n', english: 'Melon'),
      ]),
      ChallengeKana(hiragana: 'モ', romaji: 'mo', words: [
        ChallengeKanaWord(hiragana: 'モモ', kanji: '桃', romaji: 'mo mo', english: 'Peach'),
        ChallengeKanaWord(hiragana: 'モノ', kanji: '物', romaji: 'mo no', english: 'Thing / Object'),
      ]),
    ]),
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'ヤ', romaji: 'ya', words: [
        ChallengeKanaWord(hiragana: 'ヤギ', romaji: 'ya gi', english: 'Goat'),
        ChallengeKanaWord(hiragana: 'ヤサイ', kanji: '野菜', romaji: 'ya sa i', english: 'Vegetable'),
      ]),
      ChallengeKana(hiragana: 'ユ', romaji: 'yu', words: [
        ChallengeKanaWord(hiragana: 'ユキ', kanji: '雪', romaji: 'yu ki', english: 'Snow'),
        ChallengeKanaWord(hiragana: 'ユメ', kanji: '夢', romaji: 'yu me', english: 'Dream'),
      ]),
      ChallengeKana(hiragana: 'ヨ', romaji: 'yo', words: [
        ChallengeKanaWord(hiragana: 'ヨル', kanji: '夜', romaji: 'yo ru', english: 'Night'),
        ChallengeKanaWord(hiragana: 'ヨット', romaji: 'yo tto', english: 'Yacht'),
      ]),
    ]),
  ],
  // Day 13 - katakana r-row & w-row (incl. ン)
  [
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'ラ', romaji: 'ra', words: [
        ChallengeKanaWord(hiragana: 'ラジオ', romaji: 'ra ji o', english: 'Radio'),
        ChallengeKanaWord(hiragana: 'ラーメン', romaji: 'ra a me n', english: 'Ramen'),
      ]),
      ChallengeKana(hiragana: 'リ', romaji: 'ri', words: [
        ChallengeKanaWord(hiragana: 'リンゴ', romaji: 'ri n go', english: 'Apple'),
        ChallengeKanaWord(hiragana: 'リス', romaji: 'ri su', english: 'Squirrel'),
      ]),
      ChallengeKana(hiragana: 'ル', romaji: 'ru', words: [
        ChallengeKanaWord(hiragana: 'ルール', romaji: 'ru u ru', english: 'Rule'),
        ChallengeKanaWord(hiragana: 'ルビー', romaji: 'ru bi i', english: 'Ruby'),
      ]),
      ChallengeKana(hiragana: 'レ', romaji: 're', words: [
        ChallengeKanaWord(hiragana: 'レモン', romaji: 're mo n', english: 'Lemon'),
        ChallengeKanaWord(hiragana: 'レストラン', romaji: 're su to ra n', english: 'Restaurant'),
      ]),
      ChallengeKana(hiragana: 'ロ', romaji: 'ro', words: [
        ChallengeKanaWord(hiragana: 'ロボット', romaji: 'ro bo tto', english: 'Robot'),
        ChallengeKanaWord(hiragana: 'ロープ', romaji: 'ro o pu', english: 'Rope'),
      ]),
    ]),
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'ワ', romaji: 'wa', words: [
        ChallengeKanaWord(hiragana: 'ワニ', romaji: 'wa ni', english: 'Crocodile'),
        ChallengeKanaWord(hiragana: 'ワタシ', kanji: '私', romaji: 'wa ta shi', english: 'I / Me'),
      ]),
      ChallengeKana(hiragana: 'ヲ', romaji: 'wo (o)', words: [
        ChallengeKanaWord(hiragana: 'ヲカシ', romaji: 'wo ka shi', english: 'Sweets (archaic spelling)'),
        ChallengeKanaWord(hiragana: 'ヲノコ', romaji: 'wo no ko', english: 'Boy (archaic spelling)'),
      ]),
      ChallengeKana(hiragana: 'ン', romaji: 'n', words: [
        ChallengeKanaWord(hiragana: 'パン', romaji: 'pa n', english: 'Bread'),
        ChallengeKanaWord(hiragana: 'ニホン', kanji: '日本', romaji: 'ni ho n', english: 'Japan'),
      ]),
    ]),
  ],
  // Day 14 - katakana g-row & z-row (dakuten)
  [
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'ガ', romaji: 'ga', words: [
        ChallengeKanaWord(hiragana: 'ガラス', romaji: 'ga ra su', english: 'Glass'),
        ChallengeKanaWord(hiragana: 'ガイド', romaji: 'ga i do', english: 'Guide'),
      ]),
      ChallengeKana(hiragana: 'ギ', romaji: 'gi', words: [
        ChallengeKanaWord(hiragana: 'ギター', romaji: 'gi taa', english: 'Guitar'),
        ChallengeKanaWord(hiragana: 'ギフト', romaji: 'gi fu to', english: 'Gift'),
      ]),
      ChallengeKana(hiragana: 'グ', romaji: 'gu', words: [
        ChallengeKanaWord(hiragana: 'グラス', romaji: 'gu ra su', english: 'Glass (cup)'),
        ChallengeKanaWord(hiragana: 'グミ', romaji: 'gu mi', english: 'Gummy candy'),
      ]),
      ChallengeKana(hiragana: 'ゲ', romaji: 'ge', words: [
        ChallengeKanaWord(hiragana: 'ゲーム', romaji: 'ge e mu', english: 'Game'),
        ChallengeKanaWord(hiragana: 'ゲート', romaji: 'ge e to', english: 'Gate'),
      ]),
      ChallengeKana(hiragana: 'ゴ', romaji: 'go', words: [
        ChallengeKanaWord(hiragana: 'ゴリラ', romaji: 'go ri ra', english: 'Gorilla'),
        ChallengeKanaWord(hiragana: 'ゴハン', kanji: 'ご飯', romaji: 'go ha n', english: 'Meal'),
      ]),
    ]),
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'ザ', romaji: 'za', words: [
        ChallengeKanaWord(hiragana: 'ザリガニ', romaji: 'za ri ga ni', english: 'Crayfish'),
        ChallengeKanaWord(hiragana: 'ザツシ', kanji: '雑誌', romaji: 'za sshi', english: 'Magazine'),
      ]),
      ChallengeKana(hiragana: 'ジ', romaji: 'ji', words: [
        ChallengeKanaWord(hiragana: 'ジテンシャ', kanji: '自転車', romaji: 'ji te n sha', english: 'Bicycle'),
        ChallengeKanaWord(hiragana: 'ジカン', kanji: '時間', romaji: 'ji ka n', english: 'Time'),
      ]),
      ChallengeKana(hiragana: 'ズ', romaji: 'zu', words: [
        ChallengeKanaWord(hiragana: 'ズボン', romaji: 'zu bo n', english: 'Pants'),
        ChallengeKanaWord(hiragana: 'ズーム', romaji: 'zu u mu', english: 'Zoom'),
      ]),
      ChallengeKana(hiragana: 'ゼ', romaji: 'ze', words: [
        ChallengeKanaWord(hiragana: 'ゼリー', romaji: 'ze rii', english: 'Jelly'),
        ChallengeKanaWord(hiragana: 'ゼンブ', kanji: '全部', romaji: 'ze n bu', english: 'All / Everything'),
      ]),
      ChallengeKana(hiragana: 'ゾ', romaji: 'zo', words: [
        ChallengeKanaWord(hiragana: 'ゾウ', kanji: '象', romaji: 'zo u', english: 'Elephant'),
        ChallengeKanaWord(hiragana: 'ゾンビ', romaji: 'zo n bi', english: 'Zombie'),
      ]),
    ]),
  ],
  // Day 15 - katakana d-row & b-row (dakuten)
  [
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'ダ', romaji: 'da', words: [
        ChallengeKanaWord(hiragana: 'ダンス', romaji: 'da n su', english: 'Dance'),
        ChallengeKanaWord(hiragana: 'ダイコン', kanji: '大根', romaji: 'da i ko n', english: 'Radish'),
      ]),
      ChallengeKana(hiragana: 'ヂ', romaji: 'ji (di)', words: [
        ChallengeKanaWord(hiragana: 'ヂカン', romaji: 'ji ka n', english: 'Time (rare use)'),
        ChallengeKanaWord(hiragana: 'ハナヂ', kanji: '鼻血', romaji: 'ha na ji', english: 'Nosebleed'),
      ]),
      ChallengeKana(hiragana: 'ヅ', romaji: 'zu (du)', words: [
        ChallengeKanaWord(hiragana: 'ツヅク', kanji: '続く', romaji: 'tsu zu ku', english: 'To continue'),
        ChallengeKanaWord(hiragana: 'ミヅ', romaji: 'mi zu', english: 'Water (archaic spelling)'),
      ]),
      ChallengeKana(hiragana: 'デ', romaji: 'de', words: [
        ChallengeKanaWord(hiragana: 'デパート', romaji: 'de paa to', english: 'Department store'),
        ChallengeKanaWord(hiragana: 'デザート', romaji: 'de za a to', english: 'Dessert'),
      ]),
      ChallengeKana(hiragana: 'ド', romaji: 'do', words: [
        ChallengeKanaWord(hiragana: 'ドア', romaji: 'do a', english: 'Door'),
        ChallengeKanaWord(hiragana: 'ドーナツ', romaji: 'do o na tsu', english: 'Donut'),
      ]),
    ]),
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'バ', romaji: 'ba', words: [
        ChallengeKanaWord(hiragana: 'バナナ', romaji: 'ba na na', english: 'Banana'),
        ChallengeKanaWord(hiragana: 'バス', romaji: 'ba su', english: 'Bus'),
      ]),
      ChallengeKana(hiragana: 'ビ', romaji: 'bi', words: [
        ChallengeKanaWord(hiragana: 'ビル', romaji: 'bi ru', english: 'Building'),
        ChallengeKanaWord(hiragana: 'ビール', romaji: 'bi i ru', english: 'Beer'),
      ]),
      ChallengeKana(hiragana: 'ブ', romaji: 'bu', words: [
        ChallengeKanaWord(hiragana: 'ブルー', romaji: 'bu ru u', english: 'Blue'),
        ChallengeKanaWord(hiragana: 'ブタ', kanji: '豚', romaji: 'bu ta', english: 'Pig'),
      ]),
      ChallengeKana(hiragana: 'ベ', romaji: 'be', words: [
        ChallengeKanaWord(hiragana: 'ベッド', romaji: 'be ddo', english: 'Bed'),
        ChallengeKanaWord(hiragana: 'ベルト', romaji: 'be ru to', english: 'Belt'),
      ]),
      ChallengeKana(hiragana: 'ボ', romaji: 'bo', words: [
        ChallengeKanaWord(hiragana: 'ボール', romaji: 'bo o ru', english: 'Ball'),
        ChallengeKanaWord(hiragana: 'ボタン', romaji: 'bo ta n', english: 'Button'),
      ]),
    ]),
  ],
  // Day 16 - katakana p-row (handakuten) - just one row, no second set
  [
    ChallengeKanaSet([
      ChallengeKana(hiragana: 'パ', romaji: 'pa', words: [
        ChallengeKanaWord(hiragana: 'パンダ', romaji: 'pa n da', english: 'Panda'),
        ChallengeKanaWord(hiragana: 'パーティー', romaji: 'paa tii', english: 'Party'),
      ]),
      ChallengeKana(hiragana: 'ピ', romaji: 'pi', words: [
        ChallengeKanaWord(hiragana: 'ピアノ', romaji: 'pi a no', english: 'Piano'),
        ChallengeKanaWord(hiragana: 'ピザ', romaji: 'pi za', english: 'Pizza'),
      ]),
      ChallengeKana(hiragana: 'プ', romaji: 'pu', words: [
        ChallengeKanaWord(hiragana: 'プール', romaji: 'pu u ru', english: 'Pool'),
        ChallengeKanaWord(hiragana: 'プリン', romaji: 'pu rin', english: 'Pudding'),
      ]),
      ChallengeKana(hiragana: 'ペ', romaji: 'pe', words: [
        ChallengeKanaWord(hiragana: 'ペン', romaji: 'pe n', english: 'Pen'),
        ChallengeKanaWord(hiragana: 'ペコペコ', romaji: 'pe ko pe ko', english: 'Hungry'),
      ]),
      ChallengeKana(hiragana: 'ポ', romaji: 'po', words: [
        ChallengeKanaWord(hiragana: 'ポケット', romaji: 'po ke tto', english: 'Pocket'),
        ChallengeKanaWord(hiragana: 'ポスト', romaji: 'po su to', english: 'Postbox'),
      ]),
    ]),
  ],
  // Day 17 - small や/ゆ/よ (ゃ/ゅ/ょ): lesson only, no new kana or vocab cards
  [],
  // Day 18 - small つ (っ/ッ) and katakana's long vowel mark ー: lesson only,
  // no new kana or vocab cards
  [],
  // Day 19 - no new kana; just the small-tsu example words as flashcards
  // (see hiraganaBonusVocabByDay)
  [],
];

// A word or phrase introduced by an end-of-day lesson (see lesson_data.dart's
// Lesson.activityBuilder) rather than tied to a specific kana character -
// greetings, self-introduction phrases, and the like. Same display
// convention as ChallengeKanaWord: pure hiragana, with a kanji preview in
// brackets when one's genuinely common in modern writing.
class BonusVocabWord {
  final String hiragana;
  final String? kanji;
  final String romaji;
  final String english;

  const BonusVocabWord({
    required this.hiragana,
    this.kanji,
    required this.romaji,
    required this.english,
  });

  String get displayJapanese => kanji == null ? hiragana : '$hiragana（$kanji）';
}

// Keyed by the day its flashcards actually appear on - one day after the
// lesson that introduces and explains it, and placed at the very start of
// that day's cards, ahead of any of that day's own kana rows. E.g. the
// "Introduce Yourself" lesson (day 7's lesson, shown right as day 6 ends)
// explains はじめまして/よろしく/しゅみ, and their flashcards are here under
// key 7, so they're the first cards studied on day 7, before the だ/ば rows.
final Map<int, List<BonusVocabWord>> hiraganaBonusVocabByDay = {
  7: [
    BonusVocabWord(hiragana: 'はじめまして', romaji: 'hajimemashite', english: 'Nice to meet you'),
    BonusVocabWord(hiragana: 'よろしく', romaji: 'yoroshiku', english: 'Pleased to meet you'),
    BonusVocabWord(hiragana: 'しゅみ', kanji: '趣味', romaji: 'shumi', english: 'Hobby'),
  ],
  8: [
    BonusVocabWord(hiragana: 'こんにちは', romaji: 'konnichiwa', english: 'Hello / Good afternoon'),
    BonusVocabWord(hiragana: 'こんばんは', romaji: 'konbanwa', english: 'Good evening'),
    BonusVocabWord(hiragana: 'おはようございます', romaji: 'ohayou gozaimasu', english: 'Good morning (polite)'),
    BonusVocabWord(hiragana: 'です', romaji: 'desu', english: 'is / am / are'),
    BonusVocabWord(hiragana: 'げんき', kanji: '元気', romaji: 'genki', english: 'Healthy, energetic, well'),
    BonusVocabWord(hiragana: 'おげんきですか', kanji: 'お元気ですか', romaji: 'o genki desu ka', english: 'How are you?'),
    BonusVocabWord(hiragana: 'だいじょうぶ', kanji: '大丈夫', romaji: 'daijoubu', english: 'Okay, alright, fine'),
    BonusVocabWord(hiragana: 'だいじょうぶですか', kanji: '大丈夫ですか', romaji: 'daijoubu desu ka', english: 'Are you okay?'),
  ],
  9: [
    BonusVocabWord(hiragana: 'わたし', kanji: '私', romaji: 'watashi', english: 'I, me'),
    BonusVocabWord(hiragana: 'ぼく', kanji: '僕', romaji: 'boku', english: 'I, me (used by males)'),
    BonusVocabWord(hiragana: 'なまえ', kanji: '名前', romaji: 'namae', english: 'Name'),
    BonusVocabWord(hiragana: 'なに', kanji: '何', romaji: 'nani', english: 'What'),
    BonusVocabWord(hiragana: 'なまえはなんですか', kanji: '名前は何ですか', romaji: 'namae wa nan desu ka', english: 'What is your name?'),
    BonusVocabWord(hiragana: 'わたしの', kanji: '私の', romaji: 'watashi no', english: 'My'),
    BonusVocabWord(hiragana: 'わたしのしゅみ', kanji: '私の趣味', romaji: 'watashi no shumi', english: 'My hobby'),
    BonusVocabWord(hiragana: 'わたしのなまえ', kanji: '私の名前', romaji: 'watashi no namae', english: 'My name'),
  ],
  // Day 19's small-tsu (っ/ッ) example words - see lesson_data.dart's
  // "Small っ and ー" lesson (day 18's lesson).
  19: [
    BonusVocabWord(hiragana: 'がっこう', kanji: '学校', romaji: 'gakkou', english: 'School'),
    BonusVocabWord(hiragana: 'にっき', kanji: '日記', romaji: 'nikki', english: 'Diary'),
    BonusVocabWord(hiragana: 'きっさてん', kanji: '喫茶店', romaji: 'kissaten', english: 'Coffee shop'),
    BonusVocabWord(hiragana: 'サッカー', romaji: 'sakkaa', english: 'Soccer'),
    BonusVocabWord(hiragana: 'きっぷ', kanji: '切符', romaji: 'kippu', english: 'Ticket'),
    BonusVocabWord(hiragana: 'せっけん', kanji: '石鹸', romaji: 'sekken', english: 'Soap'),
  ],
};

// The Unicode offset between the parallel Katakana (starting U+30A1) and
// Hiragana (starting U+3041) blocks is a constant 0x60, since the two blocks
// are laid out in the same order character-for-character. Used to compute a
// katakana character's hiragana equivalent for the Katakana Challenge's
// "comparison" context slide (see kana_comparison_screen.dart), without
// needing to hand-author 40-odd pairs alongside the character data above.
// Returns null for anything outside the basic katakana range (i.e. anything
// that isn't a single katakana character).
String? hiraganaEquivalentOf(String character) {
  if (character.length != 1) return null;
  final code = character.codeUnitAt(0);
  if (code < 0x30A1 || code > 0x30FA) return null;
  return String.fromCharCode(code - 0x60);
}

// A KanjiVG stroke-order code is just the character's Unicode codepoint as
// 5-digit lowercase hex - true for kana just as much as kanji, so hiragana
// characters get real stroke-order writing practice the same way the 90 Day
// Kanji Challenge's kanji do.
String _kanjiVGCodeFor(String character) => character.runes.first.toRadixString(16).padLeft(5, '0');

// A bare hiragana character card: drilled by drawing it from its romaji
// prompt (englishFirst, since a Kana card's `english` field holds its
// romanization) - the whole point of this early stage is learning to write
// each character, same as the 90 Day Kanji Challenge's own kanji cards.
StudyCard _cardFromChallengeKana(ChallengeKana ck, int dayNumber) {
  return StudyCard(
    japanese: ck.hiragana,
    hiragana: ck.hiragana,
    romaji: ck.romaji,
    english: ck.romaji,
    kanjiVGCodes: [_kanjiVGCodeFor(ck.hiragana)],
    cardType: 'Kana',
    challengeDay: dayNumber,
    answerMode: 'draw',
    englishFirst: true,
  );
}

// An example-word card: shown Japanese-first (its hiragana, with a kanji
// preview in brackets when it has one), self-graded rather than drawn -
// these are for reading recognition, not writing practice.
StudyCard _cardFromChallengeWord(ChallengeKanaWord w, int dayNumber) {
  return StudyCard(
    japanese: w.displayJapanese,
    hiragana: w.hiragana,
    romaji: w.romaji,
    english: w.english,
    cardType: 'Vocab',
    challengeDay: dayNumber,
    answerMode: 'basic',
    englishFirst: false,
  );
}

// A bonus vocab card - same shape as an ordinary example-word card (Japanese-
// first, self-graded), just not tied to any particular kana character.
StudyCard _cardFromBonusVocabWord(BonusVocabWord w, int dayNumber) {
  return StudyCard(
    japanese: w.displayJapanese,
    hiragana: w.hiragana,
    romaji: w.romaji,
    english: w.english,
    cardType: 'Vocab',
    challengeDay: dayNumber,
    answerMode: 'basic',
    englishFirst: false,
  );
}

// Builds the full Hiragana Challenge deck from every day authored so far - a
// fresh StudyDeck starting its schedule today, so new hiragana unlock one
// day of content at a time from here on, the same way the 90 Day Kanji
// Challenge does.
//
// Within a day, cards are grouped by set rather than interleaved character-
// by-character: any bonus vocab for that day comes first (see
// hiraganaBonusVocabByDay), then every kana card in a row comes before that
// row's own example-word cards, then the next row - so a session works
// through a whole row of characters (each introduced with its own context
// slide, then drilled by drawing) before ever seeing a vocab card, then a
// whole row of words (each introduced with its own context slide) before the
// next row of characters begins. See spaced_repetition_standard.dart's
// _maybeShowCardIntroBatch, which relies on this grouping to keep kana and
// vocab context slides from ever mixing within the same batch.
StudyDeck buildHiraganaChallengeDeck() {
  final cards = <StudyCard>[];
  final totalDays = [
    hiraganaChallengeDays.length,
    if (hiraganaBonusVocabByDay.isNotEmpty) hiraganaBonusVocabByDay.keys.reduce((a, b) => a > b ? a : b),
  ].reduce((a, b) => a > b ? a : b);
  for (var day = 1; day <= totalDays; day++) {
    for (final w in hiraganaBonusVocabByDay[day] ?? const <BonusVocabWord>[]) {
      cards.add(_cardFromBonusVocabWord(w, day));
    }
    if (day - 1 < hiraganaChallengeDays.length) {
      for (final set in hiraganaChallengeDays[day - 1]) {
        for (final ck in set.kana) {
          cards.add(_cardFromChallengeKana(ck, day));
        }
        for (final ck in set.kana) {
          for (final w in ck.words) {
            cards.add(_cardFromChallengeWord(w, day));
          }
        }
      }
    }
  }
  return StudyDeck(name: hiraganaChallengeDeckName, cards: cards, challengeStartDate: todayStamp());
}
