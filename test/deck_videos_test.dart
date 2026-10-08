import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_athletes/deck_videos.dart';
import 'package:kanji_athletes/grammar_data.dart';
import 'package:kanji_athletes/lesson_data.dart';
import 'package:kanji_athletes/study_data.dart';

String _daysAgo(int n) => DateTime.now().subtract(Duration(days: n)).toIso8601String().split('T')[0];

void main() {
  test('a custom deck has no video', () {
    final deck = StudyDeck(name: 'My own deck');
    expect(deckCompletionVideo(deck), isNull);
  });

  test('the Grammar deck has no video', () {
    final deck = StudyDeck(name: 'Grammar', lessonSetId: kGrammarTrackId);
    expect(deckCompletionVideo(deck), isNull);
  });

  test('Essential Vocabulary always gets the same video', () {
    final deck = StudyDeck(name: 'Vocabulary', lessonSetId: kEssentialVocabTrackId, deckCreatedDate: _daysAgo(5));
    final video = deckCompletionVideo(deck);
    expect(video, isNotNull);
    expect(video!.label, 'Video on learning new words effectively!');
    expect(video.url, contains('9959aae4'));
  });

  test('the 90 Day Kanji Challenge gets that day\'s video', () {
    // Started 2 days ago -> today is day 3.
    final deck = StudyDeck(name: 'Challenge', lessonSetId: kKanjiChallengeTrackId, challengeStartDate: _daysAgo(2));
    final video = deckCompletionVideo(deck);
    expect(video, isNotNull);
    expect(video!.url, kKanjiChallengeDayVideos[3]);
    expect(video.label, 'Recap with the Day 3 video!');
    expect(video.thumbnail, isNotEmpty);
  });

  test('a challenge day with no video on file yet gets none', () {
    // Started 500 days ago -> well past the 90 days recorded so far.
    final deck = StudyDeck(name: 'Challenge', lessonSetId: kKanjiChallengeTrackId, challengeStartDate: _daysAgo(500));
    expect(deckCompletionVideo(deck), isNull);
  });

  test('a challenge rest day has no video', () {
    // Started 35 days ago -> today is day 36, a rest day with no content.
    final deck = StudyDeck(name: 'Challenge', lessonSetId: kKanjiChallengeTrackId, challengeStartDate: _daysAgo(35));
    expect(deckCompletionVideo(deck), isNull);
  });

  test('the Kana course gets that day\'s video', () {
    // Started 0 days ago -> today is day 1.
    final deck = StudyDeck(name: 'Kana', lessonSetId: kHiraganaTrackId, challengeStartDate: _daysAgo(0));
    final video = deckCompletionVideo(deck);
    expect(video, isNotNull);
    expect(video!.url, kKanaCourseDayVideos[1]);
    expect(video.label, 'Recap with the Day 1 video!');
  });

  test('a Kana course day with no video on file yet gets none', () {
    // Started 500 days ago -> well past the 18 days recorded so far.
    final deck = StudyDeck(name: 'Kana', lessonSetId: kHiraganaTrackId, challengeStartDate: _daysAgo(500));
    expect(deckCompletionVideo(deck), isNull);
  });
}
