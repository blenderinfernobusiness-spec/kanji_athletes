import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_athletes/study_data.dart';

StudyCard dueReview(String japanese) => StudyCard(
      japanese: japanese,
      hiragana: '',
      english: '',
      repetitions: 1,
      nextReviewDate: '2000-01-01', // long overdue, always due
    );

StudyCard newCard(String japanese) => StudyCard(japanese: japanese, hiragana: '', english: '');

void main() {
  test('new cards come before reviews in a standard session', () {
    final deck = StudyDeck(name: 'd', cards: [dueReview('A'), newCard('B'), dueReview('C'), newCard('D')]);
    final queue = buildSpacedRepetitionQueue(deck);
    expect(queue.map((c) => c.japanese).toList(), ['B', 'D', 'A', 'C']);
  });

  test('new cards are capped by newCardsPerDay', () {
    final deck = StudyDeck(
      name: 'd',
      cards: [newCard('B'), newCard('D'), newCard('E')],
      newCardsPerDay: 2,
    );
    final queue = buildSpacedRepetitionQueue(deck);
    expect(queue.length, 2);
  });

  test('revision-only has no new cards, however many are due', () {
    final deck = StudyDeck(name: 'd', cards: [dueReview('A'), newCard('B'), dueReview('C'), newCard('D')]);
    final queue = buildSpacedRepetitionQueue(deck, revisionOnly: true);
    expect(queue.map((c) => c.japanese).toList(), ['A', 'C']);
  });

  test('revision-only with nothing due is an empty queue, not an error', () {
    final deck = StudyDeck(name: 'd', cards: [newCard('B'), newCard('D')]);
    expect(buildSpacedRepetitionQueue(deck, revisionOnly: true), isEmpty);
  });

  test('a challenge deck still gates new cards by challengeDay in standard mode', () {
    final deck = StudyDeck(
      name: 'd',
      cards: [
        newCard('B')..challengeDay = 1,
        newCard('D')..challengeDay = 99,
      ],
      challengeStartDate: DateTime.now().toIso8601String().split('T')[0],
    );
    final queue = buildSpacedRepetitionQueue(deck);
    expect(queue.map((c) => c.japanese).toList(), ['B']);
  });
}
