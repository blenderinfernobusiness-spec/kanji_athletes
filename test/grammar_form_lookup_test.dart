import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_athletes/grammar_data.dart';

void main() {
  test('grammarPointForForm finds the lesson that teaches a form', () {
    final ka = grammarPointForForm('か');
    expect(ka, isNotNull);
    expect(ka!.day, 18);
    expect(ka.explanation, isNotEmpty);

    final no = grammarPointForForm('の');
    expect(no, isNotNull);
    expect(no!.day, 15);

    expect(grammarPointForForm('ほげ'), isNull);
  });

  test('grammarQuestionUseOf finds の explained as a casual question marker', () {
    final questionNo = grammarQuestionUseOf('の');
    expect(questionNo, isNotNull);
    expect(questionNo!.note, contains('行くの'));
  });

  test('grammarQuestionUseOf is null for a form with no question-marker use', () {
    expect(grammarQuestionUseOf('は'), isNull);
  });
}
