import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_athletes/study_data.dart';

void main() {
  test('tokenizer finds a conjugated verb form not in the dictionary', () {
    final index = buildHighlightIndex(const []);
    final tokens = tokenizeSentence('今日は食べなかった。', index);
    final match = tokens.firstWhere((t) => t.text == '食べなかった');
    expect(match.entry, isNotNull);
    expect(match.entry!.conjugationLabel, 'Past negative (nakatta)');
    expect(match.entry!.reading, 'たべなかった');
    expect(match.entry!.meaning, isNotEmpty); // base dictionary meaning (To eat)
    expect(match.entry!.dictionaryForm, isNotNull);
    expect(match.entry!.dictionaryForm!.japanese, '食べる');
    expect(match.entry!.dictionaryForm!.reading, 'たべる');
  });

  test('a godan verb conjugation is matched even though its single kanji is also a dictionary entry', () {
    // 読 alone is a dictionary (Kanji) entry - the tokenizer should still
    // prefer the full 5-character conjugated form over matching just that.
    final index = buildHighlightIndex(const []);
    final tokens = tokenizeSentence('本を読んだり雑誌を読んだりした。', index);
    final match = tokens.firstWhere((t) => t.text == '読んだり');
    expect(match.entry, isNotNull);
    expect(match.entry!.conjugationLabel, 'Among other things (tari)');
    expect(match.entry!.dictionaryForm!.japanese, '読む');
  });

  test('an i-adjective conjugation is found with the base word as its dictionary form', () {
    final index = buildHighlightIndex(const []);
    final tokens = tokenizeSentence('高くなかった。', index);
    final match = tokens.firstWhere((t) => t.text == '高くなかった');
    expect(match.entry!.conjugationLabel, 'Past negative (kunakatta)');
    expect(match.entry!.dictionaryForm!.japanese, '高い');
  });

  test('the longer combined polite-negative form wins over the plain one', () {
    // 高くなかったです is itself one generated form (Polite past negative), so
    // the greedy matcher should take the whole thing, not stop at 高くなかった.
    final index = buildHighlightIndex(const []);
    final tokens = tokenizeSentence('高くなかったです。', index);
    final match = tokens.firstWhere((t) => t.text == '高くなかったです');
    expect(match.entry!.conjugationLabel, 'Polite past negative (kunakattadesu)');
  });

  test('an irregular (suru) conjugation resolves back to its dictionary form', () {
    // 愛さなかった (さ) is a different, coexisting godan verb 愛す; 愛する's own
    // negative stem is し, so 愛しなかった is the one that's unambiguously its.
    final index = buildHighlightIndex(const []);
    final tokens = tokenizeSentence('全然愛しなかった。', index);
    final match = tokens.firstWhere((t) => t.text == '愛しなかった');
    expect(match.entry!.conjugationLabel, 'Past negative (nakatta)');
    expect(match.entry!.dictionaryForm!.japanese, '愛する');
  });

  test('a real dictionary/deck word still wins over any conjugation reading', () {
    final index = buildHighlightIndex(const []);
    final tokens = tokenizeSentence('食べる', index);
    final match = tokens.firstWhere((t) => t.text == '食べる');
    expect(match.entry!.conjugationLabel, isEmpty); // the dictionary form itself, not a conjugation
  });

  test('gozaimasu (ございます), an irregular honorific godan masu-form, is matched', () {
    final index = buildHighlightIndex(const []);
    final tokens = tokenizeSentence('ありがとうございます。', index);
    final match = tokens.firstWhere((t) => t.text == 'ございます');
    expect(match.entry, isNotNull);
    expect(match.entry!.conjugationLabel, 'Polite (masu)');
    expect(match.entry!.dictionaryForm!.japanese, 'ござる');
  });

  test('deck cards are picked up as the dictionary form of a conjugation match', () {
    final card = StudyCard(japanese: '食べる', hiragana: 'たべる', english: 'my own meaning for to eat');
    final index = buildHighlightIndex([card]);
    final tokens = tokenizeSentence('食べなかった', index);
    final match = tokens.firstWhere((t) => t.text == '食べなかった');
    expect(match.entry!.dictionaryForm!.isDeckWord, isTrue);
    expect(match.entry!.dictionaryForm!.card, isNotNull);
  });
}
