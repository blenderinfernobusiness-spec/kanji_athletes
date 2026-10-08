import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_athletes/word_types.dart';

void main() {
  test('godan verbs that look like ichidan are tagged', () {
    expect(wordTypeFor('入る'), 'Godan Verb');
    expect(wordTypeFor('帰る'), 'Godan Verb');
    expect(wordTypeFor('ねじる'), 'Godan Verb');
    // Several written forms on one line each get the tag.
    expect(wordTypeFor('油ぎる'), 'Godan Verb');
    expect(wordTypeFor('脂ぎる'), 'Godan Verb');
  });

  test('kuru and suru are irregular', () {
    expect(wordTypeFor('来る'), 'Irregular Verb');
    expect(wordTypeFor('する'), 'Irregular Verb');
  });

  test('verbs classified by ending', () {
    expect(wordTypeFor('食べる'), 'Ichidan Verb');
    expect(wordTypeFor('教える'), 'Ichidan Verb');
    expect(wordTypeFor('乗り切る'), 'Godan Verb');
    expect(wordTypeFor('生き返る'), 'Godan Verb');
  });

  test('counters', () {
    expect(wordTypeFor('枚'), 'Counter');
    expect(wordTypeFor('匹'), 'Counter');
    expect(wordTypeFor('二つ'), 'Counter');
  });

  test('other words have no type yet', () {
    expect(wordTypeFor('学校'), 'Noun');
    expect(wordTypeFor('それほど'), '');
  });
}
