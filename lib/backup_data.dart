import 'dart:convert';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'sets_data.dart';
import 'set_preferences.dart';
import 'study_data.dart';
import 'user_profile.dart';
import 'backup_data_legacy.dart';
import 'cloud_sync_service.dart';

// Format 2: exports only what's actually personal - custom sets/decks plus
// small per-item patches against the shipped dictionary - instead of
// re-serializing the entire ~27,000-item default dictionary into every
// export. A set/item that matches the shipped default exactly costs
// nothing; starring or annotating one costs a few bytes, not a full copy of
// it. Format 1 (no exportFormatVersion field, a full 'sets' map) is still
// readable - see backup_data_legacy.dart - so old backups never break.
const int _exportFormatVersion = 2;

// defaultPresets (sets_data.dart) only covers Hiragana/Katakana - the other
// ~27,000 dictionary items have no separate pristine copy once setsData
// starts getting mutated at runtime (starring, notes, etc.), so there's
// nothing in memory to diff against. assets/dictionary.json is a snapshot of
// setsData taken fresh at build time (see tool/generate_dictionary_json.dart)
// specifically to fill that gap - loaded once per session and cached, since
// it never changes without a new app build anyway.
Map<String, ItemSet>? _pristineDefaultsCache;

Future<Map<String, ItemSet>> _loadPristineDefaults() async {
  final cached = _pristineDefaultsCache;
  if (cached != null) return cached;
  final raw = await rootBundle.loadString('assets/dictionary.json');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final result = <String, ItemSet>{};
  decoded.forEach((key, value) {
    final s = value as Map<String, dynamic>;
    final items = (s['items'] as List<dynamic>)
        .map((it) => _itemFromMap(Map<String, dynamic>.from(it as Map)))
        .toList();
    result[key] = ItemSet(
      name: s['name'] as String? ?? key,
      items: items,
      setType: s['setType'] as String? ?? 'Uncategorised',
      displayInDictionary: s['displayInDictionary'] as bool? ?? true,
      tags: (s['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  });
  _pristineDefaultsCache = result;
  return result;
}

Map<String, dynamic> _fullItemMap(Item item) => {
  'japanese': item.japanese,
  'translation': item.translation,
  'reading': item.reading,
  'strokeOrder': item.strokeOrder,
  'kanjiVGCode': item.kanjiVGCode,
  'itemType': item.itemType,
  'onYomi': item.onYomi,
  'kunYomi': item.kunYomi,
  'naNori': item.naNori,
  'tags': item.tags,
  'notes': item.notes,
  'isStarred': item.isStarred,
};

Item _itemFromMap(Map<String, dynamic> it) => Item(
  japanese: it['japanese'] as String? ?? '',
  translation: it['translation'] as String? ?? '',
  strokeOrder: it['strokeOrder'] as String? ?? '',
  kanjiVGCode: it['kanjiVGCode'] as String?,
  reading: it['reading'] as String? ?? '',
  itemType: it['itemType'] as String? ?? 'Kanji',
  onYomi: it['onYomi'] as String? ?? '',
  kunYomi: it['kunYomi'] as String? ?? '',
  naNori: it['naNori'] as String? ?? '',
  tags: (it['tags'] as List<dynamic>?)?.cast<String>() ?? [],
  notes: it['notes'] as String? ?? '',
  isStarred: it['isStarred'] as bool? ?? false,
);

Map<String, dynamic> _fullSetMap(ItemSet set) => {
  'name': set.name,
  'tags': set.tags,
  'displayInDictionary': set.displayInDictionary,
  'setType': set.setType,
  'items': set.items.map(_fullItemMap).toList(),
};

// Same deep-copy shape as dictionary.dart's own "reset to defaults" (the
// pattern this mirrors) - every default-backed set starts from a pristine
// copy of what's shipped with the app, not whatever happened to already be
// on this device, so an import always lands on exactly the state the
// export captured.
ItemSet _resetSetFromDefault(ItemSet preset) {
  final items = preset.items
      .map((it) => Item(
            japanese: it.japanese,
            translation: it.translation,
            strokeOrder: it.strokeOrder,
            kanjiVGCode: it.kanjiVGCode,
            itemType: it.itemType,
            reading: it.reading,
            onYomi: it.onYomi,
            kunYomi: it.kunYomi,
            naNori: it.naNori,
            tags: List<String>.from(it.tags),
            notes: it.notes,
            isStarred: it.isStarred,
          ))
      .toList();
  return ItemSet(
    name: preset.name,
    items: items,
    tags: List<String>.from(preset.tags),
    displayInDictionary: preset.displayInDictionary,
    setType: preset.setType,
  );
}

// Only fields a user can actually change on a dictionary item (see
// item_detail.dart's edit dialog, plus isStarred) are worth diffing -
// kanjiVGCode/strokeOrder are derived/technical and never edited, so they're
// left out entirely rather than risk inflating every patch for no reason.
Map<String, dynamic>? _itemOverridePatch(Item current, Item original) {
  final patch = <String, dynamic>{};
  if (current.translation != original.translation) patch['translation'] = current.translation;
  if (current.reading != original.reading) patch['reading'] = current.reading;
  if (current.onYomi != original.onYomi) patch['onYomi'] = current.onYomi;
  if (current.kunYomi != original.kunYomi) patch['kunYomi'] = current.kunYomi;
  if (current.naNori != original.naNori) patch['naNori'] = current.naNori;
  if (current.notes != original.notes) patch['notes'] = current.notes;
  if (current.isStarred != original.isStarred) patch['isStarred'] = current.isStarred;
  if (!listEquals(current.tags, original.tags)) patch['tags'] = current.tags;
  return patch.isEmpty ? null : patch;
}

// Builds the same JSON backup used by both the local file export button and
// cloud upload, so the two stay in lockstep instead of drifting apart.
Future<String> buildExportJson() async {
  await SetPreferences.loadAllSets();
  final prefs = await SharedPreferences.getInstance();

  final user = await UserProfile.load();
  final String? gemString = prefs.getString('gem_data');
  final dynamic gemData = gemString != null ? jsonDecode(gemString) : [];

  final studyDecks = await loadStudyDecks();
  final readingTexts = await loadReadingTexts();
  final pristineDefaults = await _loadPristineDefaults();

  final Map<String, dynamic> customSets = {};
  final Map<String, dynamic> setOverrides = {};

  for (final entry in setsData.entries) {
    final key = entry.key;
    final set = entry.value;
    final original = pristineDefaults[key];

    if (original == null) {
      // Not a default-backed set at all - fully custom, export in full since
      // there's nothing on the other end to reconstruct it from.
      customSets[key] = _fullSetMap(set);
      continue;
    }

    // Matched by japanese+itemType rather than list position, since a user
    // can add new items into an otherwise-default set (those simply won't
    // match anything here and get captured in full below).
    final originalByKey = {for (final i in original.items) '${i.japanese}|${i.itemType}': i};
    final itemOverrides = <Map<String, dynamic>>[];
    for (final item in set.items) {
      final oKey = '${item.japanese}|${item.itemType}';
      final o = originalByKey[oKey];
      if (o == null) {
        itemOverrides.add({'new': true, ..._fullItemMap(item)});
        continue;
      }
      final patch = _itemOverridePatch(item, o);
      if (patch != null) {
        itemOverrides.add({'japanese': item.japanese, 'itemType': item.itemType, ...patch});
      }
    }

    final displayChanged = set.displayInDictionary != original.displayInDictionary;
    final tagsChanged = !listEquals(set.tags, original.tags);
    if (itemOverrides.isNotEmpty || displayChanged || tagsChanged) {
      setOverrides[key] = {
        if (displayChanged) 'displayInDictionary': set.displayInDictionary,
        if (tagsChanged) 'tags': set.tags,
        'itemOverrides': itemOverrides,
      };
    }
  }

  final export = {
    'exportFormatVersion': _exportFormatVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'userProfile': {'xp': user.xp, 'level': user.level},
    'gems': gemData,
    'customSets': customSets,
    'setOverrides': setOverrides,
    'studyDecks': studyDecks.map((d) => d.toMap()).toList(),
    'readingTexts': readingTexts.map((t) => t.toMap()).toList(),
  };

  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(export);
}

// Applies a backup produced by buildExportJson - REPLACING current study
// decks, reading texts, unlocked gems, and dictionary sets/items - shared by
// both the local file import button and cloud restore. Old (format 1)
// exports are detected by the missing exportFormatVersion field and handed
// off to the frozen legacy implementation rather than misread as the new
// shape.
Future<void> applyImportedJson(String content) async {
  final data = jsonDecode(content) as Map<String, dynamic>;
  final version = (data['exportFormatVersion'] as num?)?.toInt() ?? 1;
  if (version < 2) {
    await applyImportedJsonLegacy(content);
    return;
  }

  final prefs = await SharedPreferences.getInstance();

  if (data.containsKey('userProfile')) {
    try {
      final up = data['userProfile'] as Map<String, dynamic>;
      await prefs.setInt('user_xp', (up['xp'] as num?)?.toInt() ?? 0);
      await prefs.setInt('user_level', (up['level'] as num?)?.toInt() ?? 0);
    } catch (_) {}
  }

  if (data.containsKey('gems')) {
    await prefs.setString('gem_data', jsonEncode(data['gems']));
  }

  if (data.containsKey('studyDecks')) {
    try {
      final decks = (data['studyDecks'] as List<dynamic>)
          .map((d) => StudyDeck.fromMap(Map<String, dynamic>.from(d as Map)))
          .toList();
      await saveStudyDecks(decks);
    } catch (_) {}
  }

  if (data.containsKey('readingTexts')) {
    try {
      final texts = (data['readingTexts'] as List<dynamic>)
          .map((t) => ReadingText.fromMap(Map<String, dynamic>.from(t as Map)))
          .toList();
      await saveReadingTexts(texts);
    } catch (_) {}
  }

  // Replace saved sets: remove existing saved set keys
  final keys = prefs.getKeys().toList();
  for (var key in keys) {
    if (key.startsWith('set_') || key.startsWith('practice_set_') || key.startsWith('vocab_set_')) {
      await prefs.remove(key);
    }
  }

  // Every default-backed set starts from a clean, pristine copy of the
  // shipped default before any override is applied - this is what makes an
  // import a true replace rather than a merge: something personalized
  // locally but absent from the imported overrides correctly reverts to
  // default, instead of lingering from before the import.
  final pristineDefaults = await _loadPristineDefaults();
  for (final key in pristineDefaults.keys) {
    setsData[key] = _resetSetFromDefault(pristineDefaults[key]!);
  }

  if (data.containsKey('setOverrides')) {
    final overrides = data['setOverrides'] as Map<String, dynamic>;
    for (final entry in overrides.entries) {
      final setKey = entry.key;
      final base = setsData[setKey];
      if (base == null) continue; // a default set this app version no longer ships
      try {
        final o = entry.value as Map<String, dynamic>;
        if (o.containsKey('displayInDictionary')) base.displayInDictionary = o['displayInDictionary'] as bool;
        if (o.containsKey('tags')) base.tags = (o['tags'] as List<dynamic>).cast<String>();
        final itemOverrides = (o['itemOverrides'] as List<dynamic>?) ?? [];
        final byKey = {for (final i in base.items) '${i.japanese}|${i.itemType}': i};
        for (final raw in itemOverrides) {
          final patch = raw as Map<String, dynamic>;
          if (patch['new'] == true) {
            base.items.add(_itemFromMap(patch));
            continue;
          }
          final target = byKey['${patch['japanese']}|${patch['itemType']}'];
          if (target == null) continue;
          if (patch.containsKey('translation')) target.translation = patch['translation'] as String;
          if (patch.containsKey('reading')) target.reading = patch['reading'] as String;
          if (patch.containsKey('onYomi')) target.onYomi = patch['onYomi'] as String;
          if (patch.containsKey('kunYomi')) target.kunYomi = patch['kunYomi'] as String;
          if (patch.containsKey('naNori')) target.naNori = patch['naNori'] as String;
          if (patch.containsKey('notes')) target.notes = patch['notes'] as String;
          if (patch.containsKey('isStarred')) target.isStarred = patch['isStarred'] as bool;
          if (patch.containsKey('tags')) target.tags = (patch['tags'] as List<dynamic>).cast<String>();
        }
      } catch (_) {}
    }
  }

  if (data.containsKey('customSets')) {
    final sets = data['customSets'] as Map<String, dynamic>;
    for (var entry in sets.entries) {
      final setKey = entry.key;
      try {
        final s = entry.value as Map<String, dynamic>;
        final items = <Item>[];
        if (s.containsKey('items')) {
          for (var it in (s['items'] as List<dynamic>)) {
            try {
              items.add(_itemFromMap(Map<String, dynamic>.from(it as Map)));
            } catch (_) {}
          }
        }
        final newSet = ItemSet(
          name: s['name'] as String? ?? setKey,
          items: items,
          setType: s['setType'] as String? ?? 'Uncategorised',
          displayInDictionary: s['displayInDictionary'] as bool? ?? true,
          tags: (s['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        );
        setsData[setKey] = newSet;
        await SetPreferences.saveSet(setKey, newSet);
      } catch (_) {}
    }
  }

  // Default-backed sets that actually received an override need persisting
  // too, now that they've been reset and patched in memory, so the patch
  // survives an app restart - loadAllSets() below only pulls in whatever's
  // already saved to prefs, it doesn't persist what's currently sitting in
  // memory. A default set with no override is already correctly at its
  // pristine state after the reset above, so it's skipped here rather than
  // re-writing every single shipped set regardless of whether anything
  // about it actually changed - on web, shared_preferences is backed by
  // localStorage, which has a hard per-origin size quota, and some of the
  // larger default sets (the bigger JMdict word lists) are big enough on
  // their own to blow straight through it despite being completely
  // unmodified, failing the whole restore on a set nothing happened to.
  if (data.containsKey('setOverrides')) {
    final overrides = data['setOverrides'] as Map<String, dynamic>;
    for (final key in overrides.keys) {
      final set = setsData[key];
      if (set != null) await SetPreferences.saveSet(key, set);
    }
  }

  await SetPreferences.loadAllSets();
}

// "Sync" is an override, not a two-sided merge: this device's current data
// (including anything you just deleted) always becomes the new cloud truth.
// A plain override alone would still lose anything contributed elsewhere
// (e.g. a word added via the Chrome extension) since the last time this
// device synced, so before overriding, syncToCloud pulls forward just the
// entries on the cloud this device has genuinely never seen before - a new
// deck, a new card in a deck that still exists here, a new custom dictionary
// item, a new reading text. The key distinction from a real merge: whether
// something's "new" is decided by comparing against a persisted snapshot of
// what this device saw last time, not against what's merely absent right
// now - so a deck/card/text that WAS seen before and is missing now is
// recognised as a deliberate deletion and is never resurrected. This
// replaces an earlier two-sided merge that had no such distinction: deleting
// a deck locally didn't stop it reappearing from the cloud on the next sync.
//
// This snapshot alone only protects the device that did the deleting,
// though: it's purely local, never uploaded, so it can't tell a DIFFERENT
// device (one that still has the old copy locally and never deleted it
// itself) that something was deleted elsewhere - that device will happily
// pull-forward "nothing new" and then push its still-intact copy straight
// back up, resurrecting it. _SyncTombstones (below) is what actually closes
// that gap, by recording deletions in the cloud backup itself rather than
// only in the deleting device's own local memory. Keyed by stable id
// (StudyDeck.id/StudyCard.id) rather than name/content, so a rename isn't
// mistaken for a delete+create.
const String _syncSnapshotPrefsKey = 'sync_seen_snapshot';

String _deckId(Map<String, dynamic> deck) => (deck['id'] as String?) ?? (deck['name'] as String? ?? '');
String _cardId(Map<String, dynamic> card) =>
    (card['id'] as String?) ?? '${card['japanese']}|${card['cardType']}';

class _SyncSnapshot {
  final Set<String> deckIds;
  final Map<String, Set<String>> cardIdsByDeck;
  final Set<String> customSetKeys;
  final Map<String, Set<String>> customSetItemKeys;
  final Set<String> overrideSetKeys;
  final Map<String, Set<String>> overrideItemKeys;
  final Set<String> readingTextIds;

  _SyncSnapshot({
    required this.deckIds,
    required this.cardIdsByDeck,
    required this.customSetKeys,
    required this.customSetItemKeys,
    required this.overrideSetKeys,
    required this.overrideItemKeys,
    required this.readingTextIds,
  });

  // An empty snapshot (first time this device has ever run this sync logic)
  // treats everything on the cloud as "never seen" - i.e. pull all of it in,
  // the safe default rather than wrongly treating unfamiliar cloud content
  // as something this device already deleted.
  factory _SyncSnapshot.empty() => _SyncSnapshot(
    deckIds: {},
    cardIdsByDeck: {},
    customSetKeys: {},
    customSetItemKeys: {},
    overrideSetKeys: {},
    overrideItemKeys: {},
    readingTextIds: {},
  );

  Map<String, dynamic> toJson() => {
    'deckIds': deckIds.toList(),
    'cardIdsByDeck': cardIdsByDeck.map((k, v) => MapEntry(k, v.toList())),
    'customSetKeys': customSetKeys.toList(),
    'customSetItemKeys': customSetItemKeys.map((k, v) => MapEntry(k, v.toList())),
    'overrideSetKeys': overrideSetKeys.toList(),
    'overrideItemKeys': overrideItemKeys.map((k, v) => MapEntry(k, v.toList())),
    'readingTextIds': readingTextIds.toList(),
  };

  factory _SyncSnapshot.fromJson(Map<String, dynamic> j) => _SyncSnapshot(
    // Older snapshots (saved before ids existed) used 'deckNames'/
    // 'cardKeysByDeck' - those keys happen to already BE what _deckId/
    // _cardId fall back to for pre-migration data, so reading them under
    // their old names here still lines up correctly with the new id-based
    // comparisons everywhere else.
    deckIds: Set<String>.from(j['deckIds'] as List<dynamic>? ?? j['deckNames'] as List<dynamic>? ?? const []),
    cardIdsByDeck: ((j['cardIdsByDeck'] ?? j['cardKeysByDeck']) as Map<String, dynamic>? ?? const {}).map(
      (k, v) => MapEntry(k, Set<String>.from(v as List<dynamic>)),
    ),
    customSetKeys: Set<String>.from(j['customSetKeys'] as List<dynamic>? ?? const []),
    customSetItemKeys: (j['customSetItemKeys'] as Map<String, dynamic>? ?? const {}).map(
      (k, v) => MapEntry(k, Set<String>.from(v as List<dynamic>)),
    ),
    overrideSetKeys: Set<String>.from(j['overrideSetKeys'] as List<dynamic>? ?? const []),
    overrideItemKeys: (j['overrideItemKeys'] as Map<String, dynamic>? ?? const {}).map(
      (k, v) => MapEntry(k, Set<String>.from(v as List<dynamic>)),
    ),
    readingTextIds: Set<String>.from(j['readingTextIds'] as List<dynamic>? ?? const []),
  );
}

// Deletions recorded in the cloud backup itself (not just locally - see
// _SyncSnapshot's doc comment) so every device, not only the one that did
// the deleting, learns about them. Keyed the same way as _SyncSnapshot.
// Value is the ISO deletion timestamp, used only to age entries out (see
// prunedOlderThan) - presence is otherwise all that matters.
//
// cardIdsByDeck/customSetItemKeys are scoped per-container rather than one
// flat set so that e.g. duplicating a deck (which intentionally copies its
// cards' ids - see duplicateDeck) can't make a card deleted from the
// original wrongly vanish from the duplicate too.
class _SyncTombstones {
  final Map<String, String> deckIds;
  final Map<String, Map<String, String>> cardIdsByDeck;
  final Map<String, String> customSetKeys;
  final Map<String, Map<String, String>> customSetItemKeys;
  final Map<String, String> readingTextIds;

  _SyncTombstones({
    required this.deckIds,
    required this.cardIdsByDeck,
    required this.customSetKeys,
    required this.customSetItemKeys,
    required this.readingTextIds,
  });

  factory _SyncTombstones.fromJson(Map<String, dynamic> j) => _SyncTombstones(
    deckIds: Map<String, String>.from(j['deckIds'] as Map? ?? const {}),
    cardIdsByDeck: (j['cardIdsByDeck'] as Map<String, dynamic>? ?? const {}).map(
      (k, v) => MapEntry(k, Map<String, String>.from(v as Map)),
    ),
    customSetKeys: Map<String, String>.from(j['customSetKeys'] as Map? ?? const {}),
    customSetItemKeys: (j['customSetItemKeys'] as Map<String, dynamic>? ?? const {}).map(
      (k, v) => MapEntry(k, Map<String, String>.from(v as Map)),
    ),
    readingTextIds: Map<String, String>.from(j['readingTextIds'] as Map? ?? const {}),
  );

  Map<String, dynamic> toJson() => {
    'deckIds': deckIds,
    'cardIdsByDeck': cardIdsByDeck,
    'customSetKeys': customSetKeys,
    'customSetItemKeys': customSetItemKeys,
    'readingTextIds': readingTextIds,
  };

  // Keeps every tombstone from both sides - a deletion must never silently
  // un-happen just because one side's copy of the tombstone list happened
  // to be older.
  static _SyncTombstones union(_SyncTombstones a, _SyncTombstones b) {
    Map<String, String> mergeFlat(Map<String, String> x, Map<String, String> y) => {...x, ...y};
    Map<String, Map<String, String>> mergeNested(
      Map<String, Map<String, String>> x,
      Map<String, Map<String, String>> y,
    ) {
      final result = <String, Map<String, String>>{for (final e in x.entries) e.key: {...e.value}};
      for (final e in y.entries) {
        result[e.key] = {...(result[e.key] ?? {}), ...e.value};
      }
      return result;
    }

    return _SyncTombstones(
      deckIds: mergeFlat(a.deckIds, b.deckIds),
      cardIdsByDeck: mergeNested(a.cardIdsByDeck, b.cardIdsByDeck),
      customSetKeys: mergeFlat(a.customSetKeys, b.customSetKeys),
      customSetItemKeys: mergeNested(a.customSetItemKeys, b.customSetItemKeys),
      readingTextIds: mergeFlat(a.readingTextIds, b.readingTextIds),
    );
  }

  // Drops tombstones older than [maxAge] - by then every device has surely
  // synced at least once since the deletion, so keeping the record forever
  // would just make the backup grow without bound.
  _SyncTombstones prunedOlderThan(Duration maxAge) {
    final cutoff = DateTime.now().subtract(maxAge);
    bool fresh(String iso) {
      final t = DateTime.tryParse(iso);
      return t == null || t.isAfter(cutoff);
    }

    Map<String, String> pruneFlat(Map<String, String> m) => {for (final e in m.entries) if (fresh(e.value)) e.key: e.value};
    Map<String, Map<String, String>> pruneNested(Map<String, Map<String, String>> m) {
      final result = <String, Map<String, String>>{};
      for (final e in m.entries) {
        final inner = pruneFlat(e.value);
        if (inner.isNotEmpty) result[e.key] = inner;
      }
      return result;
    }

    return _SyncTombstones(
      deckIds: pruneFlat(deckIds),
      cardIdsByDeck: pruneNested(cardIdsByDeck),
      customSetKeys: pruneFlat(customSetKeys),
      customSetItemKeys: pruneNested(customSetItemKeys),
      readingTextIds: pruneFlat(readingTextIds),
    );
  }
}

const Duration _tombstoneRetention = Duration(days: 180);

// Compares this device's current export against what it saw last sync
// (snapshot) to find things THIS device deleted since then - these become
// new tombstones, unioned with whatever's already in the cloud before the
// pull-forward functions below run.
_SyncTombstones _detectNewTombstones(Map<String, dynamic> local, _SyncSnapshot snapshot) {
  final now = DateTime.now().toIso8601String();

  final currentDeckIds = <String>{};
  final cardIdsByDeck = <String, Set<String>>{};
  for (final d in ((local['studyDecks'] as List<dynamic>?) ?? [])) {
    final deck = d as Map<String, dynamic>;
    final id = _deckId(deck);
    currentDeckIds.add(id);
    cardIdsByDeck[id] = {
      for (final c in ((deck['cards'] as List<dynamic>?) ?? [])) _cardId(c as Map<String, dynamic>),
    };
  }
  final deletedDeckIds = snapshot.deckIds.difference(currentDeckIds);

  final deletedCardIdsByDeck = <String, Set<String>>{};
  for (final entry in snapshot.cardIdsByDeck.entries) {
    // Only meaningful for a deck that still exists locally - if the whole
    // deck is gone, deletedDeckIds above already covers it.
    final currentCards = cardIdsByDeck[entry.key];
    if (currentCards == null) continue;
    final deleted = entry.value.difference(currentCards);
    if (deleted.isNotEmpty) deletedCardIdsByDeck[entry.key] = deleted;
  }

  final currentCustomSetKeys = <String>{};
  final customSetItemKeysBySet = <String, Set<String>>{};
  ((local['customSets'] as Map<String, dynamic>?) ?? {}).forEach((key, value) {
    currentCustomSetKeys.add(key);
    final set = value as Map<String, dynamic>;
    customSetItemKeysBySet[key] = {
      for (final it in ((set['items'] as List<dynamic>?) ?? [])) '${(it as Map<String, dynamic>)['japanese']}|${it['itemType']}',
    };
  });
  final deletedCustomSetKeys = snapshot.customSetKeys.difference(currentCustomSetKeys);

  final deletedCustomSetItemKeys = <String, Set<String>>{};
  for (final entry in snapshot.customSetItemKeys.entries) {
    final currentItems = customSetItemKeysBySet[entry.key];
    if (currentItems == null) continue;
    final deleted = entry.value.difference(currentItems);
    if (deleted.isNotEmpty) deletedCustomSetItemKeys[entry.key] = deleted;
  }

  final currentReadingTextIds = <String>{
    for (final t in ((local['readingTexts'] as List<dynamic>?) ?? [])) (t as Map<String, dynamic>)['id'] as String,
  };
  final deletedReadingTextIds = snapshot.readingTextIds.difference(currentReadingTextIds);

  return _SyncTombstones(
    deckIds: {for (final id in deletedDeckIds) id: now},
    cardIdsByDeck: deletedCardIdsByDeck.map((k, v) => MapEntry(k, {for (final id in v) id: now})),
    customSetKeys: {for (final key in deletedCustomSetKeys) key: now},
    customSetItemKeys: deletedCustomSetItemKeys.map((k, v) => MapEntry(k, {for (final id in v) id: now})),
    readingTextIds: {for (final id in deletedReadingTextIds) id: now},
  );
}

Future<_SyncSnapshot> _loadSyncSnapshot() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_syncSnapshotPrefsKey);
  if (raw == null) return _SyncSnapshot.empty();
  try {
    return _SyncSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return _SyncSnapshot.empty();
  }
}

Future<void> _saveSyncSnapshot(_SyncSnapshot snapshot) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_syncSnapshotPrefsKey, jsonEncode(snapshot.toJson()));
}

// Captures the full key-set of [export] - this becomes "what this device has
// seen" for next time, so anything missing on a future sync that WAS in this
// set is recognised as a deletion rather than pulled back in.
_SyncSnapshot _snapshotFromExport(Map<String, dynamic> export) {
  final deckIds = <String>{};
  final cardIdsByDeck = <String, Set<String>>{};
  for (final d in ((export['studyDecks'] as List<dynamic>?) ?? [])) {
    final deck = d as Map<String, dynamic>;
    final id = _deckId(deck);
    deckIds.add(id);
    cardIdsByDeck[id] = {
      for (final c in ((deck['cards'] as List<dynamic>?) ?? [])) _cardId(c as Map<String, dynamic>),
    };
  }

  final customSetKeys = <String>{};
  final customSetItemKeys = <String, Set<String>>{};
  ((export['customSets'] as Map<String, dynamic>?) ?? {}).forEach((key, value) {
    customSetKeys.add(key);
    final set = value as Map<String, dynamic>;
    customSetItemKeys[key] = {
      for (final it in ((set['items'] as List<dynamic>?) ?? []))
        '${(it as Map<String, dynamic>)['japanese']}|${it['itemType']}',
    };
  });

  final overrideSetKeys = <String>{};
  final overrideItemKeys = <String, Set<String>>{};
  ((export['setOverrides'] as Map<String, dynamic>?) ?? {}).forEach((key, value) {
    overrideSetKeys.add(key);
    final o = value as Map<String, dynamic>;
    overrideItemKeys[key] = {
      for (final p in ((o['itemOverrides'] as List<dynamic>?) ?? []))
        '${(p as Map<String, dynamic>)['japanese']}|${p['itemType']}',
    };
  });

  final readingTextIds = <String>{
    for (final t in ((export['readingTexts'] as List<dynamic>?) ?? []))
      (t as Map<String, dynamic>)['id'] as String,
  };

  return _SyncSnapshot(
    deckIds: deckIds,
    cardIdsByDeck: cardIdsByDeck,
    customSetKeys: customSetKeys,
    customSetItemKeys: customSetItemKeys,
    overrideSetKeys: overrideSetKeys,
    overrideItemKeys: overrideItemKeys,
    readingTextIds: readingTextIds,
  );
}

// xp/level only ever go up during normal play, so the higher value from
// either side is always the more progressed one - no tombstone needed since
// a scalar like this was never "deleted" to begin with.
Map<String, dynamic> _mergeUserProfile(dynamic l, dynamic c) {
  final lm = (l as Map<String, dynamic>?) ?? {};
  final cm = (c as Map<String, dynamic>?) ?? {};
  final lXp = (lm['xp'] as num?)?.toInt() ?? 0;
  final cXp = (cm['xp'] as num?)?.toInt() ?? 0;
  final lLevel = (lm['level'] as num?)?.toInt() ?? 0;
  final cLevel = (cm['level'] as num?)?.toInt() ?? 0;
  return {'xp': lXp > cXp ? lXp : cXp, 'level': lLevel > cLevel ? lLevel : cLevel};
}

// Each gem slot is a one-way "unlocked" flag (see main.dart's _gemData) -
// ORing the two sides together keeps whichever slots either device has
// unlocked. Not tombstoned either: there's no per-slot "delete", only the
// all-at-once reset, which is an explicit action this simple merge doesn't
// need to special-case.
dynamic _mergeGems(dynamic l, dynamic c) {
  if (l is! List) return c ?? l;
  if (c is! List) return l;
  final length = l.length > c.length ? l.length : c.length;
  return List.generate(length, (i) {
    final lv = i < l.length && l[i] == true;
    final cv = i < c.length && c[i] == true;
    return lv || cv;
  });
}

List<Map<String, dynamic>> _pullForwardDecks(
  dynamic localRaw,
  dynamic cloudRaw,
  _SyncSnapshot snapshot,
  _SyncTombstones tombstones,
) {
  final local = (localRaw as List<dynamic>?) ?? [];
  final cloud = (cloudRaw as List<dynamic>?) ?? [];
  final localById = <String, Map<String, dynamic>>{for (final d in local) _deckId(d as Map<String, dynamic>): d};
  final cloudById = <String, Map<String, dynamic>>{for (final d in cloud) _deckId(d as Map<String, dynamic>): d};

  final result = <String, Map<String, dynamic>>{
    for (final entry in localById.entries) entry.key: Map<String, dynamic>.from(entry.value),
  };

  // Honor deletions made on another device: a deck this device still has
  // locally but that's now tombstoned (deleted elsewhere since this device
  // last synced it) gets removed too, not just left alone - otherwise this
  // sync's own upload below would push it straight back up and resurrect it.
  result.removeWhere((id, _) => tombstones.deckIds.containsKey(id));

  cloudById.forEach((id, cloudDeck) {
    if (tombstones.deckIds.containsKey(id)) return; // deleted somewhere - never pull back in
    final localDeck = result[id];
    if (localDeck == null) {
      // Missing locally - only pull it in if this device has never seen a
      // deck by this id before (truly new, e.g. created via the extension).
      // Previously seen means it was deliberately deleted here.
      if (!snapshot.deckIds.contains(id)) {
        result[id] = Map<String, dynamic>.from(cloudDeck);
      }
      return;
    }
    final seenCardIds = snapshot.cardIdsByDeck[id] ?? const <String>{};
    final tombstonedCardIds = tombstones.cardIdsByDeck[id] ?? const <String, String>{};
    final localCards = ((localDeck['cards'] as List<dynamic>?) ?? []).cast<Map<String, dynamic>>();
    final keptLocalCards = [for (final c in localCards) if (!tombstonedCardIds.containsKey(_cardId(c))) c];
    final keptLocalCardIds = {for (final c in keptLocalCards) _cardId(c)};
    final cloudCards = ((cloudDeck['cards'] as List<dynamic>?) ?? []).cast<Map<String, dynamic>>();
    final additions = <Map<String, dynamic>>[
      for (final c in cloudCards)
        if (!keptLocalCardIds.contains(_cardId(c)) &&
            !seenCardIds.contains(_cardId(c)) &&
            !tombstonedCardIds.containsKey(_cardId(c)))
          c,
    ];
    localDeck['cards'] = [...keptLocalCards, ...additions];
  });

  return result.values.toList();
}

Map<String, dynamic> _pullForwardCustomSets(
  dynamic localRaw,
  dynamic cloudRaw,
  _SyncSnapshot snapshot,
  _SyncTombstones tombstones,
) {
  final local = (localRaw as Map<String, dynamic>?) ?? {};
  final cloud = (cloudRaw as Map<String, dynamic>?) ?? {};
  final result = <String, dynamic>{...local};

  // Honor deletions made on another device - same reasoning as
  // _pullForwardDecks' equivalent line.
  result.removeWhere((key, _) => tombstones.customSetKeys.containsKey(key));

  cloud.forEach((key, cloudSetRaw) {
    if (tombstones.customSetKeys.containsKey(key)) return;
    final cloudSet = cloudSetRaw as Map<String, dynamic>;
    final localSet = result[key] as Map<String, dynamic>?;
    if (localSet == null) {
      if (!snapshot.customSetKeys.contains(key)) result[key] = cloudSet;
      return;
    }
    final seenItemKeys = snapshot.customSetItemKeys[key] ?? const <String>{};
    final tombstonedItemKeys = tombstones.customSetItemKeys[key] ?? const <String, String>{};
    final localItems = ((localSet['items'] as List<dynamic>?) ?? []).cast<Map<String, dynamic>>();
    final keptLocalItems = [
      for (final it in localItems) if (!tombstonedItemKeys.containsKey('${it['japanese']}|${it['itemType']}')) it,
    ];
    final keptLocalItemKeys = {for (final it in keptLocalItems) '${it['japanese']}|${it['itemType']}'};
    final cloudItems = ((cloudSet['items'] as List<dynamic>?) ?? []).cast<Map<String, dynamic>>();
    final additions = <Map<String, dynamic>>[
      for (final it in cloudItems)
        if (!keptLocalItemKeys.contains('${it['japanese']}|${it['itemType']}') &&
            !seenItemKeys.contains('${it['japanese']}|${it['itemType']}') &&
            !tombstonedItemKeys.containsKey('${it['japanese']}|${it['itemType']}'))
          it,
    ];
    localSet['items'] = [...keptLocalItems, ...additions];
  });

  return result;
}

Map<String, dynamic> _pullForwardSetOverrides(dynamic localRaw, dynamic cloudRaw, _SyncSnapshot snapshot) {
  final local = (localRaw as Map<String, dynamic>?) ?? {};
  final cloud = (cloudRaw as Map<String, dynamic>?) ?? {};
  final result = <String, dynamic>{...local};

  cloud.forEach((key, cloudOverrideRaw) {
    final cloudOverride = cloudOverrideRaw as Map<String, dynamic>;
    final localOverride = result[key] as Map<String, dynamic>?;
    if (localOverride == null) {
      if (!snapshot.overrideSetKeys.contains(key)) result[key] = cloudOverride;
      return;
    }
    final seenPatchKeys = snapshot.overrideItemKeys[key] ?? const <String>{};
    final localPatches = ((localOverride['itemOverrides'] as List<dynamic>?) ?? []).cast<Map<String, dynamic>>();
    final localPatchKeys = {for (final p in localPatches) '${p['japanese']}|${p['itemType']}'};
    final cloudPatches = ((cloudOverride['itemOverrides'] as List<dynamic>?) ?? []).cast<Map<String, dynamic>>();
    final additions = <Map<String, dynamic>>[
      for (final p in cloudPatches)
        if (!localPatchKeys.contains('${p['japanese']}|${p['itemType']}') &&
            !seenPatchKeys.contains('${p['japanese']}|${p['itemType']}'))
          p,
    ];
    if (additions.isNotEmpty) localOverride['itemOverrides'] = [...localPatches, ...additions];
  });

  return result;
}

List<Map<String, dynamic>> _pullForwardReadingTexts(
  dynamic localRaw,
  dynamic cloudRaw,
  _SyncSnapshot snapshot,
  _SyncTombstones tombstones,
) {
  final local = ((localRaw as List<dynamic>?) ?? []).cast<Map<String, dynamic>>();
  final cloud = ((cloudRaw as List<dynamic>?) ?? []).cast<Map<String, dynamic>>();
  // Honor deletions made on another device - same reasoning as
  // _pullForwardDecks' equivalent line.
  final keptLocal = [for (final t in local) if (!tombstones.readingTextIds.containsKey(t['id'] as String)) t];
  final keptLocalIds = {for (final t in keptLocal) t['id'] as String};
  return [
    ...keptLocal,
    for (final t in cloud)
      if (!keptLocalIds.contains(t['id'] as String) &&
          !snapshot.readingTextIds.contains(t['id'] as String) &&
          !tombstones.readingTextIds.containsKey(t['id'] as String))
        t,
  ];
}

// Downloads the latest cloud backup (if any), pulls forward anything
// genuinely new from it (see the _SyncSnapshot doc comment above), applies
// the result back to this device, then uploads it as the new cloud truth -
// an override, not a merge, so a deletion made on this device stays deleted.
// Pure decision logic, pulled out of syncToCloud so it can be exercised in
// tests without a live Firebase connection: given this device's current
// export and the cloud's current backup (or null if there isn't one, or it
// isn't readable), decides what the new cloud backup should become and
// updates the seen-snapshot to match. Also used directly by syncToCloud.
Future<String> computeSyncUpload(String localJson, String? cloudJson) async {
  String finalJson = localJson;
  if (cloudJson != null) {
    try {
      final local = jsonDecode(localJson) as Map<String, dynamic>;
      final cloud = jsonDecode(cloudJson) as Map<String, dynamic>;
      if (((cloud['exportFormatVersion'] as num?)?.toInt() ?? 1) >= 2) {
        final snapshot = await _loadSyncSnapshot();
        // Deletions this device made since its last sync (missing now vs.
        // snapshot) plus whatever's already tombstoned on the cloud from any
        // device's past sync - union of both is what every pull-forward call
        // below honors, and what gets uploaded back so the next device to
        // sync learns about it too.
        final cloudTombstones = _SyncTombstones.fromJson((cloud['tombstones'] as Map<String, dynamic>?) ?? const {});
        final newTombstones = _detectNewTombstones(local, snapshot);
        final tombstones = _SyncTombstones.union(
          cloudTombstones,
          newTombstones,
        ).prunedOlderThan(_tombstoneRetention);
        final pulled = {
          'exportFormatVersion': _exportFormatVersion,
          'exportedAt': DateTime.now().toIso8601String(),
          'userProfile': _mergeUserProfile(local['userProfile'], cloud['userProfile']),
          'gems': _mergeGems(local['gems'], cloud['gems']),
          'customSets': _pullForwardCustomSets(local['customSets'], cloud['customSets'], snapshot, tombstones),
          'setOverrides': _pullForwardSetOverrides(local['setOverrides'], cloud['setOverrides'], snapshot),
          'studyDecks': _pullForwardDecks(local['studyDecks'], cloud['studyDecks'], snapshot, tombstones),
          'readingTexts': _pullForwardReadingTexts(local['readingTexts'], cloud['readingTexts'], snapshot, tombstones),
          'tombstones': tombstones.toJson(),
        };
        const encoder = JsonEncoder.withIndent('  ');
        finalJson = encoder.convert(pulled);
      }
    } catch (_) {
      // Unreadable cloud data - fall back to overriding with local as-is.
    }
  }

  await _saveSyncSnapshot(_snapshotFromExport(jsonDecode(finalJson) as Map<String, dynamic>));
  return finalJson;
}

// Serializes concurrent syncToCloud calls rather than letting them race -
// two overlapping syncs (a double-tap on the sync button, or two sync
// surfaces like the app and the Mini companion both triggering around the
// same moment, since they share the same local storage) would otherwise both
// read "previous" state, both compute their own pulled-forward result, and
// whichever uploads/saves last would silently clobber the other's work.
Future<void>? _syncInFlight;

Future<void> syncToCloud() async {
  final existing = _syncInFlight;
  if (existing != null) return existing;

  final future = _doSyncToCloud();
  _syncInFlight = future;
  try {
    await future;
  } finally {
    _syncInFlight = null;
  }
}

Future<void> _doSyncToCloud() async {
  final localJson = await buildExportJson();
  final cloudJson = await CloudSyncService.downloadBackup();
  final finalJson = await computeSyncUpload(localJson, cloudJson);
  await _applySyncedLocally(finalJson, localJson);
  await CloudSyncService.uploadBackup(finalJson);
}

// applyImportedJson resets and re-saves the ENTIRE ~27,000-item/~5MB shipped
// dictionary to disk every time it runs, which is the right thing for an
// explicit "Download from cloud" restore but pointlessly expensive for an
// ordinary sync: computeSyncUpload's customSets/setOverrides only ever
// differ from what's already on this device when something was genuinely
// pulled forward from elsewhere (rare - nobody but this device usually edits
// the dictionary), so in the overwhelmingly common case there's nothing to
// re-apply there at all. This compares the two and only pays for the full
// dictionary reset when it's actually necessary, instead of on every single
// sync regardless - that redundant work was what made Sync feel stuck/slow.
Future<void> _applySyncedLocally(String finalJson, String localJson) async {
  Map<String, dynamic> finalData;
  Map<String, dynamic> localData;
  try {
    finalData = jsonDecode(finalJson) as Map<String, dynamic>;
    localData = jsonDecode(localJson) as Map<String, dynamic>;
  } catch (_) {
    await applyImportedJson(finalJson);
    return;
  }

  final dictionaryChanged =
      jsonEncode(finalData['customSets']) != jsonEncode(localData['customSets']) ||
      jsonEncode(finalData['setOverrides']) != jsonEncode(localData['setOverrides']);

  if (dictionaryChanged) {
    await applyImportedJson(finalJson);
    return;
  }

  // Fast path: only profile/gems/decks/reading texts can have changed - the
  // dictionary already matches, so skip touching it entirely.
  final prefs = await SharedPreferences.getInstance();

  if (finalData.containsKey('userProfile')) {
    try {
      final up = finalData['userProfile'] as Map<String, dynamic>;
      await prefs.setInt('user_xp', (up['xp'] as num?)?.toInt() ?? 0);
      await prefs.setInt('user_level', (up['level'] as num?)?.toInt() ?? 0);
    } catch (_) {}
  }

  if (finalData.containsKey('gems')) {
    await prefs.setString('gem_data', jsonEncode(finalData['gems']));
  }

  if (finalData.containsKey('studyDecks')) {
    try {
      final decks = (finalData['studyDecks'] as List<dynamic>)
          .map((d) => StudyDeck.fromMap(Map<String, dynamic>.from(d as Map)))
          .toList();
      await saveStudyDecks(decks);
    } catch (_) {}
  }

  if (finalData.containsKey('readingTexts')) {
    try {
      final texts = (finalData['readingTexts'] as List<dynamic>)
          .map((t) => ReadingText.fromMap(Map<String, dynamic>.from(t as Map)))
          .toList();
      await saveReadingTexts(texts);
    } catch (_) {}
  }
}
