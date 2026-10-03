import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kanji_athletes/backup_data.dart';

Map<String, dynamic> _deck(String id, {List<Map<String, dynamic>> cards = const []}) => {
  'id': id,
  'name': id,
  'cards': cards,
  'newCardsPerDay': 10,
  'newCardsIntroducedDate': null,
  'newCardsIntroducedToday': 0,
  'challengeStartDate': null,
  'completedLessonDays': <int>[],
  'lessonSetId': null,
  'deckCreatedDate': null,
  'hasShownAnswerIntro': false,
};

Map<String, dynamic> _card(String id, String japanese) => {
  'id': id,
  'japanese': japanese,
  'hiragana': '',
  'romaji': '',
  'english': '',
  'kanjiVGCodes': <String>[],
  'repetitions': 0,
  'easeFactor': 2.5,
  'intervalDays': 0,
  'nextReviewDate': null,
  'progress': 0,
  'englishFirst': true,
  'answerMode': 'basic',
  'memoryTechnique': '',
  'isStarred': false,
  'challengeDay': null,
  'memoryImageAsset': null,
  'cardType': 'Vocab',
};

String _export({List<Map<String, dynamic>> decks = const []}) => jsonEncode({
  'exportFormatVersion': 2,
  'exportedAt': DateTime.now().toIso8601String(),
  'userProfile': {'xp': 0, 'level': 0},
  'gems': [],
  'customSets': {},
  'setOverrides': {},
  'studyDecks': decks,
  'readingTexts': [],
});

// Runs [action] with its own isolated SharedPreferences content (standing in
// for one device's local storage), then captures whatever sync wrote back to
// it into [store] so the same device's NEXT turn picks up where it left off
// - while a different device's turn, using a different store, stays
// completely separate, just like two real phones never share local prefs.
Future<T> _asDevice<T>(Map<String, Object> store, Future<T> Function() action) async {
  SharedPreferences.setMockInitialValues(store);
  final result = await action();
  final prefs = await SharedPreferences.getInstance();
  store.clear();
  final snapshot = prefs.getString('sync_seen_snapshot');
  if (snapshot != null) store['sync_seen_snapshot'] = snapshot;
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a deck deleted on one device stays deleted after another device syncs', () async {
    final fooDeck = _deck('Foo');
    final deviceA = <String, Object>{};
    final deviceB = <String, Object>{};

    // Device A's first-ever sync: no cloud yet, uploads Foo as-is.
    String cloud = await _asDevice(deviceA, () => computeSyncUpload(_export(decks: [fooDeck]), null));

    // Device B's first-ever sync: downloads cloud (has Foo), already has Foo
    // locally too - should end up with exactly one copy, not two.
    cloud = await _asDevice(deviceB, () => computeSyncUpload(_export(decks: [fooDeck]), cloud));
    expect((jsonDecode(cloud)['studyDecks'] as List).length, 1);

    // Device A deletes Foo locally and syncs again.
    cloud = await _asDevice(deviceA, () => computeSyncUpload(_export(decks: []), cloud));
    expect(jsonDecode(cloud)['studyDecks'], isEmpty);
    expect((jsonDecode(cloud)['tombstones']['deckIds'] as Map).containsKey('Foo'), isTrue);

    // Device B, which never deleted Foo and still has it locally, syncs next
    // - it must honor the tombstone and drop its own stale copy, instead of
    // pushing it back up and resurrecting it on the cloud for everyone.
    cloud = await _asDevice(deviceB, () => computeSyncUpload(_export(decks: [fooDeck]), cloud));
    expect(jsonDecode(cloud)['studyDecks'], isEmpty);
  });

  test('renaming a deck is not mistaken for deleting it', () async {
    final deviceA = <String, Object>{};
    final deviceB = <String, Object>{};

    String cloud = await _asDevice(
      deviceA,
      () => computeSyncUpload(_export(decks: [_deck('stable-id', cards: [])]), null),
    );
    cloud = await _asDevice(
      deviceB,
      () => computeSyncUpload(_export(decks: [_deck('stable-id', cards: [])]), cloud),
    );

    // Device A renames the deck (same id, new name) and syncs.
    final renamed = {..._deck('stable-id'), 'name': 'New Name'};
    cloud = await _asDevice(deviceA, () => computeSyncUpload(_export(decks: [renamed]), cloud));
    expect((jsonDecode(cloud)['studyDecks'] as List).single['name'], 'New Name');

    // Device B syncs next - the rename should carry forward, not get treated
    // as "deleted old deck, created an unrelated new one".
    cloud = await _asDevice(
      deviceB,
      () => computeSyncUpload(_export(decks: [_deck('stable-id', cards: [])]), cloud),
    );
    final decks = jsonDecode(cloud)['studyDecks'] as List;
    expect(decks.length, 1);
    expect(decks.single['id'], 'stable-id');
  });

  test('deleting one card from a surviving deck propagates across devices', () async {
    final deviceA = <String, Object>{};
    final deviceB = <String, Object>{};
    final deckWithTwoCards = _deck('deck1', cards: [_card('c1', 'one'), _card('c2', 'two')]);

    String cloud = await _asDevice(deviceA, () => computeSyncUpload(_export(decks: [deckWithTwoCards]), null));
    cloud = await _asDevice(deviceB, () => computeSyncUpload(_export(decks: [deckWithTwoCards]), cloud));

    // Device A deletes card c2 (keeps the deck) and syncs.
    final deckWithOneCard = _deck('deck1', cards: [_card('c1', 'one')]);
    cloud = await _asDevice(deviceA, () => computeSyncUpload(_export(decks: [deckWithOneCard]), cloud));

    // Device B still has both cards locally - its sync should drop c2 rather
    // than pushing it back up.
    cloud = await _asDevice(deviceB, () => computeSyncUpload(_export(decks: [deckWithTwoCards]), cloud));
    final cards = (jsonDecode(cloud)['studyDecks'] as List).single['cards'] as List;
    expect(cards.map((c) => c['id']), ['c1']);
  });
}
