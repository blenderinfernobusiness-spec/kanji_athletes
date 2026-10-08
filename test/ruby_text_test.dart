import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_athletes/ruby_text.dart';

void main() {
  // (word, reading, expected pieces as text:ruby)
  final cases = <List<String>>[
    ['降った', 'ふった', '降:ふ|った:'],
    ['雨', 'あめ', '雨:あめ'],
    ['また明日', 'またあした', 'また:|明日:あした'],
    ['来て', 'きて', '来:き|て:'],
    ['住んでいる', 'すんでいる', '住:す|んでいる:'],
    ['学校', 'がっこう', '学校:がっこう'],
    ['降る', 'ふる, おりる', '降る:'],
    ['取り消す', 'とりけす', '取:と|り:|消:け|す:'],
    ['私の趣味', 'わたしのしゅみ', '私:わたし|の:|趣味:しゅみ'],
    ['可愛い', 'かわいい', '可愛:かわい|い:'],
    ['幸せ', 'しあわせ', '幸:しあわ|せ:'],
    ['暑い', 'あつ.い', '暑:あつ|い:'],
    ['怖かった', 'こわかった', '怖:こわ|かった:'],
    ['分かった', 'わからない', '分かった:'],
    ['いい', 'いい', 'いい:'],
  ];

  for (final c in cases) {
    test('${c[0]} with ${c[1]} puts the reading over the kanji only', () {
      final pieces = rubySegmentsFor(c[0], c[1])
          .map((s) => '${s.text}:${s.ruby}')
          .join('|');
      expect(pieces, c[2]);
    });
  }
}
