import 'dart:convert';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'sets_data.dart';
import 'set_preferences.dart';
import 'study_data.dart';
import 'user_profile.dart';
import 'backup_data_legacy.dart';

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

  // Default-backed sets need persisting too now that they've been reset and
  // patched in memory, so the result survives an app restart - loadAllSets()
  // below only pulls in whatever's already saved to prefs, it doesn't
  // persist what's currently sitting in memory.
  for (final key in pristineDefaults.keys) {
    await SetPreferences.saveSet(key, setsData[key]!);
  }

  await SetPreferences.loadAllSets();
}
