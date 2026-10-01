import 'sets_data.dart';
import 'study_data.dart';

const String kanjiChallengeDeckName = '90 Day Kanji Challenge';

// One kanji/radical's authored content for the 90 Day Kanji Challenge: its
// meaning and the user's own mnemonic(s). Its KanjiVG stroke-order code is
// derived automatically from its own Unicode codepoint (see
// _kanjiVGCodeFor) rather than stored here, since that's all a KanjiVG code
// ever is - this also means it works for every character (kanji, radicals,
// even ones not in the app's own dictionary), not just ones a Kakijun page
// happens to be linked for.
class ChallengeKanji {
  final String japanese;
  final String english;
  final List<String> memoryNotes;
  // Bundled asset path for this kanji's memory-technique illustration (e.g.
  // 'assets/kanji_memory/706b.webp'), when one's been authored - null for
  // the vast majority of entries until images are added in later batches.
  final String? imageAsset;

  const ChallengeKanji({
    required this.japanese,
    required this.english,
    this.memoryNotes = const [],
    this.imageAsset,
  });
}

// One kanji shown alongside another for a visual side-by-side comparison -
// see similarLookingKanji below. Carries its own meaning rather than relying
// on the dictionary or kanjiChallengeDays, since a couple of these (e.g. 承,
// 了) are only ever referenced here for the comparison and aren't otherwise
// part of the challenge or dictionary.
class SimilarKanji {
  final String japanese;
  final String english;
  const SimilarKanji(this.japanese, this.english);
}

// One full group of kanji that are easy to visually confuse with each
// other, the way the 90 Day Kanji Challenge lesson videos group them on
// their "Similar Looking Kanji" slides - e.g. 王/玉/主. Every member is
// listed (not just the "new" one a card happens to be), so this same group
// doubles as the content for the Lessons tab's standalone "Similar Kanji"
// section, which just lists every group as its own browsable slide.
class SimilarKanjiGroup {
  final List<SimilarKanji> members;
  const SimilarKanjiGroup(this.members);
}

// Only the groups authored so far are included; more are added as later
// days' lesson scripts are written.
final List<SimilarKanjiGroup> similarKanjiGroups = [
  SimilarKanjiGroup([SimilarKanji('日', 'Day, sun'), SimilarKanji('目', 'Eye'), SimilarKanji('耳', 'Ear')]),
  SimilarKanjiGroup([SimilarKanji('王', 'King'), SimilarKanji('玉', 'Ball'), SimilarKanji('主', 'Chief')]),
  SimilarKanjiGroup([SimilarKanji('人', 'Person'), SimilarKanji('火', 'Fire'), SimilarKanji('入', 'Enter')]),
  SimilarKanjiGroup([SimilarKanji('子', 'Child'), SimilarKanji('承', 'Acknowledge'), SimilarKanji('了', 'Complete')]),
];

// Derived from similarKanjiGroups: every kanji in a group maps to every
// OTHER kanji in that same group, so similarKanjiFor works no matter which
// one of the group is the card actually being studied.
final Map<String, List<SimilarKanji>> similarLookingKanji = {
  for (final group in similarKanjiGroups)
    for (final member in group.members)
      member.japanese: [for (final other in group.members) if (other.japanese != member.japanese) other],
};

List<SimilarKanji>? similarKanjiFor(String kanji) => similarLookingKanji[kanji];

// Each entry is one day's newly-introduced kanji, in order. Only days that
// have been authored so far are included - more are appended as they're
// written, which is also what makes each day's new-card count "variable"
// rather than a fixed daily number.
final List<List<ChallengeKanji>> kanjiChallengeDays = [
  // Day 1
  [
    ChallengeKanji(
      japanese: '日',
      english: 'Day, sun',
      memoryNotes: [
        "A minecraft sun rising to start the day (because of the kanji's square/rectangular shape)",
        "A sun in the shape of two drawers",
      ],
      imageAsset: 'assets/kanji_memory/065e5.webp',
    ),
    ChallengeKanji(
      japanese: '王',
      english: 'King',
      memoryNotes: [
        "A crown tilted on it's side",
        "3 kings talking on a staircase",
      ],
      imageAsset: 'assets/kanji_memory/0738b.webp',
    ),
    ChallengeKanji(
      japanese: '玉',
      english: 'Ball',
      memoryNotes: ["A king kicking up a football/soccerball"],
    ),
    ChallengeKanji(
      japanese: '口',
      english: 'Mouth, box, enclosure',
      memoryNotes: ["Someone opening their mouth wide open"],
      imageAsset: 'assets/kanji_memory/053e3.webp',
    ),
    ChallengeKanji(
      japanese: '人',
      english: 'Person',
      memoryNotes: ["A person with a wide stance"],
      imageAsset: 'assets/kanji_memory/04eba.webp',
    ),
    ChallengeKanji(
      japanese: '入',
      english: 'Enter, insert',
      memoryNotes: ["A person putting an enter sign in a box back to front"],
      imageAsset: 'assets/kanji_memory/05165.webp',
    ),
    ChallengeKanji(
      japanese: '火',
      english: 'Fire',
      memoryNotes: ["A person holding fire in each hand"],
      imageAsset: 'assets/kanji_memory/0706b.webp',
    ),
    ChallengeKanji(
      japanese: '子',
      english: 'Child',
      memoryNotes: ["A kid in a captain hook costume"],
    ),
    ChallengeKanji(
      japanese: '小',
      english: 'Small',
      memoryNotes: ["A massive bow and a super small arrow"],
      imageAsset: 'assets/kanji_memory/05c0f.webp',
    ),
    ChallengeKanji(
      japanese: '言',
      english: 'Say',
      memoryNotes: ["A person speaking and soundwaves coming from the mouth"],
      imageAsset: 'assets/kanji_memory/08a00.webp',
    ),
  ],
  // Day 2
  [
    ChallengeKanji(
      japanese: '大',
      english: 'Big',
      memoryNotes: ["A Big person with their arms wide apart"],
      imageAsset: 'assets/kanji_memory/05927.webp',
    ),
    ChallengeKanji(
      japanese: '力',
      english: 'Power',
      memoryNotes: ["A strong man shouting kaaaa (kanji looks like the katakana symbol for ka カ)"],
      imageAsset: 'assets/kanji_memory/0529b.webp',
    ),
    ChallengeKanji(
      japanese: '刀',
      english: 'Sword, katana',
      memoryNotes: [
        "The strong man in now holding a katana (katakana kanji 刀 looks like the previous kanji for power 力)",
        "The second stroke looks like the blade of the sword",
      ],
      imageAsset: 'assets/kanji_memory/05200.webp',
    ),
    ChallengeKanji(
      japanese: '木',
      english: 'Tree, wood',
      memoryNotes: ["A tree with long hanging branches"],
      imageAsset: 'assets/kanji_memory/06728.webp',
    ),
    ChallengeKanji(
      japanese: '水',
      english: 'Water',
      memoryNotes: ["An arrow made of water"],
    ),
    ChallengeKanji(
      japanese: '父',
      english: 'Father',
      memoryNotes: ["A dad holding two swords with a concerned expression (especially in his eyebrows)"],
    ),
    ChallengeKanji(
      japanese: '田',
      english: 'Field, rice paddy',
      memoryNotes: ["Rice plots from a rice paddy with a fence around it"],
    ),
    ChallengeKanji(
      japanese: '雨',
      english: 'Rain',
      memoryNotes: [
        "It's raining underneath an umbrella",
        "The dots look like drops of rain",
      ],
      imageAsset: 'assets/kanji_memory/096e8.webp',
    ),
    ChallengeKanji(
      japanese: '月',
      english: 'Moon, month',
      memoryNotes: ["Two drawers are the moon and wearing a cape"],
      imageAsset: 'assets/kanji_memory/06708.webp',
    ),
    ChallengeKanji(
      japanese: '女',
      english: 'Woman, female',
      memoryNotes: ["A woman sitting with her legs crossed"],
      imageAsset: 'assets/kanji_memory/05973.webp',
    ),
  ],
  // Day 3
  [
    ChallengeKanji(
      japanese: '男',
      english: 'Man, male',
      memoryNotes: ["A strong man working in a field"],
    ),
    ChallengeKanji(
      japanese: '耳',
      english: 'Ear',
      memoryNotes: ["A person with eyes where his ears should be"],
      imageAsset: 'assets/kanji_memory/08033.webp',
    ),
    ChallengeKanji(
      japanese: '可',
      english: 'Can, possible',
      memoryNotes: ["A man shocked with his mouth wide open because a street is completely normal"],
    ),
    ChallengeKanji(
      japanese: '川',
      english: 'River',
      memoryNotes: ["The number 3 floating in the river on its side (this kanji looks like the kanji for 3 三 on it's side)"],
      imageAsset: 'assets/kanji_memory/05ddd.webp',
    ),
    ChallengeKanji(
      japanese: '半',
      english: 'Half',
      memoryNotes: ["A cake cut in half unfairly, one half is '2' small"],
    ),
    ChallengeKanji(
      japanese: '舌',
      english: 'Tongue',
      memoryNotes: ["A person shouting 1000 with their tongue sticking out"],
      imageAsset: 'assets/kanji_memory/0820c.webp',
    ),
    ChallengeKanji(
      japanese: '手',
      english: 'Hand',
      memoryNotes: ["a person holding their hand sideways like this"],
      imageAsset: 'assets/kanji_memory/0624b.webp',
    ),
    ChallengeKanji(
      japanese: '心',
      english: 'Heart, mind, spirit',
      memoryNotes: ["3 shockwaves around a heart, the heart is turned and looks like an 'L' like the middle stroke of the kanji"],
      imageAsset: 'assets/kanji_memory/05fc3.webp',
    ),
    ChallengeKanji(
      japanese: '目',
      english: 'Eye',
      memoryNotes: ["An eye turned sideways"],
      imageAsset: 'assets/kanji_memory/076ee.webp',
    ),
    ChallengeKanji(
      japanese: '衣',
      english: 'Clothing, garment',
      memoryNotes: ["A person wearing a shirt with a big L on it and trousers with an L on their left leg"],
      imageAsset: 'assets/kanji_memory/08863.webp',
    ),
    ChallengeKanji(
      japanese: '竹',
      english: 'Bamboo',
      memoryNotes: ["Two people holding bamboo sticks"],
    ),
    ChallengeKanji(
      japanese: '門',
      english: 'Gate',
      memoryNotes: ["A P and a 9 facing each other to form a gate, also looks like a tori gate"],
    ),
    ChallengeKanji(
      japanese: '貝',
      english: 'Shellfish',
      memoryNotes: ["An eye with a shell around it and a lobster pincers"],
    ),
  ],
  // Day 4
  [
    ChallengeKanji(
      japanese: '魚',
      english: 'Fish',
      memoryNotes: ["A person catching a big goldfish in a rice paddy"],
    ),
    ChallengeKanji(
      japanese: '止',
      english: 'Stop',
      memoryNotes: ["A big stop sign going up to the sky"],
    ),
    ChallengeKanji(
      japanese: '糸',
      english: 'Thread',
      memoryNotes: ["A person holding a small piece of thread"],
    ),
    ChallengeKanji(
      japanese: '足',
      english: 'Foot, leg',
      memoryNotes: ["Head arm and a big foot"],
    ),
    ChallengeKanji(
      japanese: '走',
      english: 'Run',
      memoryNotes: ["A person with big feet running on the soil"],
    ),
    ChallengeKanji(
      japanese: '山',
      english: 'Mountain',
      memoryNotes: ["A 3 spiked fork shaped mountain"],
    ),
    ChallengeKanji(
      japanese: '夕',
      english: 'Evening',
      memoryNotes: ["Looks like a crescent moon (moon comes out at evening/night time)"],
    ),
    ChallengeKanji(
      japanese: '土',
      english: 'Earth, soil',
      memoryNotes: ["A number 10 sticking out the soil"],
    ),
    ChallengeKanji(
      japanese: '士',
      english: 'Samurai, scholar, warrior',
      memoryNotes: ["A samurai with super wide shoulders holding a PhD"],
    ),
    ChallengeKanji(
      japanese: '寸',
      english: 'Measure',
      memoryNotes: ["Two rulers crossed over each other"],
    ),
    ChallengeKanji(
      japanese: '寺',
      english: 'Temple',
      memoryNotes: ["rulers making a small torii gate on the soil at a temple"],
    ),
    ChallengeKanji(
      japanese: '又',
      english: 'Again',
      memoryNotes: ["A fisherman catches fish again again and again (kanji looks like a fish)"],
    ),
    ChallengeKanji(
      japanese: '乙',
      english: 'The latter, second',
      memoryNotes: [
        "Looks like a 2 (for the meaning second)",
        "Also looks like a fancy L so you could think of L for the latter'",
      ],
    ),
  ],
  // Day 5 - basic strokes and radicals
  [
    ChallengeKanji(
      japanese: '一',
      english: 'One, horizontal stroke',
      memoryNotes: ["'一' represents 1 just like how '二' represents 2 and '三' represents 3."],
    ),
    const ChallengeKanji(japanese: '丨', english: 'Stick, vertical stroke'),
    const ChallengeKanji(japanese: '丿', english: 'Bent stroke'),
    const ChallengeKanji(japanese: '丶', english: 'Dot'),
    const ChallengeKanji(japanese: '亅', english: 'Stroke with hook'),
    ChallengeKanji(
      japanese: '亠',
      english: 'Lid',
      memoryNotes: ["Looks like a lid on a cooking pot"],
    ),
    ChallengeKanji(
      japanese: '儿',
      english: 'Legs',
      memoryNotes: ["Looks like Charlie Chaplin legs"],
    ),
    const ChallengeKanji(japanese: '冂', english: 'To enclose'),
    ChallengeKanji(
      japanese: '冖',
      english: 'Crown, cover',
      memoryNotes: ["A flat crown"],
    ),
    ChallengeKanji(
      japanese: '冫',
      english: 'Ice',
      memoryNotes: ["Like the water radical but since it's frozen the dots have started merging together"],
    ),
    ChallengeKanji(
      japanese: '几',
      english: 'Desk, table',
      memoryNotes: ["A table with two legs"],
    ),
    ChallengeKanji(
      japanese: '凵',
      english: 'Open box, open mouth',
      memoryNotes: ["An open box"],
    ),
    ChallengeKanji(
      japanese: '勹',
      english: 'To wrap/embrace',
      memoryNotes: ["A barbell holder at the gym"],
    ),
    ChallengeKanji(
      japanese: '匕',
      english: 'Spoon',
      memoryNotes: ["Seven spoons"],
    ),
    const ChallengeKanji(japanese: '囗', english: 'Box'),
    ChallengeKanji(
      japanese: '匚',
      english: 'Side open box',
      memoryNotes: ["An open box on its side"],
    ),
    const ChallengeKanji(japanese: '匸', english: 'To conceal, dead'),
    ChallengeKanji(
      japanese: '卜',
      english: 'Divination, oracle, diving rod',
      memoryNotes: ["Here's what a divining rod looks like"],
    ),
    ChallengeKanji(
      japanese: '卩',
      english: 'Stamp, seal',
      memoryNotes: ["A 'P'ost man with his stamps"],
    ),
    const ChallengeKanji(japanese: '厂', english: 'Cliff'),
    ChallengeKanji(
      japanese: '厶',
      english: 'Private',
      memoryNotes: ["A cow types a password on his computer"],
    ),
    ChallengeKanji(
      japanese: '亻',
      english: 'Person',
      memoryNotes: ["A person balancing on one leg side profile view"],
    ),
  ],
  // Day 6 - more radicals
  [
    ChallengeKanji(
      japanese: '宀',
      english: 'Roof',
      memoryNotes: ["The line in the middle looks like a chimney"],
    ),
    ChallengeKanji(
      japanese: '艹',
      english: 'Grass',
      memoryNotes: ["The two lines look like grass growing from the ground"],
    ),
    const ChallengeKanji(japanese: '⺌', english: 'Small'),
    ChallengeKanji(
      japanese: 'ホ',
      english: 'Tree, wood',
      memoryNotes: ["Two branches fell off the tree"],
    ),
    ChallengeKanji(
      japanese: '禾',
      english: 'Two branched tree, grain',
      memoryNotes: ["A tree with two big branches slanted like this"],
    ),
    ChallengeKanji(
      japanese: '衤',
      english: 'Clothes',
      memoryNotes: ["A horse wearing clothes saying 'neyy' (the radical looks like the katakana symbol for 'ne' ネ)"],
    ),
    ChallengeKanji(
      japanese: '巛',
      english: 'Winding river',
      memoryNotes: ["A winding river with arrows showing the direction of the current"],
    ),
    ChallengeKanji(
      japanese: '阝',
      english: 'Village, group',
      memoryNotes: ["A village with a big 'B'urger restaurant"],
    ),
    ChallengeKanji(
      japanese: '阝',
      english: 'Hill',
      memoryNotes: ["A flag with the letter B on it atop a hill"],
    ),
    ChallengeKanji(
      japanese: '己',
      english: 'Self',
      memoryNotes: [
        "You gain your sense of self by age 5 (5 is the other way round)",
        "'S'elf (S is the other way round)",
      ],
    ),
    ChallengeKanji(
      japanese: '氵',
      english: 'Water',
      memoryNotes: ["The ice has melted so there are more drops again"],
    ),
    ChallengeKanji(
      japanese: '扌',
      english: 'Hand',
      memoryNotes: ["A squashed hand"],
    ),
    ChallengeKanji(
      japanese: '忄',
      english: 'Heart',
      memoryNotes: ["A small heart (looks similar to the small radical ⺌)"],
    ),
    ChallengeKanji(
      japanese: '彳',
      english: 'Step',
      memoryNotes: ["A person taking a step"],
    ),
    ChallengeKanji(
      japanese: '毋',
      english: 'Mother, do not',
      memoryNotes: ["A mother collecting fruit from the field for her son"],
    ),
    ChallengeKanji(
      japanese: '幺',
      english: 'Short thread',
      memoryNotes: ["A shortened version of thread"],
    ),
    ChallengeKanji(
      japanese: '夂',
      english: 'Go, late, winter',
      memoryNotes: [
        "Shortened version of 冬 (winter)",
        "Winter is the 'late'st part of the year",
      ],
    ),
    ChallengeKanji(
      japanese: '灬',
      english: 'Fire',
      memoryNotes: ["Fire embers on the ground"],
    ),
    ChallengeKanji(
      japanese: '攵',
      english: 'Strike',
      memoryNotes: ["Two people clashing swords"],
    ),
    ChallengeKanji(
      japanese: '广',
      english: 'Slanted roof, rocky cliff',
      memoryNotes: [
        "A cliff with rocks sticking out",
        "A slanted roof (like a cliff is slanted) with a chimney on top",
      ],
    ),
  ],
  // Day 7
  [
    ChallengeKanji(
      japanese: '人',
      english: 'Person',
      memoryNotes: ["A person with a wide stance"],
    ),
    ChallengeKanji(
      japanese: '一',
      english: 'One',
      memoryNotes: ["'一' represents 1 just like how '二' represents 2 and '三' represents 3."],
    ),
    ChallengeKanji(
      japanese: '日',
      english: 'Day, sun',
      memoryNotes: [
        "A minecraft sun rising to start the day (because of the kanji's square/rectangular shape)",
        "A sun in the shape of two drawers",
      ],
    ),
    ChallengeKanji(
      japanese: '大',
      english: 'Big',
      memoryNotes: ["A Big person with their arms wide apart"],
    ),
    ChallengeKanji(
      japanese: '年',
      english: 'Year',
      memoryNotes: ["A person running down the steps shouting 'happy new year'"],
    ),
    ChallengeKanji(
      japanese: '出',
      english: 'Leave',
      memoryNotes: ["2 arrows pointing toward an exit"],
    ),
    ChallengeKanji(
      japanese: '本',
      english: 'Book, foundation',
      memoryNotes: ["A book about trees"],
    ),
    ChallengeKanji(
      japanese: '中',
      english: 'Inside, center, during',
      memoryNotes: ["A totem"],
    ),
    ChallengeKanji(
      japanese: '子',
      english: 'Child',
      memoryNotes: ["A kid in a captain hook costume"],
    ),
    ChallengeKanji(
      japanese: '見',
      english: 'See, look',
      memoryNotes: ["An eye on legs looking at the tv"],
    ),
  ],
  // Day 8
  [
    ChallengeKanji(
      japanese: '国',
      english: 'Country',
      memoryNotes: [
        "A capital city with a big ball shaped building in the center\nYou could think of your own country capital\nE.g a big round big ben (UK), a big round eiffel tower (France) etc.",
      ],
    ),
    ChallengeKanji(
      japanese: '上',
      english: 'Up, above',
      memoryNotes: ["A stick above the ground"],
    ),
    ChallengeKanji(
      japanese: '分',
      english: 'Part, minute',
      memoryNotes: ["A sword separated into its different parts"],
    ),
    ChallengeKanji(
      japanese: '生',
      english: 'Life, born',
      memoryNotes: ["A king is born"],
    ),
    ChallengeKanji(
      japanese: '行',
      english: 'Go, carry out',
      memoryNotes: ["A man walking towards a street"],
    ),
    ChallengeKanji(
      japanese: '二',
      english: 'Two',
      memoryNotes: ["Two '一' (meaning 1)"],
    ),
    ChallengeKanji(
      japanese: '間',
      english: 'Gap',
      memoryNotes: ["A gate that takes you to the sun called the gap in space time"],
    ),
    ChallengeKanji(
      japanese: '時',
      english: 'Time, hour',
      memoryNotes: [
        "A temple with a sundial",
        "This is what a sundial looks like if you don't know",
      ],
    ),
    ChallengeKanji(
      japanese: '気',
      english: 'Energy, mood, spirit',
      memoryNotes: ["Steam from forging a sword"],
    ),
    ChallengeKanji(
      japanese: '十',
      english: 'Ten',
      memoryNotes: ["A 10 speed limit sign"],
    ),
  ],
  // Day 9
  [
    ChallengeKanji(
      japanese: '女',
      english: 'Woman, female',
      memoryNotes: ["A woman sitting with her legs crossed"],
    ),
    ChallengeKanji(
      japanese: '三',
      english: 'Three',
      memoryNotes: ["Three '一' (meaning 1)"],
    ),
    ChallengeKanji(
      japanese: '前',
      english: 'Before, in front',
      memoryNotes: ["A grass field in front of a moon and sword"],
    ),
    ChallengeKanji(
      japanese: '入',
      english: 'Enter, insert',
      memoryNotes: ["A person putting an enter sign in a box backwards"],
    ),
    ChallengeKanji(
      japanese: '小',
      english: 'Small',
      memoryNotes: ["A massive bow and a super small arrow"],
    ),
    ChallengeKanji(
      japanese: '後',
      english: 'Later, after',
      memoryNotes: ["The Turtle doesn't make it to the finish line until after everyone else (took so long it became winter)"],
    ),
    ChallengeKanji(
      japanese: '長',
      english: 'Long, leader',
      memoryNotes: ["A long closet with only 3 outfits in it"],
    ),
    ChallengeKanji(
      japanese: '下',
      english: 'Below, under',
      memoryNotes: ["A stick below the ground"],
    ),
    ChallengeKanji(
      japanese: '学',
      english: 'Study, learning',
      memoryNotes: ["A prince with a small crown studying at school"],
    ),
    ChallengeKanji(
      japanese: '月',
      english: 'Moon, month',
      memoryNotes: ["Two drawers are the moon, and wearing a cape"],
    ),
  ],
  // Day 10
  [
    ChallengeKanji(
      japanese: '何',
      english: 'What',
      memoryNotes: ["A person asking what makes something possible"],
    ),
    ChallengeKanji(
      japanese: '来',
      english: 'Come, next, future',
      memoryNotes: ["A person at a restaurant waiting for the waiter to come with a rice pot"],
    ),
    ChallengeKanji(
      japanese: '話',
      english: 'Speech, talk',
      memoryNotes: ["Two people talking whilst sticking out their tongues"],
    ),
    ChallengeKanji(
      japanese: '山',
      english: 'Mountain',
      memoryNotes: ["I think of a mountain in the shape of a 3 spiked fork"],
    ),
    ChallengeKanji(
      japanese: '高',
      english: 'High, expensive',
      memoryNotes: [
        "Etymology: Depicts a tall structure\nLooks a bit like traffic lights to me so I think of really high up traffic lights",
      ],
    ),
    ChallengeKanji(
      japanese: '今',
      english: 'Now',
      memoryNotes: ["A tiger person checking what time it is now"],
    ),
    ChallengeKanji(
      japanese: '書',
      english: 'Writing',
      memoryNotes: ["An author writing a story outside with a writing brush at sunrise"],
    ),
    ChallengeKanji(
      japanese: '五',
      english: 'Five',
      memoryNotes: ["Looks like the number 5 with a line through it"],
    ),
    ChallengeKanji(
      japanese: '名',
      english: 'Name',
      memoryNotes: [
        "Etymology: Saying one's name to identify themselves in the dark.\nSomeone saying their name at night time to identify themselves",
      ],
    ),
    ChallengeKanji(
      japanese: '金',
      english: 'Gold, money',
      memoryNotes: ["A person gets loads of money and gold from the king"],
    ),
  ],
  // Day 11
  [
    ChallengeKanji(
      japanese: '男',
      english: 'Man, male',
      memoryNotes: ["A strong man working in a field"],
    ),
    ChallengeKanji(
      japanese: '外',
      english: 'Outside',
      memoryNotes: ["People with sparklers outside at evening time"],
    ),
    ChallengeKanji(
      japanese: '四',
      english: 'Four',
      memoryNotes: ["A cat (an animal with 4 legs) in a box"],
    ),
    ChallengeKanji(
      japanese: '先',
      english: 'Previous, beforehand',
      memoryNotes: ["Footprints left in the 'soil' from the 'legs' symbolising previous."],
    ),
    ChallengeKanji(
      japanese: '川',
      english: 'River',
      memoryNotes: ["The number 3 floating in the river on its side"],
    ),
    ChallengeKanji(
      japanese: '東',
      english: 'East',
      memoryNotes: ["A tree field outside an eastern temple."],
    ),
    ChallengeKanji(
      japanese: '聞',
      english: 'Listen, ask',
      memoryNotes: ["A gate to the ears. The gate opens allowing the person to hear."],
    ),
    ChallengeKanji(
      japanese: '語',
      english: 'Language',
      memoryNotes: ["A person translating the number 5 out loud from english to japanese."],
    ),
    ChallengeKanji(
      japanese: '九',
      english: 'Nine',
      memoryNotes: [
        "9 looks a lot like the kanji for power (力), for those who like my hero academia Deku is the 9th user of one for all a very powerful quirk.",
        "A powerful looking number nine",
      ],
    ),
    ChallengeKanji(
      japanese: '食',
      english: 'Eat, meal',
      memoryNotes: ["A person is feeling great whilst eating"],
    ),
    ChallengeKanji(
      japanese: '良',
      english: 'Good',
      memoryNotes: ["An angel (a good person wearing white clothes)"],
    ),
  ],
  // Day 12
  [
    ChallengeKanji(
      japanese: '八',
      english: 'Eight, (separate as radical)',
      memoryNotes: ["Building off of the meaning for 4 四, two cats lying in the shape of the 8 kanji (4 + 4 = 8)"],
    ),
    ChallengeKanji(
      japanese: '水',
      english: 'Water',
      memoryNotes: ["An arrow made of water"],
    ),
    ChallengeKanji(
      japanese: '天',
      english: 'Sky, heavens',
      memoryNotes: ["A massive heaven on the horizon"],
    ),
    ChallengeKanji(
      japanese: '木',
      english: 'Tree, wood',
      memoryNotes: ["A tree with long hanging branches"],
    ),
    ChallengeKanji(
      japanese: '六',
      english: 'Six',
      memoryNotes: ["A lid separated into 6 pieces"],
    ),
    ChallengeKanji(
      japanese: '万',
      english: 'Ten thousand',
      memoryNotes: ["A 10,000 dollar katana"],
    ),
    ChallengeKanji(
      japanese: '白',
      english: 'White',
      memoryNotes: ["The bright white sun"],
    ),
    ChallengeKanji(
      japanese: '七',
      english: 'Seven',
      memoryNotes: ["An upside down 7"],
    ),
    ChallengeKanji(
      japanese: '円',
      english: 'Round, yen',
      memoryNotes: [
        "The enclose radical wraps around = round",
        "Coins are round",
      ],
    ),
    ChallengeKanji(
      japanese: '電',
      english: 'Electricity',
      memoryNotes: ["Thunder rain and loads of lightning hitting a field"],
    ),
  ],
  // Day 13
  [
    ChallengeKanji(
      japanese: '父',
      english: 'Father',
      memoryNotes: ["A dad holding two swords with a concerned expression (especially in his eyebrows)"],
    ),
    ChallengeKanji(
      japanese: '北',
      english: 'North',
      memoryNotes: ["Standing with a spoon at the north pole"],
    ),
    ChallengeKanji(
      japanese: '車',
      english: 'Car, vehicle',
      memoryNotes: ["2 cars driving over a field"],
    ),
    ChallengeKanji(
      japanese: '母',
      english: 'Mother',
      memoryNotes: ["A mother collecting fruit from the field for her son"],
    ),
    ChallengeKanji(
      japanese: '半',
      english: 'Half',
      memoryNotes: ["A cake cut in half unfairly, one half is '2' small"],
    ),
    ChallengeKanji(
      japanese: '百',
      english: 'Hundred',
      memoryNotes: ["A polar bear celebrates his 100th birthday"],
    ),
    ChallengeKanji(
      japanese: '土',
      english: 'Ground, soil, earth',
      memoryNotes: ["A number 10 on the soil"],
    ),
    ChallengeKanji(
      japanese: '西',
      english: 'West',
      memoryNotes: ["West is the 4th direction in north, east, south, west"],
    ),
    ChallengeKanji(
      japanese: '読',
      english: 'Reading',
      memoryNotes: ["Selling words (books) for people to read."],
    ),
    ChallengeKanji(
      japanese: '千',
      english: 'Thousand',
      memoryNotes: ["A crooked sign saying 1000 miles"],
    ),
  ],
  // Day 14
  [
    ChallengeKanji(
      japanese: '校',
      english: 'Exam, school',
      memoryNotes: ["A group of students talking and studying under a tree (radicals are tree, and mingle)"],
    ),
    ChallengeKanji(
      japanese: '右',
      english: 'Right (as in right or left)',
      memoryNotes: ["Imagine your holding a rock in your right hand, imagine your left hand fingers turn into construction tools"],
    ),
    ChallengeKanji(
      japanese: '南',
      english: 'South',
      memoryNotes: [
        "Half as in around the half way point of north, east, south, west",
        "The compass needle is a cross shape",
      ],
    ),
    ChallengeKanji(
      japanese: '左',
      english: 'Left (as in right or left)',
      memoryNotes: ["Imagine your left hand fingers turn into construction tools"],
    ),
    ChallengeKanji(
      japanese: '友',
      english: 'Friend',
      memoryNotes: ["Two friends having a snowball fight in winter"],
    ),
    ChallengeKanji(
      japanese: '火',
      english: 'Fire',
      memoryNotes: ["A person holding fire in his hands"],
    ),
    ChallengeKanji(
      japanese: '毎',
      english: 'Every',
      memoryNotes: ["Every person has a mother"],
    ),
    ChallengeKanji(
      japanese: '雨',
      english: 'Rain',
      memoryNotes: [
        "It's raining underneath an umbrella",
        "The dots look like drops of rain",
      ],
    ),
    ChallengeKanji(
      japanese: '休',
      english: 'Rest, holiday',
      memoryNotes: ["A person resting by a tree"],
    ),
    ChallengeKanji(
      japanese: '午',
      english: 'Noon',
      memoryNotes: ["A person wearing a t-shirt with the number 10 on it waiting for 12pm (lunch time)"],
    ),
  ],
  // Day 15 - rest day, no new cards
  [],
  // Day 16
  [
    ChallengeKanji(
      japanese: '言',
      english: 'Word, speech',
      memoryNotes: ["A person speaking with soundwaves coming out their mouth"],
    ),
    ChallengeKanji(
      japanese: '手',
      english: 'Hand',
      memoryNotes: ["Looks a bit like a hand"],
    ),
    ChallengeKanji(
      japanese: '自',
      english: 'Self',
      memoryNotes: ["The eye that looks inward at oneself"],
    ),
    ChallengeKanji(
      japanese: '者',
      english: 'Person, someone',
      memoryNotes: ["The old wise sun who tells you who you are."],
    ),
    ChallengeKanji(
      japanese: '事',
      english: 'Thing, matter',
      memoryNotes: ["A broom with a mouth thinking about things."],
    ),
    ChallengeKanji(
      japanese: '思',
      english: 'Think',
      memoryNotes: ["Thoughts are like a field in your mind."],
    ),
    ChallengeKanji(
      japanese: '会',
      english: 'Meet, association',
      memoryNotes: ["A person saying something at a meeting."],
    ),
    ChallengeKanji(
      japanese: '家',
      english: 'House, home',
      memoryNotes: ["A pig living in a house."],
    ),
    ChallengeKanji(
      japanese: '的',
      english: 'Target, -like (suffix)',
      memoryNotes: ["A target with white circles wrapping around it."],
    ),
    ChallengeKanji(
      japanese: '方',
      english: 'Direction, way of doing, person (polite)',
      memoryNotes: ["Looks like a person pointing which direction to go."],
    ),
    ChallengeKanji(
      japanese: '地',
      english: 'Earth, ground',
      memoryNotes: ["To be soil, to be ground."],
    ),
    ChallengeKanji(
      japanese: '目',
      english: 'Eye',
      memoryNotes: ["A 90 degree turned eye"],
    ),
    ChallengeKanji(
      japanese: '場',
      english: 'Place',
      memoryNotes: ["The sun reveals a place on the soil."],
    ),
    ChallengeKanji(
      japanese: '代',
      english: 'Generation, substitute',
      memoryNotes: ["A person holding a ceremony to celebrate the end of an era."],
    ),
    ChallengeKanji(
      japanese: '私',
      english: 'I, private',
      memoryNotes: ["Imagine yourself as a tree thinking about something personal."],
    ),
  ],
  // Day 17
  [
    ChallengeKanji(
      japanese: '立',
      english: 'Stand',
      memoryNotes: ["Looks a bit like a person standing"],
    ),
    ChallengeKanji(
      japanese: '物',
      english: 'Thing, object',
      memoryNotes: ["A cow with their box of things and a comb."],
    ),
    ChallengeKanji(
      japanese: '田',
      english: 'Rice field',
      memoryNotes: ["A window with crops growing out of it."],
    ),
    ChallengeKanji(
      japanese: '体',
      english: 'Body',
      memoryNotes: ["A person reading a book about the human body."],
    ),
    ChallengeKanji(
      japanese: '動',
      english: 'Move',
      memoryNotes: ["A strong man moves a heavy boulder."],
    ),
    ChallengeKanji(
      japanese: '社',
      english: 'Company, shrine',
      memoryNotes: ["A festival on the soil where a company celebrates."],
    ),
    ChallengeKanji(
      japanese: '知',
      english: 'Know',
      memoryNotes: ["Knowledge is like an arrow hitting your head."],
    ),
    ChallengeKanji(
      japanese: '理',
      english: 'Reason, logic',
      memoryNotes: ["Go to the king of the village for logic and wisdom."],
    ),
    ChallengeKanji(
      japanese: '同',
      english: 'Same',
      memoryNotes: ["When you enclose one mouth, everyone speaks the same, so it becomes \"same.\""],
    ),
    ChallengeKanji(
      japanese: '心',
      english: 'Heart, mind',
      memoryNotes: ["A heart with 'badump badump' shockwaves around it. The L looks like a heart"],
    ),
    ChallengeKanji(
      japanese: '発',
      english: 'Depart, emit',
      memoryNotes: ["A person's footsteps are heard as she departs and she waves with both hands."],
    ),
    ChallengeKanji(
      japanese: '作',
      english: 'Make, create',
      memoryNotes: ["A person is during the process of making something"],
    ),
    ChallengeKanji(
      japanese: '新',
      english: 'New',
      memoryNotes: ["A man stands up and cuts into a tree with an axe to make something new."],
    ),
    ChallengeKanji(
      japanese: '世',
      english: 'World, generation',
      memoryNotes: ["W for world."],
    ),
    ChallengeKanji(
      japanese: '度',
      english: 'Degree, measure',
      memoryNotes: ["Under a slanted roof, I do 20 push ups with my right hand."],
    ),
  ],
  // Day 18
  [
    ChallengeKanji(
      japanese: '明',
      english: 'Bright, clear',
      memoryNotes: ["When the sun and moon shine, it's bright."],
    ),
    ChallengeKanji(
      japanese: '力',
      english: 'Power, strength',
      memoryNotes: ["A strong man shouting 'kaaaa' (looks like the katakana symbol for ka)"],
    ),
    ChallengeKanji(
      japanese: '意',
      english: 'Meaning, intention, idea',
      memoryNotes: ["An idea is the sound of the heart."],
    ),
    ChallengeKanji(
      japanese: '用',
      english: 'Use',
      memoryNotes: ["Using a plough in a field."],
    ),
    ChallengeKanji(
      japanese: '主',
      english: 'Main, master',
      memoryNotes: ["A leader wearing a feather hat is the chief."],
    ),
    ChallengeKanji(
      japanese: '通',
      english: 'Pass through, traffic',
      memoryNotes: ["Passing through a road with walls on both sides."],
    ),
    ChallengeKanji(
      japanese: '文',
      english: 'Writing, text',
      memoryNotes: ["Writing a sentence with a sword themed pen."],
    ),
    ChallengeKanji(
      japanese: '屋',
      english: 'Roof, shop',
      memoryNotes: ["A zombie welcomes your arrival to the building/shop."],
    ),
    ChallengeKanji(
      japanese: '業',
      english: 'Work, business',
      memoryNotes: ["The boss of the company is a sheep wearing a crown and sitting on a tree themed throne."],
    ),
    ChallengeKanji(
      japanese: '持',
      english: 'Hold, carry',
      memoryNotes: ["Holding a temple in my hand."],
    ),
    ChallengeKanji(
      japanese: '道',
      english: 'Road, path',
      memoryNotes: ["A neck shaped car going down a road."],
    ),
    ChallengeKanji(
      japanese: '身',
      english: 'Body, oneself',
      memoryNotes: ["Someone with their heart over their chest thinking \"I'm a somebody\""],
    ),
    ChallengeKanji(
      japanese: '不',
      english: 'Not',
      memoryNotes: ["Looks like an incorrect cross on a sign."],
    ),
    ChallengeKanji(
      japanese: '口',
      english: 'Mouth',
      memoryNotes: ["Looks like an open mouth."],
    ),
    ChallengeKanji(
      japanese: '多',
      english: 'Many',
      memoryNotes: ["Many evenings of hard work."],
    ),
  ],
  // Day 19
  [
    ChallengeKanji(
      japanese: '野',
      english: 'Field, wild',
      memoryNotes: ["Before the village there were plains."],
    ),
    ChallengeKanji(
      japanese: '考',
      english: 'Think, consider',
      memoryNotes: ["An older person counting five pauses to consider."],
    ),
    ChallengeKanji(
      japanese: '開',
      english: 'Open',
      memoryNotes: ["Opening a gate and two hands."],
    ),
    ChallengeKanji(
      japanese: '教',
      english: 'Teach',
      memoryNotes: ["A respectful child receiving a strikes/challenges the mind to learn."],
    ),
    ChallengeKanji(
      japanese: '近',
      english: 'Near',
      memoryNotes: ["An axe getting closer to you."],
    ),
    ChallengeKanji(
      japanese: '以',
      english: 'By means of',
      memoryNotes: ["A face and a person."],
    ),
    ChallengeKanji(
      japanese: '問',
      english: 'Ask',
      memoryNotes: ["A gate with a mouth inside asks a question."],
    ),
    ChallengeKanji(
      japanese: '正',
      english: 'Correct, right',
      memoryNotes: ["Stop and listen to the truth."],
    ),
    ChallengeKanji(
      japanese: '真',
      english: 'True',
      memoryNotes: ["A tool which tells you the truth."],
    ),
    ChallengeKanji(
      japanese: '味',
      english: 'Taste, flavor',
      memoryNotes: ["A mouth tasting something not yet known discovers a new flavour."],
    ),
    ChallengeKanji(
      japanese: '界',
      english: 'World, boundary',
      memoryNotes: ["A person on stilts holding the world above their head, which is covered in fields."],
    ),
    ChallengeKanji(
      japanese: '無',
      english: 'Nothing, none',
      memoryNotes: ["A person with four hands burns all his positions and becomes nothing."],
    ),
    ChallengeKanji(
      japanese: '少',
      english: 'Few, little',
      memoryNotes: ["Only a few are cooked properly. (So he's only smiling slightly)"],
    ),
    ChallengeKanji(
      japanese: '海',
      english: 'Sea, ocean',
      memoryNotes: ["Every water = sea."],
    ),
    ChallengeKanji(
      japanese: '切',
      english: 'Cut',
      memoryNotes: ["Cutting something with a number 7 shaped sword."],
    ),
  ],
  // Day 20
  [
    ChallengeKanji(
      japanese: '重',
      english: 'Heavy, important',
      memoryNotes: ["A thousand villages would be really heavy."],
    ),
    ChallengeKanji(
      japanese: '集',
      english: 'Gather',
      memoryNotes: ["A bird in a tree gathering sticks for a nest."],
    ),
    ChallengeKanji(
      japanese: '員',
      english: 'Member',
      memoryNotes: ["An employee shellfish with a big mouth."],
    ),
    ChallengeKanji(
      japanese: '公',
      english: 'Public',
      memoryNotes: ["Something private separated out becomes public."],
    ),
    ChallengeKanji(
      japanese: '画',
      english: 'Picture, drawing, stroke',
      memoryNotes: ["A picture of a field inside a box."],
    ),
    ChallengeKanji(
      japanese: '死',
      english: 'Death',
      memoryNotes: ["A crescent moon who dies by spoon."],
    ),
    ChallengeKanji(
      japanese: '安',
      english: 'Peaceful, cheap',
      memoryNotes: ["A minimalist woman under a roof lives cheaply and peacefully."],
    ),
    ChallengeKanji(
      japanese: '親',
      english: 'Parent, intimate',
      memoryNotes: ["Parents stand by the tree and watch over their child."],
    ),
    ChallengeKanji(
      japanese: '強',
      english: 'Strong',
      memoryNotes: ["Shooting a powerful insect with a bow."],
    ),
    ChallengeKanji(
      japanese: '使',
      english: 'Use, messenger',
      memoryNotes: ["A person serving an officer is used for many tasks."],
    ),
    ChallengeKanji(
      japanese: '朝',
      english: 'Morning, dynasty',
      memoryNotes: ["Early in the morning you can still see the moon."],
    ),
    ChallengeKanji(
      japanese: '題',
      english: 'Topic, title',
      memoryNotes: ["A topic about justice for lobsters."],
    ),
    ChallengeKanji(
      japanese: '仕',
      english: 'Serve, job',
      memoryNotes: ["A person becomes a samurai for work, and serves his people."],
    ),
    ChallengeKanji(
      japanese: '京',
      english: 'Capital',
      memoryNotes: ["A small capital city inside of a pot."],
    ),
    ChallengeKanji(
      japanese: '足',
      english: 'Foot, sufficient',
      memoryNotes: ["Looks like a person with a very big foot."],
    ),
  ],
  // Day 21
  [
    ChallengeKanji(
      japanese: '品',
      english: 'Goods, items',
      memoryNotes: ["Looks like boxes of goods."],
    ),
    ChallengeKanji(
      japanese: '着',
      english: 'Wear, arrive',
      memoryNotes: ["Looking at what the sheep is wearing when I arrive at the party."],
    ),
    ChallengeKanji(
      japanese: '別',
      english: 'Separate, another',
      memoryNotes: ["Separating a sword from a box with another sword."],
    ),
    ChallengeKanji(
      japanese: '音',
      english: 'Sound',
      memoryNotes: ["The sun stands at the podium and makes a sound."],
    ),
    ChallengeKanji(
      japanese: '元',
      english: 'Origin, base',
      memoryNotes: ["Two little legs take the very first step at the origin."],
    ),
    ChallengeKanji(
      japanese: '特',
      english: 'Special',
      memoryNotes: ["A special temple dedicated to a cow."],
    ),
    ChallengeKanji(
      japanese: '風',
      english: 'Wind, style',
      memoryNotes: ["A tornado of insects."],
    ),
    ChallengeKanji(
      japanese: '夜',
      english: 'Night',
      memoryNotes: ["A person looking at the crescent moon at night time."],
    ),
    ChallengeKanji(
      japanese: '空',
      english: 'Sky, empty',
      memoryNotes: ["A creator crafts a hole which becomes the sky."],
    ),
    ChallengeKanji(
      japanese: '有',
      english: 'Have, exist',
      memoryNotes: ["You hold the moon close and say na to show you possess it."],
    ),
    ChallengeKanji(
      japanese: '起',
      english: 'Wake up, rise',
      memoryNotes: ["Waking yourself up to go run."],
    ),
    ChallengeKanji(
      japanese: '運',
      english: 'Carry, fortune',
      memoryNotes: ["An army on the move carrying resources, the crowd wishing them good luck."],
    ),
    ChallengeKanji(
      japanese: '料',
      english: 'Materials, fee',
      memoryNotes: ["Rice and a dipper."],
    ),
    ChallengeKanji(
      japanese: '楽',
      english: 'Comfort, music',
      memoryNotes: ["Having fun and listening to music at the icy white tree."],
    ),
    ChallengeKanji(
      japanese: '色',
      english: 'Color',
      memoryNotes: ["A rainbow coloured computer mouse (kanji looks like a computer mouse)."],
    ),
  ],
  // Day 22 - rest day, no new cards
  [],
  // Day 23
  [
    ChallengeKanji(
      japanese: '帰',
      english: 'Return',
      memoryNotes: ["The sword and broom return home."],
    ),
    ChallengeKanji(
      japanese: '歩',
      english: 'Walk',
      memoryNotes: ["I stop a few times during my walk."],
    ),
    ChallengeKanji(
      japanese: '悪',
      english: 'Bad, evil',
      memoryNotes: ["When the heart is pushed down, things get bad."],
    ),
    ChallengeKanji(
      japanese: '広',
      english: 'Wide, broad',
      memoryNotes: ["A wide private space under a slanted roof."],
    ),
    ChallengeKanji(
      japanese: '店',
      english: 'Shop, store',
      memoryNotes: ["A shop where you can get your fortune told. Or a roof occupied by a shop."],
    ),
    ChallengeKanji(
      japanese: '町',
      english: 'Town',
      memoryNotes: ["A small town with fields on the street."],
    ),
    ChallengeKanji(
      japanese: '住',
      english: 'Live, reside',
      memoryNotes: ["A person becomes the chief of where they live."],
    ),
    ChallengeKanji(
      japanese: '売',
      english: 'Sell',
      memoryNotes: ["A samurai running around selling crowns."],
    ),
    ChallengeKanji(
      japanese: '待',
      english: 'Wait',
      memoryNotes: ["Stepping back and forth at a temple whilst waiting for someone."],
    ),
    ChallengeKanji(
      japanese: '古',
      english: 'Old',
      memoryNotes: ["A mouth that has spoken for ten generations is old."],
    ),
    ChallengeKanji(
      japanese: '始',
      english: 'Begin',
      memoryNotes: ["A woman stepping onto a little pedestal marks the beginning."],
    ),
    ChallengeKanji(
      japanese: '終',
      english: 'End, finish',
      memoryNotes: ["String from spring to winter marking the end of the year."],
    ),
    ChallengeKanji(
      japanese: '計',
      english: 'Measure, plan',
      memoryNotes: ["Saying your plan in 10 stages."],
    ),
    ChallengeKanji(
      japanese: '院',
      english: 'Institution',
      memoryNotes: ["A building finished on the side of a hill becomes an institution."],
    ),
    ChallengeKanji(
      japanese: '送',
      english: 'Send',
      memoryNotes: ["Sending something to people you have relation with."],
    ),
  ],
  // Day 24
  [
    ChallengeKanji(
      japanese: '族',
      english: 'Tribe, family',
      memoryNotes: ["People shooting their arrows in the same direction belong to one clan."],
    ),
    ChallengeKanji(
      japanese: '映',
      english: 'Reflect, project',
      memoryNotes: ["The sun is shining in the center of a mirror."],
    ),
    ChallengeKanji(
      japanese: '買',
      english: 'Buy',
      memoryNotes: ["Shellfish caught in a net are bought."],
    ),
    ChallengeKanji(
      japanese: '病',
      english: 'Illness',
      memoryNotes: ["I'm sick so I stay inside."],
    ),
    ChallengeKanji(
      japanese: '早',
      english: 'Early, fast',
      memoryNotes: ["The sun rises early before 10am."],
    ),
    ChallengeKanji(
      japanese: '質',
      english: 'Quality, matter',
      memoryNotes: ["Checking the quality of lobsters with an axe."],
    ),
    ChallengeKanji(
      japanese: '台',
      english: 'Stand, platform',
      memoryNotes: ["Resembles a pedestal."],
    ),
    ChallengeKanji(
      japanese: '室',
      english: 'Room',
      memoryNotes: ["Arriving at the room."],
    ),
    ChallengeKanji(
      japanese: '可',
      english: 'Possible, allowed',
      memoryNotes: ["Shocked because a street is completely empty (how is it possible)."],
    ),
    ChallengeKanji(
      japanese: '建',
      english: 'Build',
      memoryNotes: ["Long strides and an architect's brushstrokes allow you to build something."],
    ),
    ChallengeKanji(
      japanese: '転',
      english: 'Turn',
      memoryNotes: ["A vehicle saying 'turning' as it turns."],
    ),
    ChallengeKanji(
      japanese: '医',
      english: 'Doctor, medicine',
      memoryNotes: ["An arrow is taken out of the soldier's arm by a doctor and put in a box."],
    ),
    ChallengeKanji(
      japanese: '止',
      english: 'Stop',
      memoryNotes: ["A stop sign going up to the sky."],
    ),
    ChallengeKanji(
      japanese: '字',
      english: 'Character, letter',
      memoryNotes: ["A child under a roof learns each character."],
    ),
    ChallengeKanji(
      japanese: '工',
      english: 'Craft, construction',
      memoryNotes: ["People shouting 'eeee' while crafting things."],
    ),
  ],
  // Day 25
  [
    ChallengeKanji(
      japanese: '急',
      english: 'Hurry, urgent',
      memoryNotes: ["Wrap your hands around a broom and clean in a hurry, your mind is shaken from the rush."],
    ),
    ChallengeKanji(
      japanese: '図',
      english: 'Diagram, map',
      memoryNotes: ["X marks the spot on a treasure map!"],
    ),
    ChallengeKanji(
      japanese: '黒',
      english: 'Black',
      memoryNotes: ["A burned down village is black."],
    ),
    ChallengeKanji(
      japanese: '花',
      english: 'Flower',
      memoryNotes: ["Grass changes into a flower."],
    ),
    ChallengeKanji(
      japanese: '英',
      english: 'England',
      memoryNotes: ["Grass around the hero's sword with an english flag on it."],
    ),
    ChallengeKanji(
      japanese: '走',
      english: 'Run',
      memoryNotes: ["Running on the soil."],
    ),
    ChallengeKanji(
      japanese: '青',
      english: 'Blue, green (Japanese sense)',
      memoryNotes: ["The king looks up at the moon on a clear blue night sky."],
    ),
    ChallengeKanji(
      japanese: '答',
      english: 'Answer',
      memoryNotes: ["Align the bamboo to reveal the answer."],
    ),
    ChallengeKanji(
      japanese: '紙',
      english: 'Paper',
      memoryNotes: ["The family business is turning thread into paper."],
    ),
    ChallengeKanji(
      japanese: '歌',
      english: 'Song, sing',
      memoryNotes: ["It is possible to make a song about something you lack."],
    ),
    ChallengeKanji(
      japanese: '注',
      english: 'Pour, note',
      memoryNotes: ["The chief pours water for his subordinate."],
    ),
    ChallengeKanji(
      japanese: '赤',
      english: 'Red',
      memoryNotes: ["Soil turned into red paint again, again, and again."],
    ),
    ChallengeKanji(
      japanese: '春',
      english: 'Spring',
      memoryNotes: ["Three people enjoying the sun in spring."],
    ),
    ChallengeKanji(
      japanese: '館',
      english: 'Building, hall',
      memoryNotes: ["Bureaucrats eating food in a grand building."],
    ),
    ChallengeKanji(
      japanese: '旅',
      english: 'Travel',
      memoryNotes: ["A person chooses a direction for their trip."],
    ),
  ],
  // Day 26
  [
    ChallengeKanji(
      japanese: '験',
      english: 'Test, experience',
      memoryNotes: ["A person and a horse matched together gain experience."],
    ),
    ChallengeKanji(
      japanese: '写',
      english: 'Copy',
      memoryNotes: ["Give a photograph of a king."],
    ),
    ChallengeKanji(
      japanese: '去',
      english: 'Leave, past',
      memoryNotes: ["A private memory box left behind in the soil."],
    ),
    ChallengeKanji(
      japanese: '研',
      english: 'Sharpen, study',
      memoryNotes: ["Polishing something with a stone and both hands."],
    ),
    ChallengeKanji(
      japanese: '飲',
      english: 'Drink',
      memoryNotes: ["If there's a lack of food, drink something instead."],
    ),
    ChallengeKanji(
      japanese: '肉',
      english: 'Meat',
      memoryNotes: ["Two people taking ribs out of a box."],
    ),
    ChallengeKanji(
      japanese: '服',
      english: 'Clothes',
      memoryNotes: ["Dressing a moon and zipping up the jacket with my right hand."],
    ),
    ChallengeKanji(
      japanese: '銀',
      english: 'Silver',
      memoryNotes: ["At the boundary of gold, silver is next."],
    ),
    ChallengeKanji(
      japanese: '茶',
      english: 'Tea',
      memoryNotes: ["A person making tea out of herbs in a tree house."],
    ),
    ChallengeKanji(
      japanese: '究',
      english: 'Research',
      memoryNotes: ["A scientist crawls into a hole shaped like a nine to do research."],
    ),
    ChallengeKanji(
      japanese: '洋',
      english: 'Ocean, Western',
      memoryNotes: ["American sheep in the American sea."],
    ),
    ChallengeKanji(
      japanese: '兄',
      english: 'Older brother',
      memoryNotes: ["An older brother with only a head and legs."],
    ),
    ChallengeKanji(
      japanese: '秋',
      english: 'Autumn',
      memoryNotes: ["A tree with orange (fiery leaves) indicating autumn time."],
    ),
    ChallengeKanji(
      japanese: '堂',
      english: 'Hall',
      memoryNotes: ["Under a small roof many mouths gather on the soil in a great hall."],
    ),
    ChallengeKanji(
      japanese: '週',
      english: 'Week',
      memoryNotes: ["The week goes around and around."],
    ),
  ],
  // Day 27
  [
    ChallengeKanji(
      japanese: '習',
      english: 'Learn, practice',
      memoryNotes: ["White feathers flapping trying to learn how to fly."],
    ),
    ChallengeKanji(
      japanese: '試',
      english: 'Try, test',
      memoryNotes: ["Saying you passed the test in style!"],
    ),
    ChallengeKanji(
      japanese: '夏',
      english: 'Summer',
      memoryNotes: ["You brave the winter and make it to the hot summer."],
    ),
    ChallengeKanji(
      japanese: '弟',
      english: 'Younger brother',
      memoryNotes: ["A younger brother has a talent for archery."],
    ),
    ChallengeKanji(
      japanese: '鳥',
      english: 'Bird',
      memoryNotes: ["A white bird with fire elemental powers."],
    ),
    ChallengeKanji(
      japanese: '犬',
      english: 'Dog',
      memoryNotes: ["The dot on top is like a wagging tail, a big dog."],
    ),
    ChallengeKanji(
      japanese: '夕',
      english: 'Evening',
      memoryNotes: ["A crescent moon indicating evening time."],
    ),
    ChallengeKanji(
      japanese: '魚',
      english: 'Fish',
      memoryNotes: ["A person catching a big goldfish in a rice paddy."],
    ),
    ChallengeKanji(
      japanese: '借',
      english: 'Borrow',
      memoryNotes: ["A person borrows a fairytale book."],
    ),
    ChallengeKanji(
      japanese: '飯',
      english: 'Cooked rice, meal',
      memoryNotes: ["Anti-food, the meal was eaten very quickly."],
    ),
  ],
  // Day 28
  [
    ChallengeKanji(
      japanese: '駅',
      english: 'Station',
      memoryNotes: ["A horse gets on a train with a big R on it."],
    ),
    ChallengeKanji(
      japanese: '昼',
      english: 'Noon, daytime',
      memoryNotes: ["A big sun in the shape of an R at noon."],
    ),
    ChallengeKanji(
      japanese: '冬',
      english: 'Winter',
      memoryNotes: ["Winter is cold and icy."],
    ),
    ChallengeKanji(
      japanese: '姉',
      english: 'Older sister',
      memoryNotes: ["A woman with a city scarf on her shoulders is the older sister."],
    ),
    ChallengeKanji(
      japanese: '曜',
      english: 'Day of the week',
      memoryNotes: ["A mythical bird tells the sun about days of the week."],
    ),
    ChallengeKanji(
      japanese: '漢',
      english: 'Chinese, Sino-',
      memoryNotes: ["A husband eating grass by the river near the great wall of china."],
    ),
    ChallengeKanji(
      japanese: '牛',
      english: 'Cow, ox',
      memoryNotes: ["A cow eating lunch at noon."],
    ),
    ChallengeKanji(
      japanese: '妹',
      english: 'Younger sister',
      memoryNotes: ["A woman who is not yet grown is the younger sister."],
    ),
    ChallengeKanji(
      japanese: '貸',
      english: 'Lend',
      memoryNotes: ["A fisherman getting a loan as a substitute for selling lobsters."],
    ),
    ChallengeKanji(
      japanese: '勉',
      english: 'Endeavor, exertion',
      memoryNotes: ["Pushing past excuses with power when you exert yourself."],
    ),
  ],
  // Day 29 - rest day, no new cards
  [],
  // Day 30
  [
    ChallengeKanji(
      japanese: '合',
      english: 'Fit, match',
      memoryNotes: ["Two people with matching mouths"],
    ),
    ChallengeKanji(
      japanese: '部',
      english: 'Section, department',
      memoryNotes: ["A person standing and talking about turning a section of land into a village"],
    ),
    ChallengeKanji(
      japanese: '彼',
      english: 'He',
      memoryNotes: ["He steps forward taking the insults because he has thick skin"],
    ),
    ChallengeKanji(
      japanese: '内',
      english: 'Inside',
      memoryNotes: ["A person enclosed within walls is inside."],
    ),
    ChallengeKanji(
      japanese: '実',
      english: 'Real, truth',
      memoryNotes: ["Under a roof, three laws of reality are revealed."],
    ),
    ChallengeKanji(
      japanese: '当',
      english: 'Hit, appropriate',
      memoryNotes: ["Hitting a small object with a broom"],
    ),
    ChallengeKanji(
      japanese: '戦',
      english: 'War, battle',
      memoryNotes: ["A simple clash of spears turns into war."],
    ),
    ChallengeKanji(
      japanese: '性',
      english: 'Nature, gender',
      memoryNotes: ["The heart you live with."],
    ),
    ChallengeKanji(
      japanese: '対',
      english: 'Oppose',
      memoryNotes: ["Literature face to face with math."],
    ),
    ChallengeKanji(
      japanese: '関',
      english: 'Connection',
      memoryNotes: ["Through a gate of making relations in the sky."],
    ),
    ChallengeKanji(
      japanese: '感',
      english: 'Feeling, sense',
      memoryNotes: ["Emotion has everything to do with the heart"],
    ),
    ChallengeKanji(
      japanese: '定',
      english: 'Decide, fix',
      memoryNotes: ["Under a roof, truth is decided."],
    ),
    ChallengeKanji(
      japanese: '政',
      english: 'Politics',
      memoryNotes: ["Trying to enforce what is correct is politics."],
    ),
    ChallengeKanji(
      japanese: '取',
      english: 'Take',
      memoryNotes: ["A right hand grabs an ear and takes it."],
    ),
    ChallengeKanji(
      japanese: '所',
      english: 'Place',
      memoryNotes: ["Throwing an axe at a door to mark the location."],
    ),
  ],
  // Day 31
  [
    ChallengeKanji(
      japanese: '現',
      english: 'Present, appear',
      memoryNotes: ["Look the king has appeared."],
    ),
    ChallengeKanji(
      japanese: '最',
      english: 'Most, utmost',
      memoryNotes: ["Taking the sun is the most dangerous heist ever."],
    ),
    ChallengeKanji(
      japanese: '化',
      english: 'Change, transform',
      memoryNotes: ["A person uses a spoon to change milk and eggs into batter."],
    ),
    ChallengeKanji(
      japanese: '民',
      english: 'People, nation',
      memoryNotes: ["People hold up a flag for a ceremony of people."],
    ),
    ChallengeKanji(
      japanese: '相',
      english: 'Mutual, minister, appearance',
      memoryNotes: ["An eye and a tree mutually agree."],
    ),
    ChallengeKanji(
      japanese: '法',
      english: 'Law, method',
      memoryNotes: ["The law of tea is to leave the teabag in water."],
    ),
    ChallengeKanji(
      japanese: '全',
      english: 'Whole, all',
      memoryNotes: ["A person gives his entire being to the king."],
    ),
    ChallengeKanji(
      japanese: '情',
      english: 'Emotion, condition',
      memoryNotes: ["A heart turns blue with feelings."],
    ),
    ChallengeKanji(
      japanese: '向',
      english: 'Direction, face',
      memoryNotes: ["Facing a cyclops."],
    ),
    ChallengeKanji(
      japanese: '平',
      english: 'Flat, peace',
      memoryNotes: ["A dry, flat, and peaceful land."],
    ),
    ChallengeKanji(
      japanese: '成',
      english: 'Become, achieve',
      memoryNotes: ["A sword turned into a spear."],
    ),
    ChallengeKanji(
      japanese: '経',
      english: 'Pass through, manage',
      memoryNotes: ["A sacred thread scroll explains the sutra."],
    ),
    ChallengeKanji(
      japanese: '信',
      english: 'Trust, believe',
      memoryNotes: ["A person who speaks the truth is trustworthy."],
    ),
    ChallengeKanji(
      japanese: '面',
      english: 'Face, surface',
      memoryNotes: ["A big eye and face on the tv."],
    ),
    ChallengeKanji(
      japanese: '連',
      english: 'Connect, take along',
      memoryNotes: ["A car that goes brings others with it."],
    ),
  ],
  // Day 32
  [
    ChallengeKanji(
      japanese: '原',
      english: 'Origin, field',
      memoryNotes: ["White grass meadow on a small cliff."],
    ),
    ChallengeKanji(
      japanese: '顔',
      english: 'Face',
      memoryNotes: ["A person standing with fur and shellfish on their face"],
    ),
    ChallengeKanji(
      japanese: '機',
      english: 'Machine, opportunity',
      memoryNotes: ["A device wade of wood counts how many threads to use and make something."],
    ),
    ChallengeKanji(
      japanese: '次',
      english: 'Next',
      memoryNotes: ["Since I lack ice my next step is to get some"],
    ),
    ChallengeKanji(
      japanese: '数',
      english: 'Number',
      memoryNotes: ["A woman counting rice messes up so she strikes the table."],
    ),
    ChallengeKanji(
      japanese: '美',
      english: 'Beauty',
      memoryNotes: ["A big beautiful sheep."],
    ),
    ChallengeKanji(
      japanese: '回',
      english: 'Turn, rotate',
      memoryNotes: ["Putting a box in a box several times."],
    ),
    ChallengeKanji(
      japanese: '表',
      english: 'Surface, express',
      memoryNotes: ["A king's clothes show the surface."],
    ),
    ChallengeKanji(
      japanese: '声',
      english: 'Voice',
      memoryNotes: ["A samurai speaking about his flag."],
    ),
    ChallengeKanji(
      japanese: '報',
      english: 'Report, inform',
      memoryNotes: ["Good news gets the stamp of approval for the report."],
    ),
    ChallengeKanji(
      japanese: '要',
      english: 'Need, essential',
      memoryNotes: ["A woman moves west to find water."],
    ),
    ChallengeKanji(
      japanese: '変',
      english: 'Change',
      memoryNotes: ["When winter comes again, things feel strange."],
    ),
    ChallengeKanji(
      japanese: '神',
      english: 'God, spirit',
      memoryNotes: ["A festival in the field for a deity."],
    ),
    ChallengeKanji(
      japanese: '記',
      english: 'Record, write',
      memoryNotes: ["You are a journalist who records what people say."],
    ),
    ChallengeKanji(
      japanese: '和',
      english: 'Peace, Japan',
      memoryNotes: ["A peaceful japanese bonsai tree with a mouth"],
    ),
  ],
  // Day 33
  [
    ChallengeKanji(
      japanese: '引',
      english: 'Pull',
      memoryNotes: ["You pull back a bow and arrow."],
    ),
    ChallengeKanji(
      japanese: '治',
      english: 'Heal, govern',
      memoryNotes: ["Healing water on a pedestal."],
    ),
    ChallengeKanji(
      japanese: '決',
      english: 'Decide',
      memoryNotes: ["A big decision on which water to choose… One is poisoned."],
    ),
    ChallengeKanji(
      japanese: '太',
      english: 'Thick, great',
      memoryNotes: ["Thick and fat are similar concepts to big"],
    ),
    ChallengeKanji(
      japanese: '込',
      english: 'Crowded, include',
      memoryNotes: ["People go inside and it becomes crowded."],
    ),
    ChallengeKanji(
      japanese: '受',
      english: 'Receive',
      memoryNotes: ["Receiving a small crown with your right hand."],
    ),
    ChallengeKanji(
      japanese: '解',
      english: 'Solve, understand',
      memoryNotes: ["A cow sitting in the corner unties a knot with a sword."],
    ),
    ChallengeKanji(
      japanese: '市',
      english: 'City',
      memoryNotes: ["Lids and cloth hang for sale in the market."],
    ),
    ChallengeKanji(
      japanese: '期',
      english: 'Period, term',
      memoryNotes: ["Measuring a period of time using the moon as a tool"],
    ),
    ChallengeKanji(
      japanese: '様',
      english: 'Appearance, manner',
      memoryNotes: ["A drenched sheep wearing a tree hat"],
    ),
    ChallengeKanji(
      japanese: '活',
      english: 'Life, active',
      memoryNotes: ["A lively person has a wet tongue."],
    ),
    ChallengeKanji(
      japanese: '頭',
      english: 'Head',
      memoryNotes: ["The brain is a bean thinking about shellfish."],
    ),
    ChallengeKanji(
      japanese: '組',
      english: 'Group, assemble',
      memoryNotes: ["Tying a group of eyes together with a thread."],
    ),
    ChallengeKanji(
      japanese: '指',
      english: 'Finger, point',
      memoryNotes: ["A man with spoons for fingers points at the sun"],
    ),
    ChallengeKanji(
      japanese: '説',
      english: 'Explain',
      memoryNotes: ["The older brother speaks about his opinion."],
    ),
  ],
  // Day 34
  [
    ChallengeKanji(
      japanese: '能',
      english: 'Ability, capability',
      memoryNotes: ["A cow with an ability to turn into a were-cow when the moon comes out, it uses spoons as its weapon"],
    ),
    ChallengeKanji(
      japanese: '葉',
      english: 'Leaf',
      memoryNotes: ["Every tree in the world has grass on it called leaves."],
    ),
    ChallengeKanji(
      japanese: '流',
      english: 'Flow',
      memoryNotes: ["Water flowing in a secret private river where a fashion runway is."],
    ),
    ChallengeKanji(
      japanese: '然',
      english: 'So, thus, natural',
      memoryNotes: ["In the evening, a dog by the fire."],
    ),
    ChallengeKanji(
      japanese: '初',
      english: 'Beginning, first',
      memoryNotes: ["Cutting cloth with a sword/blade marks the first beginning."],
    ),
    ChallengeKanji(
      japanese: '在',
      english: 'Exist',
      memoryNotes: ["A genius meditating on the soil."],
    ),
    ChallengeKanji(
      japanese: '調',
      english: 'Investigate, tune',
      memoryNotes: ["Saying things in a circle to try to solve the investigation."],
    ),
    ChallengeKanji(
      japanese: '笑',
      english: 'Laugh, smile',
      memoryNotes: ["A big bamboo smiley face in the sky."],
    ),
    ChallengeKanji(
      japanese: '議',
      english: 'Discuss, deliberate',
      memoryNotes: ["Talking about what's just in the discussion."],
    ),
    ChallengeKanji(
      japanese: '直',
      english: 'Straight, fix',
      memoryNotes: ["Looking straightaway at the giant L."],
    ),
    ChallengeKanji(
      japanese: '夫',
      english: 'Husband, man',
      memoryNotes: ["A husband doing work in the soil."],
    ),
    ChallengeKanji(
      japanese: '選',
      english: 'Choose, elect',
      memoryNotes: ["Comparing ideas with yourself to make a choice."],
    ),
    ChallengeKanji(
      japanese: '権',
      english: 'Authority, rights',
      memoryNotes: ["A bird person on top of the tree is the authority."],
    ),
    ChallengeKanji(
      japanese: '利',
      english: 'Profit, benefit',
      memoryNotes: ["Trees being cut with a sword to make a profit."],
    ),
    ChallengeKanji(
      japanese: '制',
      english: 'System, control',
      memoryNotes: ["A system to wash a cloth covered in soil."],
    ),
  ],
  // Day 35
  [
    ChallengeKanji(
      japanese: '続',
      english: 'Continue',
      memoryNotes: ["Thread that keeps being sold keeps the business continuing."],
    ),
    ChallengeKanji(
      japanese: '石',
      english: 'Stone',
      memoryNotes: ["Biting a T shaped stone."],
    ),
    ChallengeKanji(
      japanese: '進',
      english: 'Advance',
      memoryNotes: ["A bird moving forward continues onward."],
    ),
    ChallengeKanji(
      japanese: '伝',
      english: 'Transmit, convey',
      memoryNotes: ["A person who says something passes it along."],
    ),
    ChallengeKanji(
      japanese: '加',
      english: 'Add',
      memoryNotes: ["Using the power of your mouth to add food to your body."],
    ),
    ChallengeKanji(
      japanese: '助',
      english: 'Help',
      memoryNotes: ["An all seeing powerful eye helps others."],
    ),
    ChallengeKanji(
      japanese: '点',
      english: 'Point, dot',
      memoryNotes: ["A divine fiery dot."],
    ),
    ChallengeKanji(
      japanese: '産',
      english: 'Produce, give birth',
      memoryNotes: ["Standing at a cliff where products are born."],
    ),
    ChallengeKanji(
      japanese: '務',
      english: 'Duty, task',
      memoryNotes: ["Using weapons, effort, and power to complete a task."],
    ),
    ChallengeKanji(
      japanese: '件',
      english: 'Matter, case',
      memoryNotes: ["The cow incident."],
    ),
    ChallengeKanji(
      japanese: '命',
      english: 'Life, order',
      memoryNotes: ["A person's mouth sealed by fate."],
    ),
    ChallengeKanji(
      japanese: '番',
      english: 'Number, turn',
      memoryNotes: ["Numbered trees in a field"],
    ),
    ChallengeKanji(
      japanese: '落',
      english: 'Fall, drop',
      memoryNotes: ["Each grass blade falls after being washed away by water."],
    ),
    ChallengeKanji(
      japanese: '付',
      english: 'Attach, apply',
      memoryNotes: ["A person attaching rulers together."],
    ),
    ChallengeKanji(
      japanese: '得',
      english: 'Gain, obtain',
      memoryNotes: ["Walking through a large amount of days until you gain something."],
    ),
  ],
  // Day 36 - rest day, no new cards
  [],
  // Day 37
  [
    ChallengeKanji(
      japanese: '好',
      english: 'Like, fond',
      memoryNotes: ["A mother likes her child."],
    ),
    ChallengeKanji(
      japanese: '違',
      english: 'Differ, wrong',
      memoryNotes: ["Going down 5 steps is different from taking the elevator."],
    ),
    ChallengeKanji(
      japanese: '殺',
      english: 'Kill',
      memoryNotes: ["Cutting through a tree and killing it with two sword weapons."],
    ),
    ChallengeKanji(
      japanese: '置',
      english: 'Place, set',
      memoryNotes: ["Something is caught in a net straightaway and placed down."],
    ),
    ChallengeKanji(
      japanese: '返',
      english: 'Return, turn over',
      memoryNotes: ["You go the opposite direction to return."],
    ),
    ChallengeKanji(
      japanese: '論',
      english: 'Discuss, theory',
      memoryNotes: ["People arguing by a bookshelf."],
    ),
    ChallengeKanji(
      japanese: '際',
      english: 'Occasion, edge, verge',
      memoryNotes: ["A special occasion where we have a ritual on a hill."],
    ),
    ChallengeKanji(
      japanese: '歳',
      english: 'Years, age',
      memoryNotes: ["Stopping a small spear to mark your age."],
    ),
    ChallengeKanji(
      japanese: '反',
      english: 'Oppose, anti-',
      memoryNotes: ["A sign saying don't climb the cliff with your right hand, anti- right hand/cliff."],
    ),
    ChallengeKanji(
      japanese: '形',
      english: 'Shape, form',
      memoryNotes: ["Using both hands to create shapes out of fur."],
    ),
    ChallengeKanji(
      japanese: '光',
      english: 'Light',
      memoryNotes: ["Small legs running fast leave trails of light."],
    ),
    ChallengeKanji(
      japanese: '首',
      english: 'Neck, head, chief',
      memoryNotes: ["Grass growing on your own neck."],
    ),
    ChallengeKanji(
      japanese: '勝',
      english: 'Win, victory',
      memoryNotes: ["Winning with muscle and fire power."],
    ),
    ChallengeKanji(
      japanese: '必',
      english: 'Certainly, without fail',
      memoryNotes: ["I cross my heart because I'm certain."],
    ),
    ChallengeKanji(
      japanese: '係',
      english: 'Connection, person in charge',
      memoryNotes: ["A person tied to a lineage is in charge e.g inheriting the business."],
    ),
  ],
  // Day 38
  [
    ChallengeKanji(
      japanese: '由',
      english: 'Reason, cause',
      memoryNotes: ["A field that shows where a train passes through. I wonder why?"],
    ),
    ChallengeKanji(
      japanese: '愛',
      english: 'Love',
      memoryNotes: ["I love the winter themed small crown with all my heart"],
    ),
    ChallengeKanji(
      japanese: '都',
      english: 'Capital, metropolis',
      memoryNotes: ["Someone creates a village that becomes a capital."],
    ),
    ChallengeKanji(
      japanese: '放',
      english: 'Release, let go',
      memoryNotes: ["How to strike the lock to set something free."],
    ),
    ChallengeKanji(
      japanese: '確',
      english: 'Certain, confirm',
      memoryNotes: ["The bird wearing a crown is sure as stone"],
    ),
    ChallengeKanji(
      japanese: '過',
      english: 'Pass, exceed',
      memoryNotes: ["A boxer with a crooked mouth exceeds everyone's expectations."],
    ),
    ChallengeKanji(
      japanese: '約',
      english: 'Promise, approx.',
      memoryNotes: ["Thread wrapped tightly makes a promise."],
    ),
    ChallengeKanji(
      japanese: '馬',
      english: 'Horse',
      memoryNotes: ["A fiery horse with the head of a bird."],
    ),
    ChallengeKanji(
      japanese: '状',
      english: 'Condition, form',
      memoryNotes: ["A dog inside a house safe from the icy conditions."],
    ),
    ChallengeKanji(
      japanese: '想',
      english: 'Think, imagine',
      memoryNotes: ["Thinking about a tree and an eye."],
    ),
    ChallengeKanji(
      japanese: '官',
      english: 'Official',
      memoryNotes: ["Under a roof Bureaucrats form the government."],
    ),
    ChallengeKanji(
      japanese: '交',
      english: 'Mingle',
      memoryNotes: ["A father mingling with others showing his bottle cap collection."],
    ),
    ChallengeKanji(
      japanese: '米',
      english: 'Rice',
      memoryNotes: ["A tree with rice falling from it."],
    ),
    ChallengeKanji(
      japanese: '配',
      english: 'Distribute',
      memoryNotes: ["Distributing alcohol."],
    ),
    ChallengeKanji(
      japanese: '若',
      english: 'Young',
      memoryNotes: ["The young grass is on the right."],
    ),
  ],
  // Day 39
  [
    ChallengeKanji(
      japanese: '資',
      english: 'Resources, capital',
      memoryNotes: ["The money you use next are your resources/assets."],
    ),
    ChallengeKanji(
      japanese: '常',
      english: 'Usual, normal',
      memoryNotes: ["It's normal to wear plenty of cloth in winter."],
    ),
    ChallengeKanji(
      japanese: '果',
      english: 'Fruit, result',
      memoryNotes: ["A field of trees growing fruit."],
    ),
    ChallengeKanji(
      japanese: '呼',
      english: 'Call',
      memoryNotes: ["A mouth asks a question out loud."],
    ),
    ChallengeKanji(
      japanese: '共',
      english: 'Together, both',
      memoryNotes: ["Two people eating ice cream together beside a fence."],
    ),
    ChallengeKanji(
      japanese: '残',
      english: 'Remain',
      memoryNotes: ["After the death a few spears are left, so something remains."],
    ),
    ChallengeKanji(
      japanese: '判',
      english: 'Judge, decision',
      memoryNotes: ["Judgement as to whether or not to be cut in half as punishment."],
    ),
    ChallengeKanji(
      japanese: '役',
      english: 'Role, service',
      memoryNotes: ["Stepping with a weapon is the soldier's duty."],
    ),
    ChallengeKanji(
      japanese: '他',
      english: 'Other',
      memoryNotes: ["To be a person is to be different or other from everyone else."],
    ),
    ChallengeKanji(
      japanese: '術',
      english: 'Art, technique',
      memoryNotes: ["An engineer stepping towards a tree street to use their techniques."],
    ),
    ChallengeKanji(
      japanese: '支',
      english: 'Support, branch',
      memoryNotes: ["A samurai's right hand is a branch. The branch supports him."],
    ),
    ChallengeKanji(
      japanese: '両',
      english: 'Both',
      memoryNotes: ["Borth mountains contained."],
    ),
    ChallengeKanji(
      japanese: '乗',
      english: 'Ride',
      memoryNotes: ["Riding a tree car with a 30 number plate."],
    ),
    ChallengeKanji(
      japanese: '済',
      english: 'Finish, relieve',
      memoryNotes: ["After adjusting the water flow the story comes to an end."],
    ),
    ChallengeKanji(
      japanese: '供',
      english: 'Offer, provide',
      memoryNotes: ["Two parents offer a gift"],
    ),
  ],
  // Day 40
  [
    ChallengeKanji(
      japanese: '格',
      english: 'Status',
      memoryNotes: ["Each tree placed in order shows rank and status."],
    ),
    ChallengeKanji(
      japanese: '打',
      english: 'Hit, strike',
      memoryNotes: ["Hitting in a street fight."],
    ),
    ChallengeKanji(
      japanese: '御',
      english: 'Honorific prefix',
      memoryNotes: ["The respectful truthful postman stops for lunch at noon"],
    ),
    ChallengeKanji(
      japanese: '断',
      english: 'Cut off, decide',
      memoryNotes: ["Cutting rice off a plant with an axe."],
    ),
    ChallengeKanji(
      japanese: '式',
      english: 'Style, ceremony',
      memoryNotes: ["Stylish clothes crafted for a ceremony."],
    ),
    ChallengeKanji(
      japanese: '師',
      english: 'Teacher, master',
      memoryNotes: ["The martial arts master with a B on his gi."],
    ),
    ChallengeKanji(
      japanese: '告',
      english: 'Announce, inform',
      memoryNotes: ["Words the soil through a mouth announce something."],
    ),
    ChallengeKanji(
      japanese: '深',
      english: 'Deep',
      memoryNotes: ["A tree deep in the well."],
    ),
    ChallengeKanji(
      japanese: '存',
      english: 'Exist, keep',
      memoryNotes: ["A gifted child meditates."],
    ),
    ChallengeKanji(
      japanese: '争',
      english: 'Dispute, argue',
      memoryNotes: ["Fighting with hands wrapped around brooms. Quidditch from Harry Potter."],
    ),
    ChallengeKanji(
      japanese: '覚',
      english: 'Remember',
      memoryNotes: ["A prince with a small crown looks at the text to memorise it."],
    ),
    ChallengeKanji(
      japanese: '側',
      english: 'Side',
      memoryNotes: ["A person stands by the shellfish with a sword."],
    ),
    ChallengeKanji(
      japanese: '飛',
      english: 'Fly',
      memoryNotes: ["Two strong hands break through ice and fly."],
    ),
    ChallengeKanji(
      japanese: '参',
      english: 'Participate, visit',
      memoryNotes: ["3 people participate in a big private competition."],
    ),
    ChallengeKanji(
      japanese: '突',
      english: 'Stab, thrust',
      memoryNotes: ["Dogs suddenly come bursting through a hole."],
    ),
  ],
  // Day 41
  [
    ChallengeKanji(
      japanese: '容',
      english: 'Contain',
      memoryNotes: ["A roof containing a valley."],
    ),
    ChallengeKanji(
      japanese: '育',
      english: 'Raise, grow',
      memoryNotes: ["Raising a moon in private"],
    ),
    ChallengeKanji(
      japanese: '構',
      english: 'Construct, set up',
      memoryNotes: ["Building 20 trees on top of each other again again to make a log house."],
    ),
    ChallengeKanji(
      japanese: '認',
      english: 'Recognize, acknowledge',
      memoryNotes: ["The knight says he acknowledges you with his sword across his heart."],
    ),
    ChallengeKanji(
      japanese: '位',
      english: 'Rank, position',
      memoryNotes: ["A person standing tall shows rank."],
    ),
    ChallengeKanji(
      japanese: '達',
      english: 'Reach, achieve',
      memoryNotes: ["A group of sheep arrive together on the soil."],
    ),
    ChallengeKanji(
      japanese: '守',
      english: 'Protect, guard',
      memoryNotes: ["Protecting the rulers in the building."],
    ),
    ChallengeKanji(
      japanese: '満',
      english: 'Full, satisfy',
      memoryNotes: ["Water filling on both sides until it becomes full."],
    ),
    ChallengeKanji(
      japanese: '消',
      english: 'Extinguish, erase',
      memoryNotes: ["Erasing things resembles putting out a fire with water."],
    ),
    ChallengeKanji(
      japanese: '任',
      english: 'Duty, responsibility',
      memoryNotes: ["A person is responsible for looking after the king."],
    ),
  ],
  // Day 42
  [
    ChallengeKanji(
      japanese: '居',
      english: 'Reside, live',
      memoryNotes: ["Staying by the old flag."],
    ),
    ChallengeKanji(
      japanese: '予',
      english: 'Beforehand',
      memoryNotes: ["Something wrapped and set in the city is prepared beforehand."],
    ),
    ChallengeKanji(
      japanese: '路',
      english: 'Road, path',
      memoryNotes: ["Each leg step makes a path."],
    ),
    ChallengeKanji(
      japanese: '座',
      english: 'Sit',
      memoryNotes: ["Under a slanted tent roof people sit on the soil."],
    ),
    ChallengeKanji(
      japanese: '客',
      english: 'Guest, customer',
      memoryNotes: ["Each person under the restaurant roof is a guest."],
    ),
    ChallengeKanji(
      japanese: '船',
      english: 'Ship, boat',
      memoryNotes: ["A crew of eight on a boat."],
    ),
    ChallengeKanji(
      japanese: '追',
      english: 'Chase, pursue',
      memoryNotes: ["Chasing someone in a Bee themed car."],
    ),
    ChallengeKanji(
      japanese: '背',
      english: 'Back, stature',
      memoryNotes: ["A north pole hoody with north pole written on the back."],
    ),
    ChallengeKanji(
      japanese: '観',
      english: 'View, observe',
      memoryNotes: ["A person watching a bird carefully forms an outlook on life."],
    ),
    ChallengeKanji(
      japanese: '誰',
      english: 'Who',
      memoryNotes: ["A bird that speaks asks who you are."],
    ),
  ],
  // Day 43 - rest day, no new cards
  [],
  // Day 44
  [
    ChallengeKanji(
      japanese: '息',
      english: 'Breath',
      memoryNotes: ["Breath brings awareness to oneself."],
    ),
    ChallengeKanji(
      japanese: '失',
      english: 'Lose',
      memoryNotes: ["A big object sinks into the soil."],
    ),
    ChallengeKanji(
      japanese: '老',
      english: 'Old, aged',
      memoryNotes: ["An old man with a spoon."],
    ),
    ChallengeKanji(
      japanese: '良',
      english: 'Good',
      memoryNotes: ["A good person wearing white clothes (e.g an angel)"],
    ),
    ChallengeKanji(
      japanese: '示',
      english: 'Show, indicate',
      memoryNotes: ["Showing my 2 small cats."],
    ),
    ChallengeKanji(
      japanese: '号',
      english: 'Number, title',
      memoryNotes: ["A mouth shouting the number five."],
    ),
    ChallengeKanji(
      japanese: '職',
      english: 'Occupation',
      memoryNotes: ["Getting a job as a security guard with an ear sword."],
    ),
    ChallengeKanji(
      japanese: '王',
      english: 'King',
      memoryNotes: ["Looks like a crown rotated on its side."],
    ),
    ChallengeKanji(
      japanese: '識',
      english: 'Knowledge, recognize',
      memoryNotes: ["Sword-like words are discriminating."],
    ),
    ChallengeKanji(
      japanese: '警',
      english: 'Warn, police',
      memoryNotes: ["Respectful words spoken firmly form a commandment."],
    ),
    ChallengeKanji(
      japanese: '優',
      english: 'Superior, gentle',
      memoryNotes: ["A person gently comforts a grieving person."],
    ),
    ChallengeKanji(
      japanese: '投',
      english: 'Throw',
      memoryNotes: ["Throwing a weapon with your hand."],
    ),
    ChallengeKanji(
      japanese: '局',
      english: 'Bureau, office',
      memoryNotes: ["A zombie works in a bureau."],
    ),
    ChallengeKanji(
      japanese: '難',
      english: 'Difficult',
      memoryNotes: ["The husband and his pet bird find it hard to eat grass."],
    ),
    ChallengeKanji(
      japanese: '種',
      english: 'Kind, type, seed',
      memoryNotes: ["Different species of tree have a different weight."],
    ),
  ],
  // Day 45
  [
    ChallengeKanji(
      japanese: '念',
      english: 'Thought, wish',
      memoryNotes: ["What's now in your heart becomes a thought or wish."],
    ),
    ChallengeKanji(
      japanese: '寄',
      english: 'Approach, gather',
      memoryNotes: ["Under a roof, something strange draws near."],
    ),
    ChallengeKanji(
      japanese: '商',
      english: 'Commerce',
      memoryNotes: ["Two pairs of legs trading with each other."],
    ),
    ChallengeKanji(
      japanese: '害',
      english: 'Harm',
      memoryNotes: ["Under a roof, a king shouts in pain."],
    ),
    ChallengeKanji(
      japanese: '頼',
      english: 'Rely, request',
      memoryNotes: ["Giving a bundle of shellfish to build trust. Requesting a bundle of shellfish as a favor."],
    ),
    ChallengeKanji(
      japanese: '横',
      english: 'Sideways, horizontal',
      memoryNotes: ["A yellow tree on its side."],
    ),
    ChallengeKanji(
      japanese: '増',
      english: 'Increase',
      memoryNotes: ["When the soil on the field gets sun, crops increase."],
    ),
    ChallengeKanji(
      japanese: '差',
      english: 'Difference',
      memoryNotes: ["A sheep crafts two different objects."],
    ),
    ChallengeKanji(
      japanese: '苦',
      english: 'Suffering, bitter',
      memoryNotes: ["Old grass is bitter and makes your stomach suffer."],
    ),
    ChallengeKanji(
      japanese: '収',
      english: 'Collect, gain',
      memoryNotes: ["Getting 4 gold coins with your right hand."],
    ),
    ChallengeKanji(
      japanese: '段',
      english: 'Step, rank',
      memoryNotes: ["Stepping up crooked steps with a weapon."],
    ),
    ChallengeKanji(
      japanese: '俺',
      english: 'I, myself (very masculine)',
      memoryNotes: ["You are a big masculine person in the field."],
    ),
    ChallengeKanji(
      japanese: '渡',
      english: 'Cross',
      memoryNotes: ["Crossing over by water."],
    ),
    ChallengeKanji(
      japanese: '与',
      english: 'Give, provide',
      memoryNotes: ["Giving out 5 pound notes."],
    ),
    ChallengeKanji(
      japanese: '演',
      english: 'Perform, act',
      memoryNotes: ["A tiger crying whilst acting"],
    ),
  ],
  // Day 46
  [
    ChallengeKanji(
      japanese: '備',
      english: 'Provide, prepare',
      memoryNotes: ["Two people equipping themselves with armor to use."],
    ),
    ChallengeKanji(
      japanese: '申',
      english: 'Say',
      memoryNotes: ["A person in a field says something."],
    ),
    ChallengeKanji(
      japanese: '例',
      english: 'Example',
      memoryNotes: ["A person dying by sword is used as an example to be careful."],
    ),
    ChallengeKanji(
      japanese: '働',
      english: 'Work',
      memoryNotes: ["A person who moves is working."],
    ),
    ChallengeKanji(
      japanese: '景',
      english: 'Scene, view',
      memoryNotes: ["The sun shining over the capital creates scenery."],
    ),
    ChallengeKanji(
      japanese: '抜',
      english: 'Pull out',
      memoryNotes: ["Pulling your friend out of a hole with your hand."],
    ),
    ChallengeKanji(
      japanese: '遠',
      english: 'Far',
      memoryNotes: ["There is a face mask on the soil far away."],
    ),
    ChallengeKanji(
      japanese: '絶',
      english: 'Discontinue',
      memoryNotes: ["A rainbow thread is cut off completely."],
    ),
    ChallengeKanji(
      japanese: '負',
      english: 'Lose, bear',
      memoryNotes: ["The shellfish slips out of your hands."],
    ),
    ChallengeKanji(
      japanese: '福',
      english: 'Blessing, fortune',
      memoryNotes: ["Blessings fill the container of life with good fortune."],
    ),
    ChallengeKanji(
      japanese: '球',
      english: 'Ball, sphere',
      memoryNotes: ["A king requests a ball."],
    ),
    ChallengeKanji(
      japanese: '酒',
      english: 'Alcohol, sake',
      memoryNotes: ["Water looking alcohol is sake."],
    ),
    ChallengeKanji(
      japanese: '君',
      english: 'You (informal)',
      memoryNotes: ["A person with a bent broom."],
    ),
    ChallengeKanji(
      japanese: '察',
      english: 'Guess, inspect',
      memoryNotes: ["Under a roof in the evening, before showing the answer I raise my right hand and try to answer."],
    ),
    ChallengeKanji(
      japanese: '望',
      english: 'Hope, desire',
      memoryNotes: ["The king wants the moon to die."],
    ),
  ],
  // Day 47
  [
    ChallengeKanji(
      japanese: '婚',
      english: 'Marriage',
      memoryNotes: ["A woman's day where she joins the family."],
    ),
    ChallengeKanji(
      japanese: '単',
      english: 'Simple',
      memoryNotes: ["A simple field in a cross shape."],
    ),
    ChallengeKanji(
      japanese: '押',
      english: 'Push, press',
      memoryNotes: ["A hand pushes a button in a field."],
    ),
    ChallengeKanji(
      japanese: '割',
      english: 'Divide, cut',
      memoryNotes: ["Dividing harm between people with a sword."],
    ),
    ChallengeKanji(
      japanese: '限',
      english: 'Limit',
      memoryNotes: ["The limit is the boundary on the hill."],
    ),
    ChallengeKanji(
      japanese: '戻',
      english: 'Return, go back',
      memoryNotes: ["Returning with a big door."],
    ),
    ChallengeKanji(
      japanese: '科',
      english: 'Subject, department',
      memoryNotes: ["A wooden door with a dipper on it marks a department."],
    ),
    ChallengeKanji(
      japanese: '求',
      english: 'Request, seek',
      memoryNotes: ["Requesting water."],
    ),
    ChallengeKanji(
      japanese: '談',
      english: 'Talk, discuss',
      memoryNotes: ["A heated discussion."],
    ),
    ChallengeKanji(
      japanese: '降',
      english: 'Descend, fall',
      memoryNotes: ["Going down the stairs on the hill."],
    ),
    ChallengeKanji(
      japanese: '妻',
      english: 'Wife',
      memoryNotes: ["A wife with a broom for a head."],
    ),
    ChallengeKanji(
      japanese: '岡',
      english: 'Hill, ridge',
      memoryNotes: ["A photo of a grassy mountain."],
    ),
    ChallengeKanji(
      japanese: '熱',
      english: 'Heat, fever, passion',
      memoryNotes: ["The art of fire is heat."],
    ),
    ChallengeKanji(
      japanese: '浮',
      english: 'Float',
      memoryNotes: ["A kitten swimming in water."],
    ),
    ChallengeKanji(
      japanese: '等',
      english: 'Equal',
      memoryNotes: ["Two equal length bamboo at a temple."],
    ),
  ],
  // Day 48
  [
    ChallengeKanji(
      japanese: '末',
      english: 'End, tip',
      memoryNotes: ["A tree cut by a samurai to end the battle."],
    ),
    ChallengeKanji(
      japanese: '幸',
      english: 'Happiness, fortune',
      memoryNotes: ["Happily lying on the dry soil."],
    ),
    ChallengeKanji(
      japanese: '草',
      english: 'Grass',
      memoryNotes: ["Grass pushes through the ground in the early morning."],
    ),
    ChallengeKanji(
      japanese: '越',
      english: 'Cross over, exceed',
      memoryNotes: ["Getting outrun by a man with an axe."],
    ),
    ChallengeKanji(
      japanese: '登',
      english: 'Climb, register',
      memoryNotes: ["Legs climbing up a beanstock."],
    ),
    ChallengeKanji(
      japanese: '類',
      english: 'Type, kind',
      memoryNotes: ["Two bags, one with loads of rice, and one with loads of shellfish."],
    ),
    ChallengeKanji(
      japanese: '未',
      english: 'Not yet',
      memoryNotes: ["A tree still rooted in the soil is not yet grown."],
    ),
    ChallengeKanji(
      japanese: '規',
      english: 'Rule, regulation',
      memoryNotes: ["A husband looks around to enforce his standards/rules."],
    ),
    ChallengeKanji(
      japanese: '精',
      english: 'Refined, spirit',
      memoryNotes: ["A blue rice ghost."],
    ),
    ChallengeKanji(
      japanese: '抱',
      english: 'Embrace, hold',
      memoryNotes: ["Wrapping your hand around yourself, giving yourself a hug."],
    ),
    ChallengeKanji(
      japanese: '労',
      english: 'Labor',
      memoryNotes: ["A small but heavy crown on your head is heavy labor."],
    ),
    ChallengeKanji(
      japanese: '処',
      english: 'Deal with, place',
      memoryNotes: ["Managing winter tasks at a desk. An office is a type of place,"],
    ),
    ChallengeKanji(
      japanese: '退',
      english: 'Retreat, withdraw',
      memoryNotes: ["Retreating to the boundary."],
    ),
    ChallengeKanji(
      japanese: '費',
      english: 'Expense, cost',
      memoryNotes: ["Spending money on shellfish is an expense."],
    ),
    ChallengeKanji(
      japanese: '非',
      english: 'Wrong, non-',
      memoryNotes: ["Reflect on a big mistake you made and imagine this kanji appearing like in a manga."],
    ),
  ],
  // Day 49
  [
    ChallengeKanji(
      japanese: '喜',
      english: 'Joy, delight',
      memoryNotes: ["A samurai rejoices whilst eating beans."],
    ),
    ChallengeKanji(
      japanese: '娘',
      english: 'Daughter, girl',
      memoryNotes: ["A woman's daughter is good/well behaved."],
    ),
    ChallengeKanji(
      japanese: '逃',
      english: 'Escape, flee',
      memoryNotes: ["Running away at a trillion miles an hour."],
    ),
    ChallengeKanji(
      japanese: '探',
      english: 'Search',
      memoryNotes: ["A hand reaches into a crown, past legs and trees, to search for something."],
    ),
    ChallengeKanji(
      japanese: '犯',
      english: 'Crime, commit',
      memoryNotes: ["A beast gets sealed for committing a crime."],
    ),
    ChallengeKanji(
      japanese: '薬',
      english: 'Medicine',
      memoryNotes: ["A special type of grass/herb that allows you to enjoy life again."],
    ),
    ChallengeKanji(
      japanese: '園',
      english: 'Garden',
      memoryNotes: ["A boundary of soil where people laugh and wear nice clothes (a park)."],
    ),
    ChallengeKanji(
      japanese: '疑',
      english: 'Doubt, suspect',
      memoryNotes: ["A detective looking at how the spoon and the arrow relate to the truth causing doubt."],
    ),
    ChallengeKanji(
      japanese: '緒',
      english: 'Cord, beginning',
      memoryNotes: ["Someone following a thread marks the beginning."],
    ),
    ChallengeKanji(
      japanese: '静',
      english: 'Quiet',
      memoryNotes: ["The blue librarian will throw hands with anyone who isn't quiet."],
    ),
    ChallengeKanji(
      japanese: '具',
      english: 'Tool, ingredient',
      memoryNotes: ["A tool to separate a lobster's claws."],
    ),
    ChallengeKanji(
      japanese: '席',
      english: 'Seat',
      memoryNotes: ["A slanted structure with two arms and cloth form a seat."],
    ),
    ChallengeKanji(
      japanese: '速',
      english: 'Fast',
      memoryNotes: ["A bundle of balls rolling at high speed."],
    ),
    ChallengeKanji(
      japanese: '舞',
      english: 'Dance',
      memoryNotes: ["30 people dancing."],
    ),
    ChallengeKanji(
      japanese: '宿',
      english: 'Inn, lodge',
      memoryNotes: ["Under a roof, 100 people stay at the inn."],
    ),
  ],
  // Day 50 - rest day, no new cards
  [],
  // Day 51
  [
    ChallengeKanji(
      japanese: '程',
      english: 'Extent, degree',
      memoryNotes: ["A tree cut to the extent of the king's liking."],
    ),
    ChallengeKanji(
      japanese: '倒',
      english: 'Fall, collapse',
      memoryNotes: ["A person struck by a sword upon arrival falls over."],
    ),
    ChallengeKanji(
      japanese: '寝',
      english: 'Sleep',
      memoryNotes: ["Under a roof, a man passes out cold from sweeping too much."],
    ),
    ChallengeKanji(
      japanese: '宅',
      english: 'Home, residence',
      memoryNotes: ["A roof with seven rooms forms a home."],
    ),
    ChallengeKanji(
      japanese: '絵',
      english: 'Picture, drawing',
      memoryNotes: ["Threads meet to form a picture."],
    ),
    ChallengeKanji(
      japanese: '破',
      english: 'Break, tear',
      memoryNotes: ["Stone tearing through skin."],
    ),
    ChallengeKanji(
      japanese: '庭',
      english: 'Garden, courtyard',
      memoryNotes: ["Under a slanted roof, the king strides through a garden."],
    ),
    ChallengeKanji(
      japanese: '婦',
      english: 'Woman, wife',
      memoryNotes: ["A very posh lady orders a broom around."],
    ),
    ChallengeKanji(
      japanese: '余',
      english: 'Remaining, surplus',
      memoryNotes: ["A person has too many trees."],
    ),
    ChallengeKanji(
      japanese: '訪',
      english: 'Visit',
      memoryNotes: ["You say which direction you're going to visit someone. How to speak when you visit someone."],
    ),
    ChallengeKanji(
      japanese: '冷',
      english: 'Cold',
      memoryNotes: ["Ice following nature's command feels cold."],
    ),
    ChallengeKanji(
      japanese: '暮',
      english: 'Live, sunset',
      memoryNotes: ["Life is the simple things like grass and sun."],
    ),
    ChallengeKanji(
      japanese: '腹',
      english: 'Belly, stomach',
      memoryNotes: ["A body part which is like the sun of the body."],
    ),
    ChallengeKanji(
      japanese: '危',
      english: 'Dangerous',
      memoryNotes: ["A seal wrapped around a cliff, indicating danger."],
    ),
    ChallengeKanji(
      japanese: '許',
      english: 'Permit, allow',
      memoryNotes: ["A mother gives a child permission to play until noon."],
    ),
  ],
  // Day 52
  [
    ChallengeKanji(
      japanese: '似',
      english: 'Resemble',
      memoryNotes: ["One person compared to another resembles them."],
    ),
    ChallengeKanji(
      japanese: '険',
      english: 'Dangerous, steep',
      memoryNotes: ["Two identical twins climb up a steep hill"],
    ),
    ChallengeKanji(
      japanese: '財',
      english: 'Wealth, property',
      memoryNotes: ["A wealthy talented shellfish. Money and talent equal wealth."],
    ),
    ChallengeKanji(
      japanese: '遊',
      english: 'Play, wander',
      memoryNotes: ["A child goes to play/hangs out, they know the method well"],
    ),
    ChallengeKanji(
      japanese: '雑',
      english: 'Miscellaneous',
      memoryNotes: ["A miscellaneous pile with 9 trees and a bird in a cage."],
    ),
    ChallengeKanji(
      japanese: '恐',
      english: 'Fear',
      memoryNotes: ["A work desk placed on the heart is causing fear."],
    ),
    ChallengeKanji(
      japanese: '値',
      english: 'Value, price',
      memoryNotes: ["A person sees the value in an object straightaway."],
    ),
    ChallengeKanji(
      japanese: '暗',
      english: 'Dark',
      memoryNotes: ["The sun says goodnight and then everything goes dark."],
    ),
    ChallengeKanji(
      japanese: '積',
      english: 'Accumulate',
      memoryNotes: ["The trees are to blame for the pile of twigs."],
    ),
    ChallengeKanji(
      japanese: '夢',
      english: 'Dream',
      memoryNotes: ["A dream about the moon with vines (grass net) growing on it"],
    ),
    ChallengeKanji(
      japanese: '痛',
      english: 'Pain',
      memoryNotes: ["Getting ill from walking down a narrow path."],
    ),
    ChallengeKanji(
      japanese: '富',
      english: 'Wealth',
      memoryNotes: ["A filled to the brim of gold shows wealth."],
    ),
    ChallengeKanji(
      japanese: '刻',
      english: 'Carve, engrave',
      memoryNotes: ["A sword carving of a hog, measures time. (a hog themed clock)"],
    ),
    ChallengeKanji(
      japanese: '鳴',
      english: 'Cry, chirp, sound',
      memoryNotes: ["A bird speaking through a mouth makes a sound."],
    ),
    ChallengeKanji(
      japanese: '欲',
      english: 'Desire, want',
      memoryNotes: ["I lack a valley and I really want one."],
    ),
  ],
  // Day 53
  [
    ChallengeKanji(
      japanese: '途',
      english: 'Route, way',
      memoryNotes: ["A route is a place people go a lot/too much."],
    ),
    ChallengeKanji(
      japanese: '曲',
      english: 'Bend, music',
      memoryNotes: ["A stereo."],
    ),
    ChallengeKanji(
      japanese: '耳',
      english: 'Ear',
      memoryNotes: ["Ladders on your ear."],
    ),
    ChallengeKanji(
      japanese: '完',
      english: 'Complete',
      memoryNotes: ["A roof completed from beginning to end."],
    ),
    ChallengeKanji(
      japanese: '願',
      english: 'Wish, request',
      memoryNotes: ["The ancient original shellfish wizard that grants wishes."],
    ),
    ChallengeKanji(
      japanese: '罪',
      english: 'Crime, guilt',
      memoryNotes: ["Being caught in a net of what's wrong is guilt."],
    ),
    ChallengeKanji(
      japanese: '陽',
      english: 'Sunshine, positive',
      memoryNotes: ["Sun rising over a hill giving off positive sunshine."],
    ),
    ChallengeKanji(
      japanese: '亡',
      english: 'Death, disappear',
      memoryNotes: ["Looks like a coffin"],
    ),
    ChallengeKanji(
      japanese: '散',
      english: 'Scatter',
      memoryNotes: ["Striking a moon together causing it to scatter."],
    ),
    ChallengeKanji(
      japanese: '掛',
      english: 'Hang, suspend',
      memoryNotes: ["Hanging onto the soil with a hand and a stick."],
    ),
    ChallengeKanji(
      japanese: '昨',
      english: 'Yesterday',
      memoryNotes: ["The day we created was yesterday."],
    ),
    ChallengeKanji(
      japanese: '怒',
      english: 'Anger',
      memoryNotes: ["A woman shakes her right hand in anger."],
    ),
    ChallengeKanji(
      japanese: '留',
      english: 'Stay, detain',
      memoryNotes: ["Prisoners pumping iron and training with swords."],
    ),
    ChallengeKanji(
      japanese: '礼',
      english: 'Thanks, etiquette',
      memoryNotes: ["A ceremony worshipping the letter L."],
    ),
    ChallengeKanji(
      japanese: '列',
      english: 'Row, line',
      memoryNotes: ["A sword and its row of victims."],
    ),
  ],
  // Day 54
  [
    ChallengeKanji(
      japanese: '雪',
      english: 'Snow',
      memoryNotes: ["Rain that needs a broom to clear is snow."],
    ),
    ChallengeKanji(
      japanese: '払',
      english: 'Pay, clear away',
      memoryNotes: ["A hand reaching into a personal bank account to pay."],
    ),
    ChallengeKanji(
      japanese: '給',
      english: 'Provide, salary',
      memoryNotes: ["Your matching threads in exchange for your work"],
    ),
    ChallengeKanji(
      japanese: '敗',
      english: 'Lose, be defeated',
      memoryNotes: ["A shellfish struck down means defeat."],
    ),
    ChallengeKanji(
      japanese: '捕',
      english: 'Catch, capture',
      memoryNotes: ["A hand capturing something for the first time"],
    ),
    ChallengeKanji(
      japanese: '忘',
      english: 'Forget',
      memoryNotes: ["Forgetting = death of the heart/mind"],
    ),
    ChallengeKanji(
      japanese: '晴',
      english: 'Clear up',
      memoryNotes: ["A blue sunlit clear day"],
    ),
    ChallengeKanji(
      japanese: '因',
      english: 'Cause',
      memoryNotes: ["The big thing in the box is the cause."],
    ),
    ChallengeKanji(
      japanese: '折',
      english: 'Break, fold',
      memoryNotes: ["Folding and breaking an axe with your hand."],
    ),
    ChallengeKanji(
      japanese: '迎',
      english: 'Welcome',
      memoryNotes: ["Going to open the seal to welcome someone."],
    ),
    ChallengeKanji(
      japanese: '悲',
      english: 'Sad',
      memoryNotes: ["A not heart = sorrow."],
    ),
    ChallengeKanji(
      japanese: '港',
      english: 'Harbor',
      memoryNotes: ["You build a harbor together with your friends by the water."],
    ),
    ChallengeKanji(
      japanese: '責',
      english: 'Blame, responsibility',
      memoryNotes: ["The shellfish king is to blame."],
    ),
    ChallengeKanji(
      japanese: '除',
      english: 'Remove, exclude',
      memoryNotes: ["If you go too high up the hill you'll be removed from reality."],
    ),
    ChallengeKanji(
      japanese: '困',
      english: 'Trouble, difficulty',
      memoryNotes: ["A tree trapped in a box is in trouble since it can't grow."],
    ),
  ],
  // Day 55
  [
    ChallengeKanji(
      japanese: '閉',
      english: 'Close',
      memoryNotes: ["A gate that requires a genius to shut."],
    ),
    ChallengeKanji(
      japanese: '吸',
      english: 'Inhale, suck',
      memoryNotes: ["A mouth reaching inward inhales."],
    ),
    ChallengeKanji(
      japanese: '髪',
      english: 'Hair',
      memoryNotes: ["Hair is your long fur friend."],
    ),
    ChallengeKanji(
      japanese: '束',
      english: 'Bundle, tie',
      memoryNotes: ["Trees tied in a loop to form a bundle."],
    ),
    ChallengeKanji(
      japanese: '眠',
      english: 'Sleep',
      memoryNotes: ["Everyone shuts their eyes to sleep."],
    ),
    ChallengeKanji(
      japanese: '易',
      english: 'Easy',
      memoryNotes: ["The hint 'not a sun' for a question makes it easy."],
    ),
    ChallengeKanji(
      japanese: '窓',
      english: 'Window',
      memoryNotes: ["A window is a hole into the private heart of people's lives."],
    ),
    ChallengeKanji(
      japanese: '祖',
      english: 'Ancestor',
      memoryNotes: ["An eye watching over the festival is an ancestor."],
    ),
    ChallengeKanji(
      japanese: '勤',
      english: 'Diligence, service',
      memoryNotes: ["A king powers through eating grass showing diligence."],
    ),
    ChallengeKanji(
      japanese: '昔',
      english: 'Long ago',
      memoryNotes: ["Reading an old fairy tale together with the sun"],
    ),
    ChallengeKanji(
      japanese: '便',
      english: 'Convenience, mail',
      memoryNotes: ["A person carrying more makes things convenient."],
    ),
    ChallengeKanji(
      japanese: '適',
      english: 'Suitable',
      memoryNotes: ["The old person standing goes because he's the most suitable and experienced for the job."],
    ),
    ChallengeKanji(
      japanese: '吹',
      english: 'Blow',
      memoryNotes: ["A mouth lacking air = blow."],
    ),
    ChallengeKanji(
      japanese: '候',
      english: 'Season, climate, wait',
      memoryNotes: ["A person watching the weather come down with arrows."],
    ),
    ChallengeKanji(
      japanese: '怖',
      english: 'Scary, fear',
      memoryNotes: ["The heart trembles with fear because of a scary outfit."],
    ),
  ],
  // Day 56
  [
    ChallengeKanji(
      japanese: '辞',
      english: 'Resign, word',
      memoryNotes: ["A man with a spicy tongue resigns in anger."],
    ),
    ChallengeKanji(
      japanese: '否',
      english: 'Negate, no',
      memoryNotes: ["Not mouth = negate."],
    ),
    ChallengeKanji(
      japanese: '遅',
      english: 'Late, slow',
      memoryNotes: ["A slow zombie riding a sheep is late."],
    ),
    ChallengeKanji(
      japanese: '煙',
      english: 'Smoke',
      memoryNotes: ["Fire on the soil with smoke blowing west"],
    ),
    ChallengeKanji(
      japanese: '徒',
      english: 'On foot, follower',
      memoryNotes: ["Stepping and running are actions taken on foot."],
    ),
    ChallengeKanji(
      japanese: '欠',
      english: 'Lack, missing',
      memoryNotes: ["A person wrapping their hands around nothing as they lack something."],
    ),
    ChallengeKanji(
      japanese: '迷',
      english: 'Get lost, puzzled',
      memoryNotes: ["A man gets lost in a rice field."],
    ),
    ChallengeKanji(
      japanese: '洗',
      english: 'Wash',
      memoryNotes: ["Washing things before use with water."],
    ),
    ChallengeKanji(
      japanese: '互',
      english: 'Mutual',
      memoryNotes: ["Similar looking shapes mirroring each other = mutual."],
    ),
    ChallengeKanji(
      japanese: '才',
      english: 'Talent, age (counter)',
      memoryNotes: ["Everyone says 'ooo' in amazement of the talented person."],
    ),
    ChallengeKanji(
      japanese: '更',
      english: 'Renew, again, more and more',
      memoryNotes: ["The sun is changing more and more (crossing out the old one)."],
    ),
    ChallengeKanji(
      japanese: '歯',
      english: 'Tooth',
      memoryNotes: ["Rice getting stuck/stopped in your teeth."],
    ),
    ChallengeKanji(
      japanese: '盗',
      english: 'Steal',
      memoryNotes: ["Next the burglar decides to steal a golden plate."],
    ),
    ChallengeKanji(
      japanese: '慣',
      english: 'Accustomed',
      memoryNotes: ["A heart pierced repeatedly grows accustomed."],
    ),
    ChallengeKanji(
      japanese: '晩',
      english: 'Evening',
      memoryNotes: ["The sun excused from the sky marks evening."],
    ),
  ],
  // Day 57 - rest day, no new cards
  [],
  // Day 58
  [
    ChallengeKanji(
      japanese: '箱',
      english: 'Box',
      memoryNotes: ["Bamboo box with an eye and a tree in it"],
    ),
    ChallengeKanji(
      japanese: '到',
      english: 'Arrive',
      memoryNotes: ["Arriving with a sword in hand"],
    ),
    ChallengeKanji(
      japanese: '頂',
      english: 'Top, receive humbly',
      memoryNotes: ["A shellfish with a hook climbs to the summit."],
    ),
    ChallengeKanji(
      japanese: '杯',
      english: 'Cup',
      memoryNotes: ["A wooden cup = not a tree anymore."],
    ),
    ChallengeKanji(
      japanese: '皆',
      english: 'Everyone',
      memoryNotes: ["Comparing two white objects."],
    ),
    ChallengeKanji(
      japanese: '招',
      english: 'Invite, beckon',
      memoryNotes: ["Handing out flyers to invite people to a sword swallowing show."],
    ),
    ChallengeKanji(
      japanese: '寒',
      english: 'Cold',
      memoryNotes: ["Together under the roof with ice feeling cold."],
    ),
    ChallengeKanji(
      japanese: '恥',
      english: 'Shame',
      memoryNotes: ["Feeling shame when you listen to your heart."],
    ),
    ChallengeKanji(
      japanese: '疲',
      english: 'Tired',
      memoryNotes: ["Tiredness is like sickness of the skin."],
    ),
    ChallengeKanji(
      japanese: '貧',
      english: 'Poor, poverty',
      memoryNotes: ["Only having part of the money you need is poverty."],
    ),
  ],
  // Day 59
  [
    ChallengeKanji(
      japanese: '猫',
      english: 'Cat',
      memoryNotes: ["A beast hiding in grass and fields is a cat."],
    ),
    ChallengeKanji(
      japanese: '誤',
      english: 'Mistake',
      memoryNotes: ["Saying that 5 is drawn wrong, it's a mistake."],
    ),
    ChallengeKanji(
      japanese: '努',
      english: 'Endeavor, strive',
      memoryNotes: ["A woman repeatedly strengthening her right hand is her toil."],
    ),
    ChallengeKanji(
      japanese: '幾',
      english: 'How many, several',
      memoryNotes: ["A person with a spear counts how many threads there are."],
    ),
    ChallengeKanji(
      japanese: '賛',
      english: 'Approve, praise',
      memoryNotes: ["Two husbands praise each other's wealth/money."],
    ),
    ChallengeKanji(
      japanese: '偶',
      english: 'Accident, by chance',
      memoryNotes: ["A person accidently meets a long tailed monkey"],
    ),
    ChallengeKanji(
      japanese: '忙',
      english: 'Busy',
      memoryNotes: ["Heart feeling like death = busy."],
    ),
    ChallengeKanji(
      japanese: '泳',
      english: 'Swim',
      memoryNotes: ["Swimming through water for eternity."],
    ),
    ChallengeKanji(
      japanese: '靴',
      english: 'Shoes',
      memoryNotes: ["Shoes = leather you change into."],
    ),
    ChallengeKanji(
      japanese: '偉',
      english: 'Great, admirable',
      memoryNotes: ["A great person dressed in tanned leather. (Think of someone great in your life)"],
    ),
  ],
  // Day 60
  [
    ChallengeKanji(
      japanese: '軍',
      english: 'Army, military',
      memoryNotes: ["Vehicles in service of the crown = army."],
    ),
    ChallengeKanji(
      japanese: '兵',
      english: 'Soldier, arms',
      memoryNotes: ["Looks like a soldier wearing a hat. A soldier holding an axe."],
    ),
    ChallengeKanji(
      japanese: '島',
      english: 'Island',
      memoryNotes: ["A big bird on an island."],
    ),
    ChallengeKanji(
      japanese: '村',
      english: 'Village',
      memoryNotes: ["An area of trees is a village."],
    ),
    ChallengeKanji(
      japanese: '門',
      english: 'Gate',
      memoryNotes: ["Looks like a saloon gate or a tori gate."],
    ),
    ChallengeKanji(
      japanese: '戸',
      english: 'Door',
      memoryNotes: ["A door with a flag on it."],
    ),
    ChallengeKanji(
      japanese: '武',
      english: 'Warrior, military',
      memoryNotes: ["A warrior stops the ceremony."],
    ),
    ChallengeKanji(
      japanese: '城',
      english: 'Castle',
      memoryNotes: ["Turning a piece of soil into a grand castle."],
    ),
    ChallengeKanji(
      japanese: '総',
      english: 'Total, whole',
      memoryNotes: ["Thread through the hearts of the general public"],
    ),
    ChallengeKanji(
      japanese: '団',
      english: 'Group, organization',
      memoryNotes: ["A group of measuring tools in boxes."],
    ),
    ChallengeKanji(
      japanese: '線',
      english: 'Line',
      memoryNotes: ["Painting a line with white paint."],
    ),
    ChallengeKanji(
      japanese: '設',
      english: 'Establish, set up',
      memoryNotes: ["Using words as a weapon to establish order."],
    ),
    ChallengeKanji(
      japanese: '勢',
      english: 'Force, energy',
      memoryNotes: ["The art of power = force."],
    ),
    ChallengeKanji(
      japanese: '党',
      english: 'Party (political), faction',
      memoryNotes: ["Under a small roof, brothers unite as a party."],
    ),
    ChallengeKanji(
      japanese: '史',
      english: 'History',
      memoryNotes: ["Talking about clashing swords = history."],
    ),
  ],
  // Day 61
  [
    ChallengeKanji(
      japanese: '営',
      english: 'Manage, operate',
      memoryNotes: ["A camp to help the prince build a backbone."],
    ),
    ChallengeKanji(
      japanese: '府',
      english: 'Government office',
      memoryNotes: ["A slanted roof building attached to the government."],
    ),
    ChallengeKanji(
      japanese: '巻',
      english: 'Scroll, volume',
      memoryNotes: ["A scroll about fire, S for Scroll."],
    ),
    ChallengeKanji(
      japanese: '介',
      english: 'Mediate',
      memoryNotes: ["A person stepping on stilts mediates."],
    ),
    ChallengeKanji(
      japanese: '蔵',
      english: 'Store, hide',
      memoryNotes: ["A retainers store house with grass and a spear/halberd"],
    ),
    ChallengeKanji(
      japanese: '造',
      english: 'Make, build',
      memoryNotes: ["Reporting progress as we go through the process of building something."],
    ),
    ChallengeKanji(
      japanese: '根',
      english: 'Root',
      memoryNotes: ["A tree's root is it's boundary"],
    ),
    ChallengeKanji(
      japanese: '寺',
      english: 'Temple',
      memoryNotes: ["A temple made of rulers on the soil"],
    ),
    ChallengeKanji(
      japanese: '査',
      english: 'Investigate',
      memoryNotes: ["An eye examining a tree to investigate."],
    ),
    ChallengeKanji(
      japanese: '将',
      english: 'Leader, general',
      memoryNotes: ["Cool judgment and careful measure make a commander."],
    ),
    ChallengeKanji(
      japanese: '改',
      english: 'Reform, change',
      memoryNotes: ["Striking the self leads to reforming the self."],
    ),
    ChallengeKanji(
      japanese: '県',
      english: 'Prefecture',
      memoryNotes: ["An eye looking at a small map of the prefectures of japan, looks like an L."],
    ),
    ChallengeKanji(
      japanese: '泉',
      english: 'Spring, fountain',
      memoryNotes: ["A spring of milk."],
    ),
    ChallengeKanji(
      japanese: '像',
      english: 'Image, statue',
      memoryNotes: ["A person imagines an image of an elephant."],
    ),
    ChallengeKanji(
      japanese: '細',
      english: 'Thin, detailed',
      memoryNotes: ["Thin threads stretched across a field"],
    ),
  ],
  // Day 62
  [
    ChallengeKanji(
      japanese: '谷',
      english: 'Valley',
      memoryNotes: ["Two matching sides separated out form a valley."],
    ),
    ChallengeKanji(
      japanese: '奥',
      english: 'Interior, inner part',
      memoryNotes: ["A big interior filled with rice bags."],
    ),
    ChallengeKanji(
      japanese: '再',
      english: 'Again',
      memoryNotes: ["Using something again or twice."],
    ),
    ChallengeKanji(
      japanese: '血',
      english: 'Blood',
      memoryNotes: ["A plate marked with blood."],
    ),
    ChallengeKanji(
      japanese: '算',
      english: 'Calculate',
      memoryNotes: ["Calculating something with bamboo in the hot sun."],
    ),
    ChallengeKanji(
      japanese: '象',
      english: 'Elephant, phenomenon',
      memoryNotes: ["A pig with a trunk."],
    ),
    ChallengeKanji(
      japanese: '清',
      english: 'Clear, pure',
      memoryNotes: ["blue water = pure."],
    ),
    ChallengeKanji(
      japanese: '技',
      english: 'Skill',
      memoryNotes: ["A branch cutting skill."],
    ),
    ChallengeKanji(
      japanese: '州',
      english: 'State, province',
      memoryNotes: ["A river defining each state of the country."],
    ),
    ChallengeKanji(
      japanese: '領',
      english: 'Territory, lead',
      memoryNotes: ["A big shellfish rules and commands the territory."],
    ),
    ChallengeKanji(
      japanese: '橋',
      english: 'Bridge',
      memoryNotes: ["A tall tree turned into a bridge."],
    ),
    ChallengeKanji(
      japanese: '芸',
      english: 'Art, performance',
      memoryNotes: ["A painting of grass saying something."],
    ),
    ChallengeKanji(
      japanese: '型',
      english: 'Type, model',
      memoryNotes: ["Punishing the soil to form a model."],
    ),
    ChallengeKanji(
      japanese: '香',
      english: 'Fragrance',
      memoryNotes: ["The sun shines on the tree, and the tree gives off a fragrance."],
    ),
    ChallengeKanji(
      japanese: '量',
      english: 'Quantity',
      memoryNotes: ["The sun rises over a large quantity of villages."],
    ),
  ],
  // Day 63
  [
    ChallengeKanji(
      japanese: '久',
      english: 'Long time',
      memoryNotes: ["A person enduring for a long time."],
    ),
    ChallengeKanji(
      japanese: '境',
      english: 'Border, boundary',
      memoryNotes: ["Soil and moving sound defines the boundary."],
    ),
    ChallengeKanji(
      japanese: '階',
      english: 'Floor, rank',
      memoryNotes: ["Climbing all the stairs to reach the top of the hill."],
    ),
    ChallengeKanji(
      japanese: '区',
      english: 'District, ward',
      memoryNotes: ["Welcome to the pirate district."],
    ),
    ChallengeKanji(
      japanese: '波',
      english: 'Wave',
      memoryNotes: ["The skin of the sea is like the waves."],
    ),
    ChallengeKanji(
      japanese: '移',
      english: 'Move, shift',
      memoryNotes: ["Many trees moving."],
    ),
    ChallengeKanji(
      japanese: '域',
      english: 'Region, area',
      memoryNotes: ["Some soil defines a region."],
    ),
    ChallengeKanji(
      japanese: '周',
      english: 'Circumference, around',
      memoryNotes: ["The circumference of a donut made of soil."],
    ),
    ChallengeKanji(
      japanese: '接',
      english: 'Connect, contact',
      memoryNotes: ["High fiving a woman standing up"],
    ),
    ChallengeKanji(
      japanese: '鉄',
      english: 'Iron',
      memoryNotes: ["When I lose my gold I use my iron instead."],
    ),
    ChallengeKanji(
      japanese: '頃',
      english: 'Time, about',
      memoryNotes: ["Remembering a time where I ate shellfish with a spoon."],
    ),
    ChallengeKanji(
      japanese: '材',
      english: 'Material',
      memoryNotes: ["A talented/good quality tree is used as a material."],
    ),
    ChallengeKanji(
      japanese: '個',
      english: 'Individual',
      memoryNotes: ["A hardened person is an independent individual."],
    ),
    ChallengeKanji(
      japanese: '協',
      english: 'Cooperate',
      memoryNotes: ["3 powerful beings cross together to cooperate."],
    ),
    ChallengeKanji(
      japanese: '各',
      english: 'Each',
      memoryNotes: ["Each mouth speaks about the dreadful winter."],
    ),
  ],
  // Day 64 - rest day, no new cards
  [],
  // Day 65
  [
    ChallengeKanji(
      japanese: '帯',
      english: 'Belt',
      memoryNotes: ["A belt with the number 30 stitched on it."],
    ),
    ChallengeKanji(
      japanese: '歴',
      english: 'History',
      memoryNotes: ["Because of the history of this cliff it's best to stop at the forest."],
    ),
    ChallengeKanji(
      japanese: '編',
      english: 'Compile, knit',
      memoryNotes: ["Editing a ghost video where you open a bookshelf door with a thread."],
    ),
    ChallengeKanji(
      japanese: '裏',
      english: 'Back, reverse side',
      memoryNotes: ["Carrying a basket with the villages clothing on my back."],
    ),
    ChallengeKanji(
      japanese: '比',
      english: 'Compare',
      memoryNotes: ["Two spoons held side by side are compared."],
    ),
    ChallengeKanji(
      japanese: '坂',
      english: 'Slope, hill',
      memoryNotes: ["Soil that goes against you becomes a slope."],
    ),
    ChallengeKanji(
      japanese: '装',
      english: 'Dress, equip',
      memoryNotes: ["A samurai's winter attire."],
    ),
    ChallengeKanji(
      japanese: '省',
      english: 'Omit, ministry',
      memoryNotes: ["Leaving a few things out/conserving something = fewer eyes see it."],
    ),
    ChallengeKanji(
      japanese: '税',
      english: 'Tax',
      memoryNotes: ["A frustrated older brother calculates the tax for grain."],
    ),
    ChallengeKanji(
      japanese: '競',
      english: 'Compete',
      memoryNotes: ["Two older brothers standing tall compete with each other."],
    ),
    ChallengeKanji(
      japanese: '囲',
      english: 'Surround',
      memoryNotes: ["A hashtag enclosed in a box."],
    ),
    ChallengeKanji(
      japanese: '辺',
      english: 'Edge, area',
      memoryNotes: ["A guard with a sword patrols the area."],
    ),
    ChallengeKanji(
      japanese: '河',
      english: 'River',
      memoryNotes: ["A river forms where it's possible for water to flow."],
    ),
    ChallengeKanji(
      japanese: '極',
      english: 'Extreme, pole',
      memoryNotes: ["Holding 5 wooden poles with your right hand."],
    ),
    ChallengeKanji(
      japanese: '防',
      english: 'Prevent, defend',
      memoryNotes: ["How to use a hill to defend yourself."],
    ),
  ],
  // Day 66
  [
    ChallengeKanji(
      japanese: '低',
      english: 'Low',
      memoryNotes: ["The lowest member of the family."],
    ),
    ChallengeKanji(
      japanese: '林',
      english: 'Woods, forest',
      memoryNotes: ["Two trees = small forest/grove"],
    ),
    ChallengeKanji(
      japanese: '導',
      english: 'Guide, lead',
      memoryNotes: ["Measurements on the road guide drivers."],
    ),
    ChallengeKanji(
      japanese: '森',
      english: 'Forest',
      memoryNotes: ["Three trees = loads of trees/forest"],
    ),
    ChallengeKanji(
      japanese: '丸',
      english: 'Circle, round',
      memoryNotes: ["A round number 9"],
    ),
    ChallengeKanji(
      japanese: '胸',
      english: 'Chest',
      memoryNotes: ["When your in turmoil you grab your chest."],
    ),
    ChallengeKanji(
      japanese: '陸',
      english: 'Land',
      memoryNotes: ["Hills, creatures, and soil make up the land."],
    ),
    ChallengeKanji(
      japanese: '療',
      english: 'Heal, cure',
      memoryNotes: ["A big fire tackling the illness to cause healing."],
    ),
    ChallengeKanji(
      japanese: '諸',
      english: 'Various',
      memoryNotes: ["Speaking about various types of people."],
    ),
    ChallengeKanji(
      japanese: '管',
      english: 'Pipe, control',
      memoryNotes: ["Bamboo pipes in a B shape."],
    ),
    ChallengeKanji(
      japanese: '仲',
      english: 'Relationship, go-between',
      memoryNotes: ["A person standing in the center builds relationships."],
    ),
    ChallengeKanji(
      japanese: '革',
      english: 'Leather, reform',
      memoryNotes: ["Using two hands to create a hole in the thick leather."],
    ),
    ChallengeKanji(
      japanese: '担',
      english: 'Carry, bear',
      memoryNotes: ["A hand lifting the sun."],
    ),
    ChallengeKanji(
      japanese: '効',
      english: 'Effect, efficacy',
      memoryNotes: ["Mingling is a power to create an effect on your life."],
    ),
    ChallengeKanji(
      japanese: '賞',
      english: 'Prize, award',
      memoryNotes: ["Under a small roof, money given to workers becomes a prize."],
    ),
  ],
  // Day 67
  [
    ChallengeKanji(
      japanese: '星',
      english: 'Star',
      memoryNotes: ["When the sun was born it became a new star."],
    ),
    ChallengeKanji(
      japanese: '復',
      english: 'Return, restore',
      memoryNotes: ["A person steps out to the sun then returns again."],
    ),
    ChallengeKanji(
      japanese: '片',
      english: 'Fragment, one-sided',
      memoryNotes: ["F for fragment."],
    ),
    ChallengeKanji(
      japanese: '並',
      english: 'Line up, ordinary',
      memoryNotes: ["2 or more people standing forms a row."],
    ),
    ChallengeKanji(
      japanese: '底',
      english: 'Bottom',
      memoryNotes: ["A family live in a house at the bottom of a great canyon."],
    ),
    ChallengeKanji(
      japanese: '温',
      english: 'Warm',
      memoryNotes: ["Sun warming water in a dish."],
    ),
    ChallengeKanji(
      japanese: '軽',
      english: 'Light (weight)',
      memoryNotes: ["A car is as light as soil."],
    ),
    ChallengeKanji(
      japanese: '録',
      english: 'Record',
      memoryNotes: ["Gold washed clean by water and broom records events."],
    ),
    ChallengeKanji(
      japanese: '腰',
      english: 'Waist',
      memoryNotes: ["The hips are needed to carry the weight of the upper body."],
    ),
    ChallengeKanji(
      japanese: '著',
      english: 'Author, write',
      memoryNotes: ["A renowned author writes a story about grass."],
    ),
    ChallengeKanji(
      japanese: '乱',
      english: 'Disorder',
      memoryNotes: ["A gang causing disorder with an L tongue tattoo."],
    ),
    ChallengeKanji(
      japanese: '章',
      english: 'Chapter',
      memoryNotes: ["Getting up early to write another chapter of my book."],
    ),
    ChallengeKanji(
      japanese: '殿',
      english: 'Lord, palace',
      memoryNotes: ["2 zombies with weapons guard the lord together."],
    ),
    ChallengeKanji(
      japanese: '布',
      english: 'Cloth',
      memoryNotes: ["Draping cloth."],
    ),
    ChallengeKanji(
      japanese: '角',
      english: 'Horn, corner',
      memoryNotes: ["Wrapping your hands around a horn to use it. Sitting in a corner while using the horn."],
    ),
  ],
  // Day 68
  [
    ChallengeKanji(
      japanese: '仏',
      english: 'Buddha',
      memoryNotes: ["A person letting go of private desire becomes like a Buddha."],
    ),
    ChallengeKanji(
      japanese: '永',
      english: 'Eternal',
      memoryNotes: ["Water flows for eternity."],
    ),
    ChallengeKanji(
      japanese: '誌',
      english: 'Record, magazine',
      memoryNotes: ["A magazine that tells a story of will and ambition."],
    ),
    ChallengeKanji(
      japanese: '減',
      english: 'Decrease',
      memoryNotes: ["All the water in the land dries up/reduces."],
    ),
    ChallengeKanji(
      japanese: '略',
      english: 'Abbreviation, strategy',
      memoryNotes: ["Each field name is abbreviated."],
    ),
    ChallengeKanji(
      japanese: '準',
      english: 'Standard, semi-',
      memoryNotes: ["Feeding the ducks is standard."],
    ),
    ChallengeKanji(
      japanese: '委',
      english: 'Committee, entrust',
      memoryNotes: ["A committee of woman farmers talking about grain."],
    ),
    ChallengeKanji(
      japanese: '令',
      english: 'Order, command',
      memoryNotes: ["Orders coming from the mother (ma)."],
    ),
    ChallengeKanji(
      japanese: '刊',
      english: 'Publish',
      memoryNotes: ["Once the sword dries it's published to the market."],
    ),
    ChallengeKanji(
      japanese: '焼',
      english: 'Burn',
      memoryNotes: ["Two people baking together with an open fire."],
    ),
    ChallengeKanji(
      japanese: '里',
      english: 'Village, hometown',
      memoryNotes: ["A rural village with loads of fields and soil."],
    ),
    ChallengeKanji(
      japanese: '圧',
      english: 'Pressure',
      memoryNotes: ["Pressure from soil on a cliff causes a landslide."],
    ),
    ChallengeKanji(
      japanese: '額',
      english: 'Forehead, amount',
      memoryNotes: ["A guest with a shellfish tattoo on their forehead."],
    ),
    ChallengeKanji(
      japanese: '印',
      english: 'Seal, mark',
      memoryNotes: ["An E shaped seal."],
    ),
    ChallengeKanji(
      japanese: '池',
      english: 'Pond',
      memoryNotes: ["Water that simply stays becomes a lake."],
    ),
  ],
  // Day 69
  [
    ChallengeKanji(
      japanese: '臣',
      english: 'Retainer, minister',
      memoryNotes: ["A powerful titan retainer stands loyally beside the ruler as a minister."],
    ),
    ChallengeKanji(
      japanese: '庫',
      english: 'Storehouse',
      memoryNotes: ["Under a slanted roof, rows of cars are stored in a warehouse."],
    ),
    ChallengeKanji(
      japanese: '農',
      english: 'Agriculture',
      memoryNotes: ["Music played in the morning to help the agriculture."],
    ),
    ChallengeKanji(
      japanese: '板',
      english: 'Board, plank',
      memoryNotes: ["Anti tree = killing the tree to become planks."],
    ),
    ChallengeKanji(
      japanese: '恋',
      english: 'Love, romance',
      memoryNotes: ["A heart caught in a net of red emotion is romance."],
    ),
    ChallengeKanji(
      japanese: '羽',
      english: 'Feather, wing',
      memoryNotes: ["A bird with icy feathers."],
    ),
    ChallengeKanji(
      japanese: '専',
      english: 'Exclusive',
      memoryNotes: ["A farmer who specialises in growing rulers."],
    ),
    ChallengeKanji(
      japanese: '逆',
      english: 'Reverse, opposite',
      memoryNotes: ["Grass growing the wrong way."],
    ),
    ChallengeKanji(
      japanese: '腕',
      english: 'Arm',
      memoryNotes: ["Using an arm to show how to get to the address."],
    ),
    ChallengeKanji(
      japanese: '短',
      english: 'Short',
      memoryNotes: ["An arrow that's tall and a bean that's short."],
    ),
    ChallengeKanji(
      japanese: '普',
      english: 'General, universal',
      memoryNotes: ["All 7 days lined up in a row as is normal."],
    ),
    ChallengeKanji(
      japanese: '岩',
      english: 'Rock',
      memoryNotes: ["Mountain stone = big stone/boulder."],
    ),
    ChallengeKanji(
      japanese: '竹',
      english: 'Bamboo',
      memoryNotes: ["Two people with bamboo sticks."],
    ),
    ChallengeKanji(
      japanese: '児',
      english: 'Child',
      memoryNotes: ["A child from long ago."],
    ),
    ChallengeKanji(
      japanese: '毛',
      english: 'Hair, fur',
      memoryNotes: ["A cats furry tail."],
    ),
  ],
  // Day 70
  [
    ChallengeKanji(
      japanese: '版',
      english: 'Edition, printing block',
      memoryNotes: ["a printing block."],
    ),
    ChallengeKanji(
      japanese: '宇',
      english: 'Roof, universe',
      memoryNotes: ["Under the roof of reality dry expanding space"],
    ),
    ChallengeKanji(
      japanese: '況',
      english: 'Condition, situation',
      memoryNotes: ["The current situation is that the older brother is sick and sweating."],
    ),
    ChallengeKanji(
      japanese: '被',
      english: 'Be subjected to, suffer',
      memoryNotes: ["Clothing laid over skin means to cover."],
    ),
    ChallengeKanji(
      japanese: '岸',
      english: 'Shore, bank',
      memoryNotes: ["A dry sandy mountain by the sea forms the coast/beach."],
    ),
    ChallengeKanji(
      japanese: '超',
      english: 'Exceed, transcend',
      memoryNotes: ["Running past the person calling you at the finish line, transcending your limits."],
    ),
    ChallengeKanji(
      japanese: '豊',
      english: 'Abundant, rich',
      memoryNotes: ["A great bean feast with music signaling abundance and richness."],
    ),
    ChallengeKanji(
      japanese: '含',
      english: 'Include, contain',
      memoryNotes: ["What's now in your mouth = contain"],
    ),
    ChallengeKanji(
      japanese: '植',
      english: 'Plant',
      memoryNotes: ["A tree is planted and grows straight away."],
    ),
    ChallengeKanji(
      japanese: '補',
      english: 'Supplement, assist',
      memoryNotes: ["Supplying clothes to a charity for the first time."],
    ),
    ChallengeKanji(
      japanese: '暴',
      english: 'Violence, expose',
      memoryNotes: ["Sun mixed together with a lot of water creates a violent reaction."],
    ),
    ChallengeKanji(
      japanese: '課',
      english: 'Section, lesson',
      memoryNotes: ["Talking about fruit as a lesson."],
    ),
    ChallengeKanji(
      japanese: '跡',
      english: 'Trace, remains',
      memoryNotes: ["Marks left behind from feet stepping again and again."],
    ),
    ChallengeKanji(
      japanese: '触',
      english: 'Touch',
      memoryNotes: ["An insect touching a horn."],
    ),
    ChallengeKanji(
      japanese: '玉',
      english: 'Jewel, ball',
      memoryNotes: ["A king kicking up a ball. A ball made of gems."],
    ),
  ],
  // Day 71 - rest day, no new cards
  [],
  // Day 72
  [
    ChallengeKanji(
      japanese: '震',
      english: 'Earthquake, shake',
      memoryNotes: ["A rainy morning when an earthquake occurs."],
    ),
    ChallengeKanji(
      japanese: '億',
      english: 'Hundred million',
      memoryNotes: ["A person's idea grows so large it reaches one hundred million people."],
    ),
    ChallengeKanji(
      japanese: '肩',
      english: 'Shoulder',
      memoryNotes: ["The shoulder is like the door of the arm."],
    ),
    ChallengeKanji(
      japanese: '劇',
      english: 'Drama, intense',
      memoryNotes: ["A tiger and a pig clash swords in a dramatic play."],
    ),
    ChallengeKanji(
      japanese: '刺',
      english: 'Stab, thorn',
      memoryNotes: ["A thorn used as a sword stabs."],
    ),
    ChallengeKanji(
      japanese: '述',
      english: 'State, mention',
      memoryNotes: ["Mentioning an idea to go to a tree."],
    ),
    ChallengeKanji(
      japanese: '輪',
      english: 'Wheel, ring',
      memoryNotes: ["A person riding a car with bookshelf themed wheels."],
    ),
    ChallengeKanji(
      japanese: '浅',
      english: 'Shallow',
      memoryNotes: ["Water barely pierced by spears is shallow."],
    ),
    ChallengeKanji(
      japanese: '純',
      english: 'Pure',
      memoryNotes: ["A pure thread taken from cotton on a mountain."],
    ),
    ChallengeKanji(
      japanese: '薄',
      english: 'Thin, weak',
      memoryNotes: ["His speciality is creating diluted tea."],
    ),
  ],
  // Day 73
  [
    ChallengeKanji(
      japanese: '阪',
      english: 'Slope, Osaka',
      memoryNotes: ["A hill that's against you climbing it is a slope."],
    ),
    ChallengeKanji(
      japanese: '韓',
      english: 'Korea',
      memoryNotes: ["Sun rising early shining on the leather couch whilst eating korean food."],
    ),
    ChallengeKanji(
      japanese: '固',
      english: 'Hard, firm',
      memoryNotes: ["Something locked inside a box becomes solid as it becomes older."],
    ),
    ChallengeKanji(
      japanese: '巨',
      english: 'Huge',
      memoryNotes: ["A giant peering over a wall."],
    ),
    ChallengeKanji(
      japanese: '講',
      english: 'Lecture, explain',
      memoryNotes: ["Words put together to form a lecture."],
    ),
    ChallengeKanji(
      japanese: '般',
      english: 'General, sort',
      memoryNotes: ["In general boats don't have any weapons."],
    ),
    ChallengeKanji(
      japanese: '湯',
      english: 'Hot water, bath',
      memoryNotes: ["Sun-heated water makes a hot bath."],
    ),
    ChallengeKanji(
      japanese: '捨',
      english: 'Throw away',
      memoryNotes: ["Throwing away a cottage."],
    ),
    ChallengeKanji(
      japanese: '衣',
      english: 'Clothes',
      memoryNotes: ["Clothes with a big L on it."],
    ),
    ChallengeKanji(
      japanese: '替',
      english: 'Replace',
      memoryNotes: ["Two husbands trading suns."],
    ),
  ],
  // Day 74
  [
    ChallengeKanji(
      japanese: '央',
      english: 'Center',
      memoryNotes: ["Looks like center 中 but split at the bottom."],
    ),
    ChallengeKanji(
      japanese: '骨',
      english: 'Bone',
      memoryNotes: ["Bones are the color of the moon."],
    ),
    ChallengeKanji(
      japanese: '齢',
      english: 'Age',
      memoryNotes: ["A tooth commands you to say your age."],
    ),
    ChallengeKanji(
      japanese: '照',
      english: 'Illuminate',
      memoryNotes: ["A sword heated in the fire of the sun illuminates."],
    ),
    ChallengeKanji(
      japanese: '層',
      english: 'Layer',
      memoryNotes: ["A zombie moves into a multi-layer building."],
    ),
    ChallengeKanji(
      japanese: '弱',
      english: 'Weak',
      memoryNotes: ["Weak frozen bows."],
    ),
    ChallengeKanji(
      japanese: '築',
      english: 'Build, construct',
      memoryNotes: ["Building desks out of wood and bamboo."],
    ),
    ChallengeKanji(
      japanese: '脳',
      english: 'Brain',
      memoryNotes: ["The brain is controlled by a small villain."],
    ),
    ChallengeKanji(
      japanese: '航',
      english: 'Navigate',
      memoryNotes: ["A boat and a wheel to navigate it."],
    ),
    ChallengeKanji(
      japanese: '快',
      english: 'Pleasant, comfortable',
      memoryNotes: ["When the heart decides it feels pleasant."],
    ),
    ChallengeKanji(
      japanese: '翌',
      english: 'Next (day, year)',
      memoryNotes: ["A bird stands up and flutters his wings, asking what's next."],
    ),
    ChallengeKanji(
      japanese: '旧',
      english: 'Old, former',
      memoryNotes: ["Remembering 1 day from the old days."],
    ),
    ChallengeKanji(
      japanese: '筆',
      english: 'Brush, writing',
      memoryNotes: ["A writing brush made of bamboo."],
    ),
    ChallengeKanji(
      japanese: '換',
      english: 'Exchange, replace',
      memoryNotes: ["A hand wraps around 4 big objects and exchanges them."],
    ),
    ChallengeKanji(
      japanese: '群',
      english: 'Group, flock',
      memoryNotes: ["Mr. Sheep is the leader of a group."],
    ),
  ],
  // Day 75
  [
    ChallengeKanji(
      japanese: '爆',
      english: 'Explode',
      memoryNotes: ["A violent fire causes an explosion."],
    ),
    ChallengeKanji(
      japanese: '捜',
      english: 'Search',
      memoryNotes: ["A hand searching fields again and again looking for something."],
    ),
    ChallengeKanji(
      japanese: '油',
      english: 'Oil',
      memoryNotes: ["Water mixed with a field's produce becomes oil (e.g. olives)."],
    ),
    ChallengeKanji(
      japanese: '叫',
      english: 'Shout',
      memoryNotes: ["A mouth opening wide and shouting 4."],
    ),
    ChallengeKanji(
      japanese: '伸',
      english: 'Stretch, extend',
      memoryNotes: ["A person expanding across a field."],
    ),
    ChallengeKanji(
      japanese: '承',
      english: 'Receive, inherit',
      memoryNotes: ["The king accepts the completed water fountain."],
    ),
    ChallengeKanji(
      japanese: '雲',
      english: 'Cloud',
      memoryNotes: ["The sky says 'rain is coming' by producing clouds."],
    ),
    ChallengeKanji(
      japanese: '練',
      english: 'Practice',
      memoryNotes: ["Practicing knitting in an eastern building."],
    ),
    ChallengeKanji(
      japanese: '紹',
      english: 'Introduce',
      memoryNotes: ["Getting called over by the man in fancy threads to introduce yourself."],
    ),
    ChallengeKanji(
      japanese: '包',
      english: 'Wrap',
      memoryNotes: ["Packing clothes. (Things you wrap around yourself)"],
    ),
    ChallengeKanji(
      japanese: '庁',
      english: 'Agency, government office',
      memoryNotes: ["Under a slanted roof, the government office for the street."],
    ),
    ChallengeKanji(
      japanese: '測',
      english: 'Measure',
      memoryNotes: ["Using water to measure."],
    ),
    ChallengeKanji(
      japanese: '占',
      english: 'Occupy, divine',
      memoryNotes: ["A high/divine mouth can tell the future."],
    ),
    ChallengeKanji(
      japanese: '混',
      english: 'Mix',
      memoryNotes: ["Mixing water and a sun together in a bowl with two spoons."],
    ),
    ChallengeKanji(
      japanese: '倍',
      english: 'Double, times',
      memoryNotes: ["Two identical twins standing and speaking = double."],
    ),
  ],
  // Day 76
  [
    ChallengeKanji(
      japanese: '乳',
      english: 'Milk',
      memoryNotes: ["A small child drinks milk."],
    ),
    ChallengeKanji(
      japanese: '荒',
      english: 'Wild, rough',
      memoryNotes: ["Grass left for dead on the river. Grass death and strong rivers are part of the wild."],
    ),
    ChallengeKanji(
      japanese: '詰',
      english: 'Pack, cram',
      memoryNotes: ["A samurai's mouth is packed with wisdom. A samurai's box is full of stories."],
    ),
    ChallengeKanji(
      japanese: '栄',
      english: 'Prosper, flourish',
      memoryNotes: ["A prospering tree wearing a small crown."],
    ),
    ChallengeKanji(
      japanese: '床',
      english: 'Floor, bed',
      memoryNotes: ["Under a roof, wooden boards make the floor."],
    ),
    ChallengeKanji(
      japanese: '則',
      english: 'Rule, law',
      memoryNotes: ["The law of how to cut a lobster (shellfish + sword) correctly."],
    ),
    ChallengeKanji(
      japanese: '禁',
      english: 'Prohibit',
      memoryNotes: ["A show in a forbidden forest."],
    ),
    ChallengeKanji(
      japanese: '順',
      english: 'Order, obey',
      memoryNotes: ["The river comes first then the shellfish."],
    ),
    ChallengeKanji(
      japanese: '枚',
      english: 'Counter for sheets',
      memoryNotes: ["Trees struck flat become sheets."],
    ),
    ChallengeKanji(
      japanese: '厚',
      english: 'Thick, kind',
      memoryNotes: ["A child on a cold cliff is given a thick blanket by the sun, what a kind sun."],
    ),
    ChallengeKanji(
      japanese: '皮',
      english: 'Skin',
      memoryNotes: ["Leather/skin growing on tree branches."],
    ),
    ChallengeKanji(
      japanese: '輸',
      english: 'Transport',
      memoryNotes: ["A car carrying a hunter with his hunted meat = transport."],
    ),
    ChallengeKanji(
      japanese: '濃',
      english: 'Thick, dense',
      memoryNotes: ["Farmers like their tea/coffee strong."],
    ),
    ChallengeKanji(
      japanese: '簡',
      english: 'Simple',
      memoryNotes: ["A simple gap between each bamboo."],
    ),
    ChallengeKanji(
      japanese: '孫',
      english: 'Grandchild',
      memoryNotes: ["Next child on the family lineage/thread is the grandchild."],
    ),
  ],
  // Day 77
  [
    ChallengeKanji(
      japanese: '丈',
      english: 'Length, height',
      memoryNotes: ["Measuring something by marking an x."],
    ),
    ChallengeKanji(
      japanese: '黄',
      english: 'Yellow',
      memoryNotes: ["Fields gathered together shine yellow."],
    ),
    ChallengeKanji(
      japanese: '届',
      english: 'Deliver, reach',
      memoryNotes: ["A zombie postman delivers a field."],
    ),
    ChallengeKanji(
      japanese: '絡',
      english: 'Entangle, connect',
      memoryNotes: ["Each thread twists causing them to entwine."],
    ),
    ChallengeKanji(
      japanese: '採',
      english: 'Pick, gather',
      memoryNotes: ["A hand picking from a tree harvests."],
    ),
    ChallengeKanji(
      japanese: '傾',
      english: 'Lean, tilt',
      memoryNotes: ["The scales lean toward the lobster."],
    ),
    ChallengeKanji(
      japanese: '鼻',
      english: 'Nose',
      memoryNotes: ["The nose is on the center of your face with crops growing on it."],
    ),
    ChallengeKanji(
      japanese: '宝',
      english: 'Treasure',
      memoryNotes: ["A roof filled with jewels (a treasure chest)."],
    ),
    ChallengeKanji(
      japanese: '患',
      english: 'Suffer, be ill',
      memoryNotes: ["A pierced heart suffers disease."],
    ),
    ChallengeKanji(
      japanese: '延',
      english: 'Extend',
      memoryNotes: ["Stretching the truth."],
    ),
    ChallengeKanji(
      japanese: '律',
      english: 'Law, regulation',
      memoryNotes: ["Stepping to the rhythm with a writing bush in hand."],
    ),
    ChallengeKanji(
      japanese: '希',
      english: 'Hope, rare',
      memoryNotes: ["A cloth with an x on it, the cloth represents the hope of Scotland."],
    ),
    ChallengeKanji(
      japanese: '甘',
      english: 'Sweet',
      memoryNotes: ["A sweet sun shaped fruit (orange)."],
    ),
    ChallengeKanji(
      japanese: '湾',
      english: 'Bay',
      memoryNotes: ["A bay of water wear archers repeatedly come to practice."],
    ),
    ChallengeKanji(
      japanese: '沈',
      english: 'Sink, settle',
      memoryNotes: ["A person wearing a crown sinks to the bottom of the sea."],
    ),
  ],
  // Day 78 - rest day, no new cards
  [],
  // Day 79
  [
    ChallengeKanji(
      japanese: '販',
      english: 'Sell',
      memoryNotes: ["Anti-money/taking money = selling/trade."],
    ),
    ChallengeKanji(
      japanese: '欧',
      english: 'Europe',
      memoryNotes: ["A district lacking any European shops."],
    ),
    ChallengeKanji(
      japanese: '砂',
      english: 'Sand',
      memoryNotes: ["Stone broken down into only a few grains becomes sand."],
    ),
    ChallengeKanji(
      japanese: '尊',
      english: 'Respect, honor',
      memoryNotes: ["The chieftain is measured to be revered to a great extent. I respect the measure of alcohol he drinks."],
    ),
    ChallengeKanji(
      japanese: '紅',
      english: 'Red, crimson',
      memoryNotes: ["Creating crimson-colored threads."],
    ),
    ChallengeKanji(
      japanese: '複',
      english: 'Complex, multiple',
      memoryNotes: ["Clothes layered over people, days, and seasons become multiple."],
    ),
    ChallengeKanji(
      japanese: '泊',
      english: 'Stay overnight',
      memoryNotes: ["Buying milk for an overnight stay."],
    ),
    ChallengeKanji(
      japanese: '荷',
      english: 'Load, baggage',
      memoryNotes: ["What did you pack in your luggage? Just grass."],
    ),
    ChallengeKanji(
      japanese: '枝',
      english: 'Branch',
      memoryNotes: ["A tree branch/bough."],
    ),
    ChallengeKanji(
      japanese: '依',
      english: 'Depend on',
      memoryNotes: ["A person depends on clothes to keep warm."],
    ),
    ChallengeKanji(
      japanese: '幼',
      english: 'Infant, young',
      memoryNotes: ["During childhood you don't even have the power to break a little thread."],
    ),
    ChallengeKanji(
      japanese: '斬',
      english: 'Behead, kill',
      memoryNotes: ["Beheading a car with an axe."],
    ),
    ChallengeKanji(
      japanese: '勇',
      english: 'Brave',
      memoryNotes: ["The aura wrapping the man is courage."],
    ),
    ChallengeKanji(
      japanese: '昇',
      english: 'Rise, ascend',
      memoryNotes: ["The sun lifted by two hands rises upward."],
    ),
    ChallengeKanji(
      japanese: '寿',
      english: 'Longevity',
      memoryNotes: ["Measuring your hand to see how long you'll live."],
    ),
  ],
  // Day 80
  [
    ChallengeKanji(
      japanese: '菜',
      english: 'Vegetable, greens',
      memoryNotes: ["Plants/herbs growing on small trees are vegetables."],
    ),
    ChallengeKanji(
      japanese: '季',
      english: 'Season',
      memoryNotes: ["A tree and his children each representing the four seasons."],
    ),
    ChallengeKanji(
      japanese: '液',
      english: 'Liquid',
      memoryNotes: ["The house gets flooded with liquid at night."],
    ),
    ChallengeKanji(
      japanese: '券',
      english: 'Ticket, coupon',
      memoryNotes: ["A ticket to watch a sword getting forged in a fire."],
    ),
    ChallengeKanji(
      japanese: '祭',
      english: 'Festival',
      memoryNotes: ["A ritual is a show usually performed in the evening."],
    ),
    ChallengeKanji(
      japanese: '袋',
      english: 'Bag',
      memoryNotes: ["A bag can carry substitute clothing."],
    ),
    ChallengeKanji(
      japanese: '燃',
      english: 'Burn',
      memoryNotes: ["Fire is the sort of thing that burns fiercely."],
    ),
    ChallengeKanji(
      japanese: '毒',
      english: 'Poison',
      memoryNotes: ["Every king fears getting poisoned."],
    ),
    ChallengeKanji(
      japanese: '札',
      english: 'Tag, bill',
      memoryNotes: ["A paper bill with an L on it."],
    ),
    ChallengeKanji(
      japanese: '狙',
      english: 'Aim at',
      memoryNotes: ["A beast's eye fixed on something aims for."],
    ),
    ChallengeKanji(
      japanese: '脇',
      english: 'Side, flank',
      memoryNotes: ["The armpit is next to the powerful muscle groups of the upper body."],
    ),
    ChallengeKanji(
      japanese: '卒',
      english: 'Graduate, soldier',
      memoryNotes: ["2 people graduate and wear lids instead of graduation hats."],
    ),
    ChallengeKanji(
      japanese: '副',
      english: 'Assistant, vice-',
      memoryNotes: ["The assistant fills in as the kings sword."],
    ),
    ChallengeKanji(
      japanese: '敬',
      english: 'Respect',
      memoryNotes: ["A phrase is much more respectful than striking."],
    ),
    ChallengeKanji(
      japanese: '針',
      english: 'Needle',
      memoryNotes: ["A golden needle pointing at the number 10 on a clock."],
    ),
  ],
  // Day 81
  [
    ChallengeKanji(
      japanese: '拝',
      english: 'Worship, humbly',
      memoryNotes: ["Worshipping the king with your hand."],
    ),
    ChallengeKanji(
      japanese: '浴',
      english: 'Bathe',
      memoryNotes: ["Bathing in a valley waterfall."],
    ),
    ChallengeKanji(
      japanese: '悩',
      english: 'Worry, trouble',
      memoryNotes: ["A heart disturbed by a small villain worries."],
    ),
    ChallengeKanji(
      japanese: '汚',
      english: 'Dirty, pollute',
      memoryNotes: ["A number 5 in dirty water."],
    ),
    ChallengeKanji(
      japanese: '灯',
      english: 'Lamp, light',
      memoryNotes: ["Controlled fires on a street acting as street lamps."],
    ),
    ChallengeKanji(
      japanese: '坊',
      english: 'Boy, monk',
      memoryNotes: ["A farmer boy shows you how to use the soil."],
    ),
    ChallengeKanji(
      japanese: '尻',
      english: 'Buttocks',
      memoryNotes: ["A zombie with a number 9 on his shorts."],
    ),
    ChallengeKanji(
      japanese: '涙',
      english: 'Tears',
      memoryNotes: ["Water returning from the eye = tears."],
    ),
    ChallengeKanji(
      japanese: '停',
      english: 'Stop',
      memoryNotes: ["A person is halted by a tall person with a hook for a hand."],
    ),
    ChallengeKanji(
      japanese: '了',
      english: 'Finish, complete',
      memoryNotes: ["A coathanger to hang your clothes when you're finished with them."],
    ),
    ChallengeKanji(
      japanese: '汗',
      english: 'Sweat',
      memoryNotes: ["You sweat when you get too dry."],
    ),
    ChallengeKanji(
      japanese: '郵',
      english: 'Mail, postal',
      memoryNotes: ["Mail droops down into the village."],
    ),
    ChallengeKanji(
      japanese: '幅',
      english: 'Width',
      memoryNotes: ["A cloth fills the entire width of the room."],
    ),
    ChallengeKanji(
      japanese: '童',
      english: 'Child',
      memoryNotes: ["A child standing in the village."],
    ),
    ChallengeKanji(
      japanese: '虫',
      english: 'Insect',
      memoryNotes: ["An insect in your mouth."],
    ),
  ],
  // Day 82
  [
    ChallengeKanji(
      japanese: '埋',
      english: 'Bury',
      memoryNotes: ["A village buried under the soil."],
    ),
    ChallengeKanji(
      japanese: '舟',
      english: 'Boat',
      memoryNotes: ["Titanic."],
    ),
    ChallengeKanji(
      japanese: '闇',
      english: 'Darkness',
      memoryNotes: ["A gate into a dark place with scary sounds."],
    ),
    ChallengeKanji(
      japanese: '棒',
      english: 'Stick, rod',
      memoryNotes: ["3 people holding wooden rods."],
    ),
    ChallengeKanji(
      japanese: '貨',
      english: 'Goods, money',
      memoryNotes: ["Changing money into goods."],
    ),
    ChallengeKanji(
      japanese: '肌',
      english: 'Skin',
      memoryNotes: ["A desk with a skin texture."],
    ),
    ChallengeKanji(
      japanese: '臓',
      english: 'Organ (internal)',
      memoryNotes: ["Body parts stored deep like a warehouse are organs."],
    ),
    ChallengeKanji(
      japanese: '塩',
      english: 'Salt',
      memoryNotes: ["Soil is like salt. Salt being served on a person's plate."],
    ),
    ChallengeKanji(
      japanese: '均',
      english: 'Even, equal',
      memoryNotes: ["Equal average level soil. Wraparound an = sign is equal."],
    ),
    ChallengeKanji(
      japanese: '湖',
      english: 'Lake',
      memoryNotes: ["A lake with the reflection of the old moon."],
    ),
    ChallengeKanji(
      japanese: '損',
      english: 'Loss, damage',
      memoryNotes: ["An employee damages goods with his hand."],
    ),
    ChallengeKanji(
      japanese: '膝',
      english: 'Knee',
      memoryNotes: ["A knee with a person swimming in a lake under a tree."],
    ),
    ChallengeKanji(
      japanese: '辛',
      english: 'Spicy, painful',
      memoryNotes: ["Spicy food makes you stand up and makes your mouth feel dry."],
    ),
    ChallengeKanji(
      japanese: '双',
      english: 'Pair',
      memoryNotes: ["Two hands together make a pair."],
    ),
    ChallengeKanji(
      japanese: '軒',
      english: 'Eaves, counter for buildings',
      memoryNotes: ["Vehicles kept dry by eaves in every house."],
    ),
  ],
  // Day 83
  [
    ChallengeKanji(
      japanese: '績',
      english: 'Exploits, achievements',
      memoryNotes: ["The thread of this bow is to blame for my achievements."],
    ),
    ChallengeKanji(
      japanese: '干',
      english: 'Dry, interfere',
      memoryNotes: ["A dry number 1,000."],
    ),
    ChallengeKanji(
      japanese: '姓',
      english: 'Surname',
      memoryNotes: ["A woman is born with a surname but can choose to change it when they get married."],
    ),
    ChallengeKanji(
      japanese: '掘',
      english: 'Dig',
      memoryNotes: ["A zombie digs his way out the ground with his hand."],
    ),
    ChallengeKanji(
      japanese: '籍',
      english: 'Register, enrollment',
      memoryNotes: ["Get enrolled by visiting the old tree and giving the man bamboo."],
    ),
    ChallengeKanji(
      japanese: '珍',
      english: 'Rare, curious',
      memoryNotes: ["A king's clothing/fur is rare."],
    ),
    ChallengeKanji(
      japanese: '訓',
      english: 'Instruction, reading',
      memoryNotes: ["Practicing saying the word river in Japanese."],
    ),
    ChallengeKanji(
      japanese: '預',
      english: 'Deposit, entrust',
      memoryNotes: ["Depositing money beforehand."],
    ),
    ChallengeKanji(
      japanese: '署',
      english: 'Signature, government office',
      memoryNotes: ["A net containing people's signatures."],
    ),
    ChallengeKanji(
      japanese: '漁',
      english: 'Fishing',
      memoryNotes: ["Searching the water for fish = fishing."],
    ),
    ChallengeKanji(
      japanese: '緑',
      english: 'Green',
      memoryNotes: ["A wet broom with green bristles."],
    ),
    ChallengeKanji(
      japanese: '畳',
      english: 'Tatami, fold',
      memoryNotes: ["Inside tatami mats you will see hay from a field."],
    ),
    ChallengeKanji(
      japanese: '咲',
      english: 'Bloom',
      memoryNotes: ["Woah blossoms in the sky."],
    ),
    ChallengeKanji(
      japanese: '貿',
      english: 'Trade',
      memoryNotes: ["Trading money for a place to lift weights and practice the sword."],
    ),
    ChallengeKanji(
      japanese: '踊',
      english: 'Dance',
      memoryNotes: ["Dancing in a path with walls on both sides."],
    ),
  ],
  // Day 84
  [
    ChallengeKanji(
      japanese: '封',
      english: 'Seal',
      memoryNotes: ["Sealing a hole in the soil with a ruler."],
    ),
    ChallengeKanji(
      japanese: '兆',
      english: 'Omen, sign, trillion',
      memoryNotes: ["Icy legs are a sign that you are too cold. Icy legs make you wish it was a trillion times hotter."],
    ),
    ChallengeKanji(
      japanese: '柱',
      english: 'Pillar',
      memoryNotes: ["The chief tree is a pillar."],
    ),
    ChallengeKanji(
      japanese: '駐',
      english: 'Station, reside',
      memoryNotes: ["The chief horse stops at a parking lot."],
    ),
    ChallengeKanji(
      japanese: '祝',
      english: 'Celebrate',
      memoryNotes: ["A festival for the older brother to celebrate his birthday."],
    ),
    ChallengeKanji(
      japanese: '炭',
      english: 'Charcoal, coal',
      memoryNotes: ["Fire fuel found in a mountain = charcoal."],
    ),
    ChallengeKanji(
      japanese: '柔',
      english: 'Soft, gentle',
      memoryNotes: ["A gentle wooden spear."],
    ),
    ChallengeKanji(
      japanese: '雇',
      english: 'Employ',
      memoryNotes: ["A door of opportunity for birds to get employed."],
    ),
    ChallengeKanji(
      japanese: '乾',
      english: 'Dry',
      memoryNotes: ["Would you like it too wet or too dry?"],
    ),
    ChallengeKanji(
      japanese: '鋭',
      english: 'Sharp',
      memoryNotes: ["An older brother's golden pencil sharpener."],
    ),
    ChallengeKanji(
      japanese: '氷',
      english: 'Ice',
      memoryNotes: ["Ice is made of water."],
    ),
    ChallengeKanji(
      japanese: '隅',
      english: 'Corner',
      memoryNotes: ["A long-tailed monkey hanging from the corner of a cliff."],
    ),
    ChallengeKanji(
      japanese: '冊',
      english: 'Tome, counter for books',
      memoryNotes: ["Books neatly lined on a shelf are counted."],
    ),
    ChallengeKanji(
      japanese: '糸',
      english: 'Thread',
      memoryNotes: ["Thread."],
    ),
    ChallengeKanji(
      japanese: '募',
      english: 'Recruit, raise',
      memoryNotes: ["Recruiting someone with the power to mow the grass."],
    ),
  ],
  // Day 85 - rest day, no new cards
  [],
  // Day 86
  [
    ChallengeKanji(
      japanese: '硬',
      english: 'Hard',
      memoryNotes: ["Change to stone = hard."],
    ),
    ChallengeKanji(
      japanese: '塗',
      english: 'Paint, smear',
      memoryNotes: ["Too much water in the soil makes paint."],
    ),
    ChallengeKanji(
      japanese: '憎',
      english: 'Hate',
      memoryNotes: ["A heart filled with hatred."],
    ),
    ChallengeKanji(
      japanese: '泥',
      english: 'Mud',
      memoryNotes: ["Washing a muddy flag and spoon."],
    ),
    ChallengeKanji(
      japanese: '脂',
      english: 'Fat, grease',
      memoryNotes: ["The sun eats the moon with a spoon and gains fat."],
    ),
    ChallengeKanji(
      japanese: '粉',
      english: 'Powder',
      memoryNotes: ["Rice broken into parts becomes powder."],
    ),
    ChallengeKanji(
      japanese: '詞',
      english: 'Words, lyrics',
      memoryNotes: ["Words guided by order form grammar."],
    ),
    ChallengeKanji(
      japanese: '筒',
      english: 'Cylinder, tube',
      memoryNotes: ["Same as bamboo = tube."],
    ),
    ChallengeKanji(
      japanese: '掃',
      english: 'Sweep',
      memoryNotes: ["Hands using a broom to clean."],
    ),
    ChallengeKanji(
      japanese: '塔',
      english: 'Tower',
      memoryNotes: ["Soil matching tower on grass and soil."],
    ),
    ChallengeKanji(
      japanese: '賢',
      english: 'Wise',
      memoryNotes: ["A minister's hand guarding wealth shows wisdom."],
    ),
    ChallengeKanji(
      japanese: '拾',
      english: 'Pick up',
      memoryNotes: ["Picking up the thing that matches what they're looking for."],
    ),
    ChallengeKanji(
      japanese: '麦',
      english: 'Wheat',
      memoryNotes: ["The king eats loads of wheat products in winter."],
    ),
    ChallengeKanji(
      japanese: '刷',
      english: 'Print, brush',
      memoryNotes: ["A zombie wearing a scarf creates sword themed prints."],
    ),
    ChallengeKanji(
      japanese: '卵',
      english: 'Egg',
      memoryNotes: ["A wrapped sealed life waiting to hatch is an egg."],
    ),
  ],
  // Day 87
  [
    ChallengeKanji(
      japanese: '械',
      english: 'Machine',
      memoryNotes: ["A machine that has two hands to chop wood."],
    ),
    ChallengeKanji(
      japanese: '皿',
      english: 'Plate, dish',
      memoryNotes: ["Plates in a plate holder."],
    ),
    ChallengeKanji(
      japanese: '祈',
      english: 'Pray',
      memoryNotes: ["A festival where we pray to the mighty axe."],
    ),
    ChallengeKanji(
      japanese: '灰',
      english: 'Ash',
      memoryNotes: ["A cliff of leftover fire = ash."],
    ),
    ChallengeKanji(
      japanese: '召',
      english: 'Summon',
      memoryNotes: ["A mouth commanding with a blade calls someone."],
    ),
    ChallengeKanji(
      japanese: '溶',
      english: 'Dissolve, melt',
      memoryNotes: ["Objects containing water melt easier."],
    ),
    ChallengeKanji(
      japanese: '磨',
      english: 'Polish, grind',
      memoryNotes: ["Polishing a stone with hemp. Hemp-flavored toothpaste."],
    ),
    ChallengeKanji(
      japanese: '粒',
      english: 'Grain',
      memoryNotes: ["A standing rice plant showing its grain."],
    ),
    ChallengeKanji(
      japanese: '喫',
      english: 'Consume, smoke',
      memoryNotes: ["The king's sword likes to eat and smoke."],
    ),
    ChallengeKanji(
      japanese: '机',
      english: 'Desk',
      memoryNotes: ["A wooden table = desk."],
    ),
    ChallengeKanji(
      japanese: '貯',
      english: 'Save, store',
      memoryNotes: ["A roof in the street for saving money (a bank)."],
    ),
    ChallengeKanji(
      japanese: '匹',
      english: 'Counter for small animals',
      memoryNotes: ["4 small animals."],
    ),
    ChallengeKanji(
      japanese: '綿',
      english: 'Cotton',
      memoryNotes: ["Soft white cotton cloth."],
    ),
    ChallengeKanji(
      japanese: '贈',
      english: 'Present, give',
      memoryNotes: ["A box filled with money/shellfish is a gift."],
    ),
    ChallengeKanji(
      japanese: '凍',
      english: 'Freeze',
      memoryNotes: ["An eastern building frozen in ice."],
    ),
  ],
  // Day 88
  [
    ChallengeKanji(
      japanese: '瓶',
      english: 'Bottle',
      memoryNotes: ["A bottle made out of tiles."],
    ),
    ChallengeKanji(
      japanese: '帽',
      english: 'Hat',
      memoryNotes: ["Cloth to protect the eyes from the sun = hat."],
    ),
    ChallengeKanji(
      japanese: '涼',
      english: 'Cool',
      memoryNotes: ["A cool/cold capital city where the water is very cold."],
    ),
    ChallengeKanji(
      japanese: '秒',
      english: 'Second (time)',
      memoryNotes: ["A machine that plants a few trees every second."],
    ),
    ChallengeKanji(
      japanese: '湿',
      english: 'Damp, moist',
      memoryNotes: ["Heat and moisture lined up together create dampness."],
    ),
    ChallengeKanji(
      japanese: '蒸',
      english: 'Steam',
      memoryNotes: ["Cooking tea on a hob creating steam."],
    ),
    ChallengeKanji(
      japanese: '菓',
      english: 'Confection, sweets',
      memoryNotes: ["Fruit from nature = natures candy."],
    ),
    ChallengeKanji(
      japanese: '耕',
      english: 'Till, cultivate',
      memoryNotes: ["Tilling the land around a well with a tree branch."],
    ),
    ChallengeKanji(
      japanese: '鉱',
      english: 'Mineral, ore',
      memoryNotes: ["Gold spread wide underground is ore."],
    ),
    ChallengeKanji(
      japanese: '膚',
      english: 'Skin',
      memoryNotes: ["Skin is similar to a tiger's stomach."],
    ),
  ],
  // Day 89
  [
    ChallengeKanji(
      japanese: '胃',
      english: 'Stomach',
      memoryNotes: ["The stomach is a field."],
    ),
    ChallengeKanji(
      japanese: '挟',
      english: 'Pinch, squeeze',
      memoryNotes: ["A wife pinches the husband's hand."],
    ),
    ChallengeKanji(
      japanese: '郊',
      english: 'Outskirts',
      memoryNotes: ["Village where people mingle = suburbs."],
    ),
    ChallengeKanji(
      japanese: '銅',
      english: 'Copper',
      memoryNotes: ["Same/similar to gold = copper."],
    ),
    ChallengeKanji(
      japanese: '鈍',
      english: 'Dull, blunt',
      memoryNotes: ["Gold used for tools is quite dull and blunt."],
    ),
    ChallengeKanji(
      japanese: '貝',
      english: 'Shellfish',
      memoryNotes: ["An eye with lobster pincers."],
    ),
    ChallengeKanji(
      japanese: '缶',
      english: 'Can, tin',
      memoryNotes: ["A can of soup called mountain lunch."],
    ),
    ChallengeKanji(
      japanese: '枯',
      english: 'Wither, dry up',
      memoryNotes: ["An old tree losing life withers."],
    ),
    ChallengeKanji(
      japanese: '滴',
      english: 'Drip, drop',
      memoryNotes: ["An ancient building with water dripping."],
    ),
    ChallengeKanji(
      japanese: '符',
      english: 'Token, sign',
      memoryNotes: ["The attached bamboo are tokens."],
    ),
  ],
  // Day 90
  [
    ChallengeKanji(
      japanese: '畜',
      english: 'Livestock',
      memoryNotes: ["A mysterious field filled with livestock."],
    ),
    ChallengeKanji(
      japanese: '軟',
      english: 'Soft',
      memoryNotes: ["A car lacking firmness is soft."],
    ),
    ChallengeKanji(
      japanese: '濯',
      english: 'Rinse, wash',
      memoryNotes: ["A bird does laundry with its wings."],
    ),
    ChallengeKanji(
      japanese: '隻',
      english: 'Counter for animals (large), ships',
      memoryNotes: ["A bird counting ships with his wing."],
    ),
    ChallengeKanji(
      japanese: '伺',
      english: 'Inquire, ask',
      memoryNotes: ["A person visits the director."],
    ),
    ChallengeKanji(
      japanese: '沸',
      english: 'Boil',
      memoryNotes: ["Boiling a dollar."],
    ),
    ChallengeKanji(
      japanese: '曇',
      english: 'Cloudy',
      memoryNotes: ["Day of clouds = cloudy."],
    ),
    ChallengeKanji(
      japanese: '肯',
      english: 'Consent, agree',
      memoryNotes: ["The moon agrees to stop so the day can start."],
    ),
    ChallengeKanji(
      japanese: '燥',
      english: 'Dry up',
      memoryNotes: ["Fire makes the tree logs go dry."],
    ),
    ChallengeKanji(
      japanese: '零',
      english: 'Zero',
      memoryNotes: ["Rain commands that zero people go outside."],
    ),
  ],
];

// Finds the existing dictionary entry for a kanji character (if any) to
// reuse its on'yomi/kun'yomi as the card's reading - the same convention
// used when adding a card from the dictionary search elsewhere in Study.
// Most radicals won't have a dictionary entry, in which case the card is
// simply left without a reading.
String _readingFor(String japanese) {
  for (final set in setsData.values) {
    for (final item in set.items) {
      if (item.japanese == japanese && item.itemType == 'Kanji') {
        return item.kunYomi.isNotEmpty ? item.kunYomi : item.onYomi;
      }
    }
  }
  return '';
}

// A KanjiVG stroke-order code is just the character's Unicode codepoint as
// 5-digit lowercase hex - true for kanji, kana and radicals alike, so this
// works for every character here without needing the dictionary to already
// know about it.
String _kanjiVGCodeFor(String japanese) {
  return japanese.runes.first.toRadixString(16).padLeft(5, '0');
}

StudyCard _cardFromChallengeKanji(ChallengeKanji ck, int dayNumber) {
  return StudyCard(
    japanese: ck.japanese,
    hiragana: _readingFor(ck.japanese),
    english: ck.english,
    kanjiVGCodes: [_kanjiVGCodeFor(ck.japanese)],
    memoryTechnique: ck.memoryNotes.join('\n\n'),
    memoryImageAsset: ck.imageAsset,
    challengeDay: dayNumber,
    // The whole point of this challenge is learning to write each kanji, so
    // every card answers via drawing rather than the default self-graded
    // reveal.
    answerMode: 'draw',
    cardType: 'Kanji',
  );
}

// Builds the full 90 Day Kanji Challenge deck from every day authored so
// far - a fresh StudyDeck starting its schedule today, so new kanji unlock
// one day of content at a time from here on.
StudyDeck buildKanjiChallengeDeck() {
  final cards = <StudyCard>[];
  for (int i = 0; i < kanjiChallengeDays.length; i++) {
    final dayNumber = i + 1;
    for (final ck in kanjiChallengeDays[i]) {
      cards.add(_cardFromChallengeKanji(ck, dayNumber));
    }
  }
  return StudyDeck(
    name: kanjiChallengeDeckName,
    cards: cards,
    challengeStartDate: todayStamp(),
  );
}
