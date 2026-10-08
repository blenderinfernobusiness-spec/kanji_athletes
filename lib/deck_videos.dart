import 'lesson_data.dart';
import 'grammar_data.dart';
import 'study_data.dart';

// A video to watch right after finishing a day's new cards, before moving on
// to revision - see spaced_repetition_standard.dart's "today's new cards
// complete" screen, which renders this as a video-player-style card:
// [thumbnail] asset with a play icon over it, and [label] as the caption
// underneath. Only the curricula below have one; a custom deck (or any other
// lesson curriculum with no video for today) gets none.
class DeckVideo {
  final String url;
  final String label;
  final String thumbnail;
  const DeckVideo(this.url, this.label, this.thumbnail);
}

const String _essentialVocabVideoUrl =
    'https://www.skool.com/kanji-athletes-5541/classroom/9959aae4?md=27d24c272a834551aa218225ca1c6ed1';
const String _essentialVocabThumbnail = 'assets/video_thumb_essential_vocab.jpg';
const String _kanjiChallengeThumbnail = 'assets/90dayvids.png';
const String _grammarThumbnail = 'assets/video_thumb_grammar.jpg';
const String _kanaCourseThumbnail = 'assets/video_thumb_kana_course.jpg';

// The 90 Day Kanji Challenge's per-day videos, keyed by challenge day
// (1-based). Add a day's URL here as soon as it's recorded - a day with no
// entry yet just shows no video button on that day's "new cards complete"
// screen, same as a deck with no video at all.
const Map<int, String> kKanjiChallengeDayVideos = {
  1: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=dc1983fa0c594c8b8d310bf1a75bf5de',
  2: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=8f9c48f08cda415d82996e69efda1d0f',
  3: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=e1e8d589c06540fd99a3a50db3738fd6',
  4: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=ebeffbebd01e4116a21e6b5b2ea8ef0d',
  5: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=169f3d8f669a48b1a1e5b1e4168ca95f',
  6: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=e366d0cef7b74dad826aa138d26014f8',
  7: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=d12d2c1144134d8ba6aef234670721f9',
  8: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=2eb52014c0dd47c292e0fc1bb19dbab2',
  9: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=d296c2c6cdf74eb9baa530a96fbfd77d',
  10: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=cc20f1ed176540d9829c0d32c69c487c',
  11: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=ebc375fcadbf4a99a627a3cdaeb33d64',
  12: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=12cfb35150894154bf2c79a07aeb0cb2',
  13: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=1e0f8601ae4a4d5eb592bdb2ed53480c',
  14: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=fb88e7b017494fa4b34c53d2a5695912',
  // Day 15: rest day, no new content - no video.
  16: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=c33e514710c345b68b9a5335ad67c002',
  17: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=f8b4f6a3a32148569159a3a8673b76e3',
  18: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=7329a371b75d404eb98d012c0a6d9998',
  19: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=005ab8026bcb46288ee35d1af4da18b0',
  20: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=076f5b962a554e35bcbe6fe0fd1ca7ce',
  21: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=d039a5eb9c1d462ba0111fa29b8b748c',
  // Day 22: rest day, no new content - no video.
  23: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=8774d680b93643ec82bee40ff68e9395',
  24: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=05510bfc251c4aa9b8b98ee2bc19f385',
  25: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=a3ca1aa3c47e4e779b38a64146effdf7',
  26: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=3c6acd5f9f3e4b00829813c6171e5d5d',
  27: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=1ddd5d6d2ee947ba9aa2b5f51da5b30d',
  28: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=cd869470a2f8405897f2ee57184e7dc0',
  // Day 29: rest day, no new content - no video.
  30: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=d0321fbd0579459a8e058e5105c79fb1',
  31: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=abb2cf072e9f4505b4c8f02da7dac4e1',
  32: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=960cae4e500f4938ae16b284e64c2598',
  33: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=aa92a28b368e452ba35fca28fe1b7b49',
  34: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=f2e0b670b27248ac9873ada7e0bc3381',
  35: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=58f78c0f51614607ad6ce1b1c43b000c',
  // Day 36: rest day, no new content - no video.
  37: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=a8d6f249eb264010a7cfefde723db273',
  38: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=1025455823074d97b09156b829ab1da3',
  39: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=fc625bc7d2b94ec6bfdd4a513a07d346',
  40: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=a950189af7af4416a57329d7bc378ab8',
  41: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=58690cccbfb74145921393ff50032f85',
  42: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=00d3f6645ec943d2b173a11574748b95',
  // Day 43: rest day, no new content - no video.
  44: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=f7250f3c26d0446ab7849800e517ae27',
  45: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=9158b2e9181f42f4b42f9f313b69f280',
  46: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=986fa414d9074a2ca8167e395dfb05a4',
  47: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=a481bc086c3e4ed195368c2ff78b15ec',
  48: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=1767c09be4634da48bf4d85cbc38144a',
  49: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=155e6773aff84cbf95ec098da3b3e643',
  // Day 50: rest day, no new content - no video.
  51: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=8c0c76fc1ad14b0ba5b476305634a3c9',
  52: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=738a6396790243748b43be21ef0550df',
  53: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=8a282e2eb6b84dd3836e12ced645bb9d',
  54: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=ed37b00fb5194808a0720b7820c670e3',
  55: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=02277fbba2574c31beadb1274a0fa477',
  56: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=71109e36452b4065a476f5bc96e671b2',
  // Day 57: rest day, no new content - no video.
  58: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=0d9664b5a37d48eeb64f06c4166e2190',
  59: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=1d22ac4463c94c23a91f1f4770e3fb4a',
  60: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=cb8934da44914c95bb5c400c38d3b7c9',
  61: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=99c39a3354d047e3ad4720a3356867ea',
  62: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=caff3853f86d47148825334de63ba48a',
  63: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=9973795f3c0d43afb942d397b8f8e583',
  // Day 64: rest day, no new content - no video.
  65: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=d75810999cb344cc8d4984990314a086',
  66: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=0574496278aa4206922e5a2cadb7158c',
  67: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=70fcd1d6765f47c5823764fffe0faa39',
  68: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=e3b9fdf842f345a98cc0cc06e92e6299',
  69: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=8d340493ebef4779887d14b205ea2fbe',
  70: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=29148a6d776644438198b392bc2fa3fd',
  // Day 71: rest day, no new content - no video.
  72: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=19619fbcee144a60bfb515b3b8317c11',
  73: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=e8a06520029b4d2fa22ecf2ea54a0af9',
  74: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=f40803ca76f2417ea872f182073fb6de',
  75: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=2e43336e1ba14f7e97d7bc4f0498a5b5',
  76: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=4d2389a5e30947f6be210d6fe3d15006',
  77: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=03a8e7f26125423286f3b5391f21746d',
  // Day 78: rest day, no new content - no video.
  79: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=6ed52c9cb20b42df902a8df8dceabc0c',
  80: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=cdd10084c01547ada31e8dda8ceb4760',
  81: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=d8ca2c02609b413b9c2b2683235b0b5c',
  82: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=1eebc6772cd14746a06e6a6e72364ed1',
  83: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=3bf0a215a8d640f9845c474227b81097',
  84: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=d89b5e7d7c1b4b99bae44048b398cd51',
  // Day 85: rest day, no new content - no video.
  86: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=ce37e66682a64f4183529a25750843dd',
  87: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=6d25c22ef8664ce4a6512914de1b580d',
  88: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=fb844b9b834c443ca59e33b45a355fab',
  89: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=34bd2cd9c7764757ae74842789dc001b',
  90: 'https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=5cb1c7a7722e4342b7928ea084ddb738',
};

// The Kana course's per-day videos.
const Map<int, String> kKanaCourseDayVideos = {
  1: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=06089a30e5704789bf03d41d52ef28fe',
  2: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=d67d1d9e78a24133af6fdad2a28ee119',
  3: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=3c581ac33d9e4da787aef1cc6fc1185e',
  4: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=0bf3b8a5a07f43a49f191058d62dd5b6',
  5: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=26229261375942c1affa2090f767b7a4',
  6: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=3e77c9ecab3445d3b59a8e87c1dc149c',
  7: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=d04b4f7f4b364fada01c82ab5e990ac5',
  8: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=3a8b9d564f07476abdf1285f6bfd3e3a',
  9: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=506ec5a7bc814954a1af56a0c79b430b',
  10: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=4038b94d93f54265b72199ffa349490d',
  11: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=4185539a87144425877e7bb6bde3a8c6',
  12: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=a71989aa395248b1a50b20836f547148',
  13: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=3159c8bc8d7d4dd387aa1342dbcfce99',
  14: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=8077a38714904f1d82f21b41b45ec125',
  15: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=d6c23577dc3240039b4ba1005fce3d5f',
  16: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=5e2961e0c2d34db097e3d7a456980f08',
  17: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=2570e6d7da834d0daf76b44c7dca5f00',
  18: 'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=db9359bf6dd54f2da1d8c88b79fa5c4c',
};

// The Grammar track's per-day videos - none supplied yet.
const Map<int, String> kGrammarDayVideos = {};

// The video for a deck's "today's new cards complete" screen, or null if
// this deck doesn't have one right now (a custom deck, or a day-scheduled
// curriculum whose video for today hasn't been added yet).
DeckVideo? deckCompletionVideo(StudyDeck deck) {
  final trackId = deck.lessonSetId;
  if (trackId == kEssentialVocabTrackId) {
    return const DeckVideo(
      _essentialVocabVideoUrl,
      'Video on learning new words effectively!',
      _essentialVocabThumbnail,
    );
  }
  if (trackId == kKanjiChallengeTrackId) {
    final day = lessonDayFor(deck);
    final url = kKanjiChallengeDayVideos[day];
    return url == null ? null : DeckVideo(url, 'Recap with the Day $day video!', _kanjiChallengeThumbnail);
  }
  if (trackId == kHiraganaTrackId) {
    final day = lessonDayFor(deck);
    final url = kKanaCourseDayVideos[day];
    return url == null ? null : DeckVideo(url, 'Recap with the Day $day video!', _kanaCourseThumbnail);
  }
  if (trackId == kGrammarTrackId) {
    final day = lessonDayFor(deck);
    final url = kGrammarDayVideos[day];
    return url == null ? null : DeckVideo(url, 'Recap with the Day $day video!', _grammarThumbnail);
  }
  return null;
}
