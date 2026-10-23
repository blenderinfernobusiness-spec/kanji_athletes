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

  // Regression coverage for the "292 cards to study despite never starting
  // it" report: a challenge deck left untouched for days used to unlock
  // every elapsed day's cards at once by elapsed time alone. Day N+1 should
  // only ever unlock once day N is actually completed *and* the calendar
  // date has moved on - see advanceChallengeDayIfReady.
  test('a challenge deck left untouched for days does not dump every elapsed day at once', () {
    final deck = StudyDeck(
      name: 'd',
      cards: [
        newCard('day1')..challengeDay = 1,
        newCard('day2')..challengeDay = 2,
        newCard('day5')..challengeDay = 5,
      ],
      // Created 5 days ago and never opened since - old elapsed-time math
      // would have unlocked days 1-5 all at once here.
      challengeStartDate: DateTime.now().subtract(const Duration(days: 5)).toIso8601String().split('T')[0],
    );
    final queue = buildSpacedRepetitionQueue(deck);
    expect(queue.map((c) => c.japanese).toList(), ['day1']);
    expect(deck.unlockedChallengeDay, 1);
  });

  test('working through day 1 the same day it unlocked does not unlock day 2', () {
    final deck = StudyDeck(
      name: 'd',
      cards: [
        newCard('day1')..challengeDay = 1,
        newCard('day2')..challengeDay = 2,
      ],
      challengeStartDate: DateTime.now().toIso8601String().split('T')[0],
    );
    // Simulate finishing day 1's only card today.
    buildSpacedRepetitionQueue(deck).first.nextReviewDate = '2999-01-01';
    final queue = buildSpacedRepetitionQueue(deck);
    expect(queue, isEmpty, reason: 'day 2 must not unlock on the same calendar day as day 1');
    expect(deck.unlockedChallengeDay, 1);
  });

  test('day 2 unlocks once day 1 is complete and the calendar date has moved on', () {
    final deck = StudyDeck(
      name: 'd',
      cards: [
        newCard('day1')..challengeDay = 1,
        newCard('day2')..challengeDay = 2,
      ],
      challengeStartDate: DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0],
      unlockedChallengeDayDate: DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0],
    );
    deck.cards.first.nextReviewDate = '2999-01-01'; // day 1 already completed, yesterday
    final queue = buildSpacedRepetitionQueue(deck);
    expect(queue.map((c) => c.japanese).toList(), ['day2']);
    expect(deck.unlockedChallengeDay, 2);
  });
}
