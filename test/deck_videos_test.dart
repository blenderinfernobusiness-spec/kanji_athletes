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

  // A challenge deck's recap video is shown for whatever day is actually
  // unlocked right now (deck.unlockedChallengeDay) - see
  // advanceChallengeDayIfReady - not however many calendar days have passed,
  // so these set unlockedChallengeDay directly rather than backdating
  // challengeStartDate.
  test('the 90 Day Kanji Challenge gets that day\'s video', () {
    final deck = StudyDeck(
      name: 'Challenge',
      lessonSetId: kKanjiChallengeTrackId,
      challengeStartDate: _daysAgo(2),
      unlockedChallengeDay: 3,
    );
    final video = deckCompletionVideo(deck);
    expect(video, isNotNull);
    expect(video!.url, kKanjiChallengeDayVideos[3]);
    expect(video.label, 'Recap with the Day 3 video!');
    expect(video.thumbnail, isNotEmpty);
  });

  test('a challenge day with no video on file yet gets none', () {
    // Well past the 90 days recorded so far.
    final deck = StudyDeck(name: 'Challenge', lessonSetId: kKanjiChallengeTrackId, challengeStartDate: _daysAgo(500), unlockedChallengeDay: 500);
    expect(deckCompletionVideo(deck), isNull);
  });

  test('a challenge rest day has no video', () {
    // Day 36 is a rest day with no content.
    final deck = StudyDeck(name: 'Challenge', lessonSetId: kKanjiChallengeTrackId, challengeStartDate: _daysAgo(35), unlockedChallengeDay: 36);
    expect(deckCompletionVideo(deck), isNull);
  });

  test('the Kana course gets that day\'s video', () {
    final deck = StudyDeck(name: 'Kana', lessonSetId: kHiraganaTrackId, challengeStartDate: _daysAgo(0), unlockedChallengeDay: 1);
    final video = deckCompletionVideo(deck);
    expect(video, isNotNull);
    expect(video!.url, kKanaCourseDayVideos[1]);
    expect(video.label, 'Recap with the Day 1 video!');
  });

  test('a Kana course day with no video on file yet gets none', () {
    // Well past the 18 days recorded so far.
    final deck = StudyDeck(name: 'Kana', lessonSetId: kHiraganaTrackId, challengeStartDate: _daysAgo(500), unlockedChallengeDay: 500);
    expect(deckCompletionVideo(deck), isNull);
  });
}
