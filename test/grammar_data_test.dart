import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_athletes/grammar_data.dart';

void main() {
  test('one grammar point per day, with recap-lesson gaps at 88, 98, 105', () {
    // Days 19-22 (Ichidan/Godan/Irregular/building the te-form), 43-45
    // (な-adjectives, い-adjectives, 小さい・小さな), 88 (てください recap),
    // 98 (なくてもいい recap), and 105 (まだ～ていません recap) are concept
    // lessons authored directly as Lessons in lesson_data.dart, not
    // GrammarPoints - see grammarSections.
    expect(
      grammarPoints.map((g) => g.day).toList(),
      [
        ...List.generate(18, (i) => i + 1),
        ...List.generate(20, (i) => i + 23),
        ...List.generate(4, (i) => i + 46),
        ...List.generate(34, (i) => i + 50),
        ...List.generate(4, (i) => i + 84),
        ...List.generate(2, (i) => i + 89),
        ...List.generate(7, (i) => i + 91),
        ...List.generate(6, (i) => i + 99),
        ...List.generate(2, (i) => i + 106),
      ],
    );
  });

  test('every point has four sentences, three creative uses and inspiration words', () {
    for (final g in grammarPoints) {
      expect(g.sentences.length, 4, reason: g.form);
      expect(g.creativeUses, isNotEmpty, reason: g.form);
      expect(g.vocabInspiration, isNotEmpty, reason: g.form);
    }
  });

  test('each point has one or two related forms', () {
    for (final g in grammarPoints) {
      expect(g.related.length, inInclusiveRange(1, 2), reason: g.form);
    }
  });

  test('sentence chunks rebuild the full sentence and contain the target form', () {
    for (final g in grammarPoints) {
      for (final s in g.sentences) {
        expect(s.chunks.join(), s.japanese, reason: '${g.form}: ${s.japanese}');
        expect(s.japanese.contains(s.target), isTrue, reason: '${g.form}: ${s.japanese}');
        expect(g.formChoices.contains(s.target), isTrue, reason: '${g.form}: ${s.target} not offered');
      }
    }
  });

  // JLPT N4 Grammar Lessons - a separate deck/curriculum from grammarPoints
  // (N5) above, so its own day numbering starts again at 1. Currently just
  // Section 1 (11 points); sentence count isn't fixed at 4 like N5's since
  // each one is a genuine sourced Tatoeba example rather than padded to a
  // round number.
  test('N4: one grammar point per day, 1 through 47', () {
    expect(grammarPointsN4.map((g) => g.day).toList(), List.generate(47, (i) => i + 1));
  });

  test('N4: every point has at least two sentences, creative uses and inspiration words', () {
    for (final g in grammarPointsN4) {
      expect(g.sentences.length, greaterThanOrEqualTo(2), reason: g.form);
      expect(g.creativeUses, isNotEmpty, reason: g.form);
      expect(g.vocabInspiration, isNotEmpty, reason: g.form);
    }
  });

  test('N4: each point has one or two related forms', () {
    for (final g in grammarPointsN4) {
      expect(g.related.length, inInclusiveRange(1, 2), reason: g.form);
    }
  });

  test('N4: sentence chunks rebuild the full sentence, contain the target form, and the '
      'target is both a form variant and an offered choice', () {
    for (final g in grammarPointsN4) {
      final variants = g.form.split(' / ').map((v) => v.trim()).toSet();
      for (final s in g.sentences) {
        expect(s.chunks.join(), s.japanese, reason: '${g.form}: ${s.japanese}');
        expect(s.japanese.contains(s.target), isTrue, reason: '${g.form}: ${s.japanese}');
        expect(variants.contains(s.target), isTrue, reason: '${g.form}: ${s.target} not a form variant');
        expect(g.formChoices.contains(s.target), isTrue, reason: '${g.form}: ${s.target} not offered');
      }
    }
  });
}
