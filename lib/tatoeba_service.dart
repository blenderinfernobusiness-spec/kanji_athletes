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

// Our own Cloud Function proxy, not Tatoeba's API directly - the web build
// can't call Tatoeba itself (it sends no Access-Control-Allow-Origin header,
// so browsers block reading the response; confirmed via a manual check).
// The proxy also owns the vulgar-tag + keyword filtering that used to live
// here, and shares one Firestore-cached result per word across every
// member instead of each device fetching/filtering independently. See
// functions/index.js.
const String _tatoebaProxyUrl = 'https://us-central1-kanji-athletes.cloudfunctions.net/tatoebaSentences';

Future<List<TatoebaSentence>> _fetchTatoebaSentences(String word) async {
  try {
    final uri = Uri.parse('$_tatoebaProxyUrl?word=${Uri.encodeComponent(word)}');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return [];
    final decoded = jsonDecode(response.body) as List;
    return decoded.map((e) => TatoebaSentence.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  } catch (_) {
    return [];
  }
}

// Cache-aware wrapper - reuses a previous fetch for [word] across sessions
// instead of hitting the proxy again every time a deck is studied.
Future<List<TatoebaSentence>> getTatoebaSentencesFor(String word) async {
  final trimmed = word.trim();
  if (trimmed.isEmpty) return [];
  final cached = await _getCached(trimmed);
  if (cached != null) return cached;
  final fresh = await _fetchTatoebaSentences(trimmed);
  if (fresh.isNotEmpty) await _putCache(trimmed, fresh);
  return fresh;
}
