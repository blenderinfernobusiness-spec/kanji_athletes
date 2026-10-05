import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_athletes/kana_romaji.dart';

void main() {
  test('converts hiragana to romaji', () {
    expect(kanaToRomaji('こんにちは'), 'konnichiha');
    expect(kanaToRomaji('まど'), 'mado');
  });

  test('handles youon combinations', () {
    expect(kanaToRomaji('きょう'), 'kyou');
    expect(kanaToRomaji('しゃしん'), 'shashin');
  });

  test('doubles the following consonant for small tsu', () {
    expect(kanaToRomaji('がっこう'), 'gakkou');
    expect(kanaToRomaji('まっちゃ'), 'matcha');
    expect(kanaToRomaji('ちょっと'), 'chotto');
  });

  test('converts katakana and extends long vowels', () {
    expect(kanaToRomaji('ラーメン'), 'raamen');
  });

  test('passes non-kana text through unchanged', () {
    expect(kanaToRomaji('窓。'), '窓。');
  });
}
