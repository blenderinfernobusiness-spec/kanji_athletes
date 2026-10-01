// Generates assets/dictionary.json (bundled into the app itself) and a copy
// in chrome_extension/dictionary.json, from setsData as it exists right at
// program start - before anything has a chance to mutate an item's
// isStarred/notes/tags/etc. This is the one pristine snapshot of "what did
// this app ship with" used for two separate things:
//   - the app's own export: diffing a user's current setsData against this
//     to find what's actually been personalized, instead of re-serializing
//     the whole ~27,000-item dictionary into every backup.
//   - the Chrome extension's baseline dictionary, so it has something to
//     look words up against before anyone's even signed in.
//
// Re-run this whenever the dictionary changes (new words/kanji added,
// translations fixed, etc.) and re-zip the extension - see
// chrome_extension/README.md. Running it is safe at any time since it only
// ever reads setsData, never writes to it.
//
// Usage: dart run tool/generate_dictionary_json.dart
import 'dart:convert';
import 'dart:io';
import 'package:kanji_athletes/sets_data.dart';

void main() {
  final Map<String, dynamic> out = {};
  for (final entry in setsData.entries) {
    final set = entry.value;
    out[entry.key] = {
      'name': set.name,
      'setType': set.setType,
      'displayInDictionary': set.displayInDictionary,
      'tags': set.tags,
      'items': set.items
          .map((item) => {
                'japanese': item.japanese,
                'translation': item.translation,
                'reading': item.reading,
                'itemType': item.itemType,
                'onYomi': item.onYomi,
                'kunYomi': item.kunYomi,
                'naNori': item.naNori,
                'notes': item.notes,
                'tags': item.tags,
              })
          .toList(),
    };
  }

  final jsonString = jsonEncode(out);
  for (final path in ['assets/dictionary.json', 'chrome_extension/dictionary.json']) {
    File(path).writeAsStringSync(jsonString);
  }

  final itemCount = setsData.values.fold<int>(0, (sum, s) => sum + s.items.length);
  stdout.writeln('Wrote assets/dictionary.json and chrome_extension/dictionary.json: '
      '${setsData.length} sets, $itemCount items, '
      '${(jsonString.length / 1024).toStringAsFixed(0)} KB each');
}
