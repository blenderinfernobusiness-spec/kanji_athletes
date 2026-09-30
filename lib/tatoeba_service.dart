import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// A single Tatoeba example sentence for a word, kept together with its own
// contributor and license. Tatoeba's default license (CC BY 2.0 FR) permits
// commercial use but requires crediting each sentence's individual author,
// not just Tatoeba as a whole - so every sentence carries that attribution
// wherever it's shown or played, rather than a single blanket credit for
// the whole feature.
class TatoebaSentence {
  final int? id;
  final String text;
  // Tatoeba's own linked human English translation, when one exists.
  final String? translation;
  final String? username;
  final String? license;

  TatoebaSentence({
    this.id,
    required this.text,
    this.translation,
    this.username,
    this.license,
  });

  String? get sentenceUrl => id == null ? null : 'https://tatoeba.org/en/sentences/show/$id';

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'translation': translation,
    'username': username,
    'license': license,
  };

  factory TatoebaSentence.fromMap(Map<String, dynamic> map) => TatoebaSentence(
    id: (map['id'] as num?)?.toInt(),
    text: map['text'] as String? ?? '',
    translation: map['translation'] as String?,
    username: map['username'] as String?,
    license: map['license'] as String?,
  );
}

// A small set of explicit/inappropriate keywords, checked against both the
// Japanese sentence and its linked English translation. Tatoeba's own
// community "vulgar" tag (see _vulgarSentenceIds below) barely covers
// Japanese sentences at all - only a handful exist - and isn't reliably
// applied to sexual content specifically, so this keyword list is the real
// line of defense for a learner-facing app. Deliberately focused on clearly
// explicit content rather than mild profanity, to avoid over-blocking
// ordinary sentences.
const List<String> _blockedKeywords = [
  'masturbat', 'orgasm', 'ejaculat', 'penis', 'vagina', 'porn', 'fetish',
  'furry', 'furries', 'bestiality', 'incest', 'pedophil', 'rape', 'nude',
  'naked', 'boob', 'nipple', 'genital', 'erotic', 'horny', 'fuck', 'blowjob',
  'cock', 'pussy', 'kinky', 'bdsm',
];

bool _isFlagged(String? id, String text, String? translation, Set<int> vulgarIds) {
  final parsedId = int.tryParse(id ?? '');
  if (parsedId != null && vulgarIds.contains(parsedId)) return true;
  final haystack = '$text ${translation ?? ''}'.toLowerCase();
  return _blockedKeywords.any(haystack.contains);
}

const String _vulgarIdsCachePrefsKey = 'tatoeba_vulgar_ids_cache';

// The (very short) list of Japanese sentence IDs carrying Tatoeba's
// community-applied "vulgar" tag - fetched once and cached indefinitely,
// since this changes rarely and there are only a handful of them at all.
// A failed fetch just yields an empty set rather than throwing - the
// keyword blocklist above is the real safety net regardless.
Future<Set<int>> _vulgarSentenceIds() async {
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getStringList(_vulgarIdsCachePrefsKey);
  if (cached != null) return cached.map(int.parse).toSet();

  final ids = <int>{};
  try {
    final uri = Uri.parse('https://tatoeba.org/en/api_v0/search?from=jpn&tags=vulgar&limit=100');
    final response = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final results = decoded['results'] as List? ?? [];
      for (final r in results) {
        final id = (r as Map<String, dynamic>)['id'];
        if (id is num) ids.add(id.toInt());
      }
    }
  } catch (_) {
    // Leave ids empty - see doc comment above.
  }
  await prefs.setStringList(_vulgarIdsCachePrefsKey, ids.map((e) => e.toString()).toList());
  return ids;
}

const String _cachePrefsKey = 'listening_tatoeba_cache';

Future<Map<String, dynamic>> _loadCacheRaw() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_cachePrefsKey);
  if (raw == null) return {};
  try {
    return jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
}

Future<void> _saveCacheRaw(Map<String, dynamic> data) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_cachePrefsKey, jsonEncode(data));
}

Future<List<TatoebaSentence>?> _getCached(String word) async {
  final data = await _loadCacheRaw();
  final list = data[word] as List?;
  if (list == null) return null;
  return list.map((e) => TatoebaSentence.fromMap(Map<String, dynamic>.from(e as Map))).toList();
}

Future<void> _putCache(String word, List<TatoebaSentence> sentences) async {
  final data = await _loadCacheRaw();
  data[word] = sentences.map((s) => s.toMap()).toList();
  await _saveCacheRaw(data);
}

// Fetches example sentences containing [word] from Tatoeba's public search
// API (Japanese only - this app has no other source language), each with
// its own linked English translation (when one exists) and its
// contributor's username for per-sentence attribution.
Future<List<TatoebaSentence>> _fetchTatoebaSentences(String word) async {
  try {
    final uri = Uri.parse(
      'https://tatoeba.org/en/api_v0/search?from=jpn&query=${Uri.encodeComponent(word)}&limit=30',
    );
    final response = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return [];
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final results = decoded['results'] as List?;
    if (results == null || results.isEmpty) return [];

    final entries = <TatoebaSentence>[];
    final seen = <String>{};
    for (final r in results) {
      final map = r as Map<String, dynamic>;
      final text = (map['text'] as String? ?? '').trim();
      if (text.isEmpty || !seen.add(text)) continue;

      String? translation;
      final translationGroups = map['translations'] as List?;
      if (translationGroups != null) {
        outer:
        for (final group in translationGroups) {
          if (group is! List) continue;
          for (final t in group) {
            final tm = t as Map<String, dynamic>;
            if (tm['lang'] == 'eng') {
              final tText = (tm['text'] as String? ?? '').trim();
              if (tText.isNotEmpty) {
                translation = tText;
                break outer;
              }
            }
          }
        }
      }

      entries.add(TatoebaSentence(
        id: (map['id'] as num?)?.toInt(),
        text: text,
        translation: translation,
        username: (map['user'] as Map<String, dynamic>?)?['username'] as String?,
        license: map['license'] as String?,
      ));
    }

    final vulgarIds = await _vulgarSentenceIds();
    entries.removeWhere((e) => _isFlagged(e.id?.toString(), e.text, e.translation, vulgarIds));

    final lowerWord = word.toLowerCase();
    final matching = entries.where((e) => e.text.toLowerCase().contains(lowerWord)).toList();
    final pool = matching.isNotEmpty ? matching : entries;
    pool.shuffle();
    return pool.take(10).toList();
  } catch (_) {
    return [];
  }
}

// Cache-aware wrapper - reuses a previous fetch for [word] across sessions
// instead of hitting Tatoeba again every time a deck is studied.
Future<List<TatoebaSentence>> getTatoebaSentencesFor(String word) async {
  final trimmed = word.trim();
  if (trimmed.isEmpty) return [];
  final cached = await _getCached(trimmed);
  if (cached != null) return cached;
  final fresh = await _fetchTatoebaSentences(trimmed);
  if (fresh.isNotEmpty) await _putCache(trimmed, fresh);
  return fresh;
}
