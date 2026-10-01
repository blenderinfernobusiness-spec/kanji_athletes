// Frozen copy of the original (pre-lean) export/import implementation, kept
// around for two reasons: as a literal rollback point if the new
// overrides-based format in backup_data.dart ever needs abandoning, and as
// the active code path for reading old export files - any backup made
// before the format change has no 'exportFormatVersion' field and carries a
// full 'sets' map rather than 'customSets'/'setOverrides', so it still needs
// somewhere to be understood. Not used for new exports going forward.
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'sets_data.dart';
import 'set_preferences.dart';
import 'study_data.dart';
import 'user_profile.dart';

Future<String> buildExportJsonLegacy() async {
  await SetPreferences.loadAllSets();
  final prefs = await SharedPreferences.getInstance();

  final user = await UserProfile.load();
  final String? gemString = prefs.getString('gem_data');
  final dynamic gemData = gemString != null ? jsonDecode(gemString) : [];

  final studyDecks = await loadStudyDecks();
  final readingTexts = await loadReadingTexts();

  final Map<String, dynamic> setsMap = {};
  for (var entry in setsData.entries) {
    final key = entry.key;
    final set = entry.value;
    setsMap[key] = {
      'name': set.name,
      'tags': set.tags,
      'displayInDictionary': set.displayInDictionary,
      'setType': set.setType,
      'items': set.items.map((item) => {
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
          }).toList(),
    };
  }

  final export = {
    'exportedAt': DateTime.now().toIso8601String(),
    'userProfile': {'xp': user.xp, 'level': user.level},
    'gems': gemData,
    'sets': setsMap,
    'studyDecks': studyDecks.map((d) => d.toMap()).toList(),
    'readingTexts': readingTexts.map((t) => t.toMap()).toList(),
  };

  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(export);
}

Future<void> applyImportedJsonLegacy(String content) async {
  final data = jsonDecode(content) as Map<String, dynamic>;
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

  if (data.containsKey('sets')) {
    final sets = data['sets'] as Map<String, dynamic>;
    for (var entry in sets.entries) {
      final setKey = entry.key;
      try {
        final s = entry.value as Map<String, dynamic>;
        final items = <Item>[];
        if (s.containsKey('items')) {
          for (var it in (s['items'] as List<dynamic>)) {
            try {
              items.add(Item(
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
              ));
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

  await SetPreferences.loadAllSets();
}
