const Map<String, String> _kanaSyllables = {
  'あ': 'a', 'い': 'i', 'う': 'u', 'え': 'e', 'お': 'o',
  'か': 'ka', 'き': 'ki', 'く': 'ku', 'け': 'ke', 'こ': 'ko',
  'さ': 'sa', 'し': 'shi', 'す': 'su', 'せ': 'se', 'そ': 'so',
  'た': 'ta', 'ち': 'chi', 'つ': 'tsu', 'て': 'te', 'と': 'to',
  'な': 'na', 'に': 'ni', 'ぬ': 'nu', 'ね': 'ne', 'の': 'no',
  'は': 'ha', 'ひ': 'hi', 'ふ': 'fu', 'へ': 'he', 'ほ': 'ho',
  'ま': 'ma', 'み': 'mi', 'む': 'mu', 'め': 'me', 'も': 'mo',
  'や': 'ya', 'ゆ': 'yu', 'よ': 'yo',
  'ら': 'ra', 'り': 'ri', 'る': 'ru', 'れ': 're', 'ろ': 'ro',
  'わ': 'wa', 'を': 'wo', 'ん': 'n', 'ゔ': 'vu',
  'が': 'ga', 'ぎ': 'gi', 'ぐ': 'gu', 'げ': 'ge', 'ご': 'go',
  'ざ': 'za', 'じ': 'ji', 'ず': 'zu', 'ぜ': 'ze', 'ぞ': 'zo',
  'だ': 'da', 'ぢ': 'ji', 'づ': 'zu', 'で': 'de', 'ど': 'do',
  'ば': 'ba', 'び': 'bi', 'ぶ': 'bu', 'べ': 'be', 'ぼ': 'bo',
  'ぱ': 'pa', 'ぴ': 'pi', 'ぷ': 'pu', 'ぺ': 'pe', 'ぽ': 'po',
  'ぁ': 'a', 'ぃ': 'i', 'ぅ': 'u', 'ぇ': 'e', 'ぉ': 'o',
};

const Map<String, String> _kanaCombinations = {
  'きゃ': 'kya', 'きゅ': 'kyu', 'きょ': 'kyo',
  'しゃ': 'sha', 'しゅ': 'shu', 'しょ': 'sho',
  'ちゃ': 'cha', 'ちゅ': 'chu', 'ちょ': 'cho',
  'にゃ': 'nya', 'にゅ': 'nyu', 'にょ': 'nyo',
  'ひゃ': 'hya', 'ひゅ': 'hyu', 'ひょ': 'hyo',
  'みゃ': 'mya', 'みゅ': 'myu', 'みょ': 'myo',
  'りゃ': 'rya', 'りゅ': 'ryu', 'りょ': 'ryo',
  'ぎゃ': 'gya', 'ぎゅ': 'gyu', 'ぎょ': 'gyo',
  'じゃ': 'ja', 'じゅ': 'ju', 'じょ': 'jo',
  'びゃ': 'bya', 'びゅ': 'byu', 'びょ': 'byo',
  'ぴゃ': 'pya', 'ぴゅ': 'pyu', 'ぴょ': 'pyo',
  'てぃ': 'ti', 'でぃ': 'di', 'ふぁ': 'fa', 'ふぃ': 'fi', 'ふぇ': 'fe', 'ふぉ': 'fo',
  'うぃ': 'wi', 'うぇ': 'we', 'うぉ': 'wo',
};

const String _vowels = 'aiueo';

// Hepburn-style romaji for hiragana/katakana text, for showing a word's
// pronunciation under it. Anything that isn't kana (kanji, punctuation) is
// passed through unchanged.
String kanaToRomaji(String text) {
  final src = String.fromCharCodes(
    text.runes.map((c) => c >= 0x30A1 && c <= 0x30F6 ? c - 0x60 : c),
  );
  final out = StringBuffer();
  var lastVowel = '';
  var i = 0;
  while (i < src.length) {
    final ch = src[i];

    if (ch == 'っ') {
      final next = _readSyllable(src, i + 1);
      if (next != null) {
        out.write(next.romaji.startsWith('ch') ? 't' : next.romaji[0]);
      }
      i++;
      continue;
    }

    if (ch == 'ー') {
      out.write(lastVowel);
      i++;
      continue;
    }

    final syllable = _readSyllable(src, i);
    if (syllable == null) {
      out.write(ch);
      i++;
      continue;
    }
    out.write(syllable.romaji);
    lastVowel = _lastVowelOf(syllable.romaji);
    i += syllable.length;
  }
  return out.toString();
}

_Syllable? _readSyllable(String s, int i) {
  if (i + 1 < s.length) {
    final combo = _kanaCombinations[s.substring(i, i + 2)];
    if (combo != null) return _Syllable(combo, 2);
  }
  if (i < s.length) {
    final single = _kanaSyllables[s[i]];
    if (single != null) return _Syllable(single, 1);
  }
  return null;
}

String _lastVowelOf(String romaji) {
  for (var i = romaji.length - 1; i >= 0; i--) {
    if (_vowels.contains(romaji[i])) return romaji[i];
  }
  return '';
}

class _Syllable {
  final String romaji;
  final int length;
  const _Syllable(this.romaji, this.length);
}
