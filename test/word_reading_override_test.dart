import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_athletes/study_data.dart';

void main() {
  // kWordReadingOverrides exists purely to give conjugated/inflected surface
  // forms a reading, not a meaning - but tokenizeSentence should still
  // recover a real meaning for them (from the conjugation table, or from
  // kOverrideBaseWords/kOverrideMeanings for the handful of forms the
  // conjugation table doesn't generate) rather than leaving a word popup
  // blank. Regression test for that bug.
  test('every kWordReadingOverrides surface resolves to a non-empty meaning', () {
    final index = buildHighlightIndex([]);
    for (final surface in kWordReadingOverrides.keys) {
      final tokens = tokenizeSentence(surface, index);
      expect(tokens.length, 1, reason: '$surface should tokenize as a single word');
      expect(
        tokens.first.entry?.meaning,
        isNotNull,
      );
      expect(
        tokens.first.entry!.meaning,
        isNotEmpty,
        reason: '$surface should resolve to a real meaning, not a blank popup',
      );
    }
  });

  test('a conjugated form still prefers a real dictionary/deck entry over an override', () {
    final index = buildHighlightIndex([]);
    // 食べた is both a kWordReadingOverrides entry and a conjugation-table
    // match (食べる's ta-form) - the richer conjugated entry should win,
    // carrying its own dictionary form back to 食べる.
    final tokens = tokenizeSentence('食べた', index);
    expect(tokens.length, 1);
    expect(tokens.first.entry?.dictionaryForm?.japanese, '食べる');
  });

  // 居る/有る (いる/ある) have a kanji form in the dictionary but are almost
  // always actually written in plain kana (います, あります) - the
  // conjugation generators only ever conjugate from a word's own written
  // (kanji) spelling, so without kKanaPreferredVerbs these kana forms
  // wouldn't match anything and would fall apart into ungrouped single kana.
  test('kKanaPreferredVerbs lets kana-written iru/aru forms group as one word', () {
    final index = buildHighlightIndex([]);
    for (final surface in ['います', 'いました', 'いた', 'あります', 'あった']) {
      final tokens = tokenizeSentence(surface, index);
      expect(tokens.length, 1, reason: '$surface should tokenize as a single word');
      expect(tokens.first.entry?.meaning, isNotEmpty, reason: '$surface should have a meaning');
    }
    final sentence = tokenizeSentence('彼は東京にいます。', index);
    expect(sentence.map((t) => t.text).toList(), ['彼', 'は', '東京', 'に', 'います', '。']);
  });
}
