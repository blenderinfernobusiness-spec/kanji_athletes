import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'sets_data.dart';

class SetPreferences {
    // Save all sets in setsData
    static Future<void> saveAllSets() async {
      for (final entry in setsData.entries) {
        await saveSet(entry.key, entry.value);
      }
    }
  static const String _setPrefix = 'set_';
  static const String _migrationVersionKey = 'sets_migration_version';
  static const int _currentMigrationVersion = 6; // Increment when structure changes

  // Clear old saved data if migration is needed
  static Future<void> checkMigration() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getInt(_migrationVersionKey) ?? 0;
    
    if (savedVersion < _currentMigrationVersion) {
      // Clear all old saved sets (including old practice_set_ and vocab_set_ prefixes)
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith('practice_set_') || key.startsWith('vocab_set_') || key.startsWith(_setPrefix)) {
          await prefs.remove(key);
        }
      }
      await prefs.setInt(_migrationVersionKey, _currentMigrationVersion);
      print('Migrated to version $_currentMigrationVersion - cleared old saved sets');
    }
  }

  // Save set configuration (unified method)
  static Future<void> saveSet(String setKey, ItemSet set) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'name': set.name,
      'tags': set.tags,
      'displayInDictionary': set.displayInDictionary,
      'setType': set.setType,
      'displayInWritingArcade': set.displayInWritingArcade,
      'displayInReadingArcade': set.displayInReadingArcade,
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
    await prefs.setString('$_setPrefix$setKey', jsonEncode(data));
  }

  // Deprecated: Use saveSet instead
  @Deprecated('Use saveSet instead')
  static Future<void> savePracticeSet(String setKey, ItemSet set) async {
    return saveSet(setKey, set);
  }

  // Deprecated: Use saveSet instead
  @Deprecated('Use saveSet instead')
  static Future<void> saveVocabularySet(String setKey, ItemSet set) async {
    return saveSet(setKey, set);
  }

  // Delete a set
  static Future<void> deleteSet(String setKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_setPrefix$setKey');
  }

  // Load all set configurations
  static Future<void> loadAllSets() async {
    final prefs = await SharedPreferences.getInstance();
    
    // First, load existing sets in setsData
    for (var entry in setsData.entries) {
      final key = entry.key;
      final set = entry.value;
      
      // Create a map of original items by character for lookup
      final Map<String, Item> originalItemsByChar = {};
      final List<Item> originalItemsByIndex = List.from(set.items);
      for (var item in set.items) {
        originalItemsByChar[item.japanese] = item;
      }
      
      // Try loading from new unified prefix, then fall back to old prefixes for backward compatibility
      String? savedData = prefs.getString('$_setPrefix$key');
      savedData ??= prefs.getString('practice_set_$key');
      savedData ??= prefs.getString('vocab_set_$key');
      
      if (savedData != null) {
        try {
          final data = jsonDecode(savedData) as Map<String, dynamic>;
          set.name = data['name'] as String? ?? set.name;
          set.tags = (data['tags'] as List<dynamic>?)?.cast<String>() ?? set.tags;
          set.displayInDictionary = data['displayInDictionary'] as bool? ?? set.displayInDictionary;
          set.setType = data['setType'] as String? ?? set.setType;
          set.displayInWritingArcade = data['displayInWritingArcade'] as bool? ?? set.displayInWritingArcade;
          set.displayInReadingArcade = data['displayInReadingArcade'] as bool? ?? set.displayInReadingArcade;
          
          // Load items if they exist
          if (data.containsKey('items')) {
            set.items.clear();
            final items = data['items'] as List<dynamic>;
            
            for (int i = 0; i < items.length; i++) {
              final itemData = items[i];
              final japanese = itemData['japanese'] as String;
              
              // Try to find matching original item by character first, then by index
              final originalItem = originalItemsByChar[japanese] ?? 
                  (i < originalItemsByIndex.length ? originalItemsByIndex[i] : null);
              
              set.items.add(Item(
                japanese: japanese,
                translation: itemData['translation'] as String,
                strokeOrder: itemData['strokeOrder'] as String? ?? originalItem?.strokeOrder ?? '',
                kanjiVGCode: itemData['kanjiVGCode'] as String? ?? originalItem?.kanjiVGCode,
                reading: itemData['reading'] as String? ?? originalItem?.reading ?? '',
                itemType: itemData['itemType'] as String? ?? originalItem?.itemType ?? (set.setType == 'Vocab' ? 'Vocab' : 'Kanji'),
                onYomi: itemData['onYomi'] as String? ?? originalItem?.onYomi ?? '',
                kunYomi: itemData['kunYomi'] as String? ?? originalItem?.kunYomi ?? '',
                naNori: itemData['naNori'] as String? ?? originalItem?.naNori ?? '',
                tags: (itemData['tags'] as List<dynamic>?)?.cast<String>() ?? originalItem?.tags ?? [],
                notes: itemData['notes'] as String? ?? originalItem?.notes ?? '',
                isStarred: itemData['isStarred'] as bool? ?? originalItem?.isStarred ?? false,
              ));
            }
          }
        } catch (e) {
          // If there's an error loading, just keep the default values
          print('Error loading set $key: $e');
        }
      }
    }
    
    // Second, load any additional saved sets that aren't in the initial setsData
    // (e.g., user-created or duplicated sets)
    final allKeys = prefs.getKeys();
    for (var key in allKeys) {
      if (key.startsWith(_setPrefix)) {
        final setKey = key.substring(_setPrefix.length);
        
        // Skip if this set is already in setsData
        if (setsData.containsKey(setKey)) continue;
        
        // Load the saved set data
        final savedData = prefs.getString(key);
        if (savedData != null) {
          try {
            final data = jsonDecode(savedData) as Map<String, dynamic>;
            
            // Create items list from saved data
            final items = <Item>[];
            if (data.containsKey('items')) {
              final itemsData = data['items'] as List<dynamic>;
              for (var itemData in itemsData) {
                items.add(Item(
                  japanese: itemData['japanese'] as String,
                  translation: itemData['translation'] as String,
                  strokeOrder: itemData['strokeOrder'] as String? ?? '',
                  kanjiVGCode: itemData['kanjiVGCode'] as String?,
                  reading: itemData['reading'] as String? ?? '',
                  itemType: itemData['itemType'] as String? ?? 'Kanji',
                  onYomi: itemData['onYomi'] as String? ?? '',
                  kunYomi: itemData['kunYomi'] as String? ?? '',
                  naNori: itemData['naNori'] as String? ?? '',
                  tags: (itemData['tags'] as List<dynamic>?)?.cast<String>() ?? [],
                  notes: itemData['notes'] as String? ?? '',
                  isStarred: itemData['isStarred'] as bool? ?? false,
                ));
              }
            }
            
            // Create the new set and add to setsData
            final newSet = ItemSet(
              name: data['name'] as String? ?? setKey,
              items: items,
              setType: data['setType'] as String? ?? 'Uncategorised',
              displayInDictionary: data['displayInDictionary'] as bool? ?? true,
              tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
              displayInWritingArcade: data['displayInWritingArcade'] as bool? ?? false,
              displayInReadingArcade: data['displayInReadingArcade'] as bool? ?? false,
            );
            
            setsData[setKey] = newSet;
          } catch (e) {
            print('Error loading additional set $setKey: $e');
          }
        }
      }
    }
  }
}
