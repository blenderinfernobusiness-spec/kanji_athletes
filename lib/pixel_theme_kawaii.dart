import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'pixel_sprites.dart';
import 'pixel_icons_base.dart';

// The "Kawaii" pixel-art theme - pastel candy colours, a soft plum outline,
// faces stamped on a few icons, and little hearts scattered over most of
// them. Reuses the exact same icon draw functions as Dungeon
// (pixel_icons_base.dart) - only the material palette and this theme's own
// decoration pass differ, since every draw function refers to materials by
// name rather than hardcoded colours.
final PixelTheme kKawaiiTheme = PixelTheme(
  id: 'kawaii',
  name: 'Kawaii',
  palette: kBasePalette.withOverrides(
    {
      'wood': const SpriteMaterial(Color(0xFFC9875F), Color(0xFFE6A97E), Color(0xFFF7CFA6)),
      'woodDark': const SpriteMaterial(Color(0xFF9B6A55), Color(0xFFB98270), Color(0xFFD49E8A)),
      'stone': const SpriteMaterial(Color(0xFFA99BC4), Color(0xFFC8BCE0), Color(0xFFE6DCF6)),
      'stoneDark': const SpriteMaterial(Color(0xFF8A7AA8), Color(0xFFA294C0), Color(0xFFBBAED6)),
      'gold': const SpriteMaterial(Color(0xFFE8A84A), Color(0xFFFFD166), Color(0xFFFFF0A8)),
      'iron': const SpriteMaterial(Color(0xFF9FB0C8), Color(0xFFC6D4E6), Color(0xFFEEF4FB)),
      'purple': const SpriteMaterial(Color(0xFFD0559A), Color(0xFFFF7FBF), Color(0xFFFFC2E2)),
      'amethyst': const SpriteMaterial(Color(0xFF9A6AD8), Color(0xFFC39BFF), Color(0xFFEAD9FF)),
      'red': const SpriteMaterial(Color(0xFFE0607E), Color(0xFFFF8FA8), Color(0xFFFFC4D2)),
      'green': const SpriteMaterial(Color(0xFF5FB98A), Color(0xFF8EE0AC), Color(0xFFC4F5D4)),
      'dirt': const SpriteMaterial(Color(0xFFB98A6A), Color(0xFFD6A888), Color(0xFFECCAAE)),
      'blue': const SpriteMaterial(Color(0xFF6A9AE0), Color(0xFF9CC4FF), Color(0xFFD0E6FF)),
      'sky': const SpriteMaterial(Color(0xFF9CC4FF), Color(0xFFC4DCFF), Color(0xFFE6F0FF)),
      'ink': const SpriteMaterial(Color(0xFF5A3A5E), Color(0xFF6E4A72), Color(0xFF8A6490)),
      'leather': const SpriteMaterial(Color(0xFFC47A6A), Color(0xFFE09A88), Color(0xFFF4C0B0)),
      'fur': const SpriteMaterial(Color(0xFFD79A6A), Color(0xFFF0BD8C), Color(0xFFFFE0BC)),
      'teal': const SpriteMaterial(Color(0xFF5AC0B0), Color(0xFF8EE6D6), Color(0xFFC8FBF2)),
      'parchment': const SpriteMaterial(Color(0xFFE8C8A8), Color(0xFFFFE6CC), Color(0xFFFFF6EA)),
      'orange': const SpriteMaterial(Color(0xFFFF8A6A), Color(0xFFFFB38A), Color(0xFFFFDCB8)),
      'bone': const SpriteMaterial(Color(0xFFD8C8D8), Color(0xFFF2E6F2), Color(0xFFFFFAFF)),
    },
    outline: const Color(0xFF5A3A5E),
  ),
  forcedDarkMode: false,
  icons: {
    'library': const SpriteIconDef(baseWidth: 32, draw: library),
    'study': const SpriteIconDef(baseWidth: 32, draw: study),
    'itembox': const SpriteIconDef(baseWidth: 32, draw: itembox),
    'dictComplete': const SpriteIconDef(baseWidth: 32, draw: dictComplete),
    'dictKanji': const SpriteIconDef(baseWidth: 32, draw: dictKanji),
    'dictVocab': const SpriteIconDef(baseWidth: 32, draw: dictVocab),
    'level': const SpriteIconDef(baseWidth: 32, draw: level),
    'gem': const SpriteIconDef(baseWidth: 32, draw: gem),
    'stats': const SpriteIconDef(baseWidth: 32, draw: stats),
    'settings': const SpriteIconDef(baseWidth: 32, draw: settings),
    'tabCards': const SpriteIconDef(baseWidth: 32, draw: tabCards),
    'tabReading': const SpriteIconDef(baseWidth: 32, draw: tabReading),
    'tabLessons': const SpriteIconDef(baseWidth: 32, draw: tabLessons),
    'addDeck': const SpriteIconDef(baseWidth: 32, draw: addDeck),
    'deckGrammar': const SpriteIconDef(baseWidth: 32, draw: deckGrammar),
    'deckKana': const SpriteIconDef(baseWidth: 32, draw: deckKana),
    'deckKanji': const SpriteIconDef(baseWidth: 32, draw: deckKanji),
    'deckMistakes': const SpriteIconDef(baseWidth: 32, draw: deckMistakes),
    'runeKana': const SpriteIconDef(baseWidth: 16, draw: runeKana),
    'bookVocab': const SpriteIconDef(baseWidth: 16, draw: bookVocab),
    'oreCoal': SpriteIconDef(baseWidth: 16, draw: oreDraw('ink')),
    'oreIron': SpriteIconDef(baseWidth: 16, draw: oreDraw('iron')),
    'oreGold': SpriteIconDef(baseWidth: 16, draw: oreDraw('gold')),
    'oreAmethyst': SpriteIconDef(baseWidth: 16, draw: oreDraw('amethyst')),
    'torch': const SpriteIconDef(baseWidth: 16, draw: torch),
    'quill': const SpriteIconDef(baseWidth: 16, draw: quill),
    'brush': const SpriteIconDef(baseWidth: 16, draw: brush),
    'bell': const SpriteIconDef(baseWidth: 32, draw: bell),
    'flag': const SpriteIconDef(baseWidth: 32, draw: flag),
    'undo': const SpriteIconDef(baseWidth: 16, draw: undo),
    'back': const SpriteIconDef(baseWidth: 16, draw: back),
    'frame': const SpriteIconDef(baseWidth: 24, draw: frame),
    'skull': const SpriteIconDef(baseWidth: 32, draw: skull),
    'shield': const SpriteIconDef(baseWidth: 32, draw: shield),
    'sword': const SpriteIconDef(baseWidth: 32, draw: sword),
    'crown': const SpriteIconDef(baseWidth: 32, draw: crown),
  },
  deco: _kawaiiDeco,
);

// Which icons get a little stamped face (cute eyes + blush + smile), and
// where on the sprite it's centred - matches the kit's own FACES map.
const Map<String, List<double>> _kawaiiFaces = {
  'itembox': [16, 22.4, 1],
  'gem': [16, 15, 1],
  'bell': [16, 17.6, 0.9],
};

void _kawaiiDeco(SpriteDrawer d, String iconId, int seed) {
  final f = _kawaiiFaces[iconId];
  if (f != null) _face(d, f[0], f[1], f[2]);
  d.sprinkle(seed, d.bw > 16 ? 2 : 1, 2.6, (x, y) => _tinyHeart(d, x, y));
}

// A simple pair of blinking eyes, blush and a smile - ported from the
// kit's own face(d,cx,cy,s) helper.
void _face(SpriteDrawer d, double cx, double cy, double s) {
  for (final sg in [-1, 1]) {
    final ex = cx + sg * 2.8 * s;
    d.ell(ex, cy, 0.95 * s, 1.3 * s, 'ink', 2);
    d.rect(ex - 0.55 * s, cy - 0.95 * s, 0.6 * s, 0.6 * s, 'paper', 3);
    d.ell(cx + sg * 5 * s, cy + 1.9 * s, 1.3 * s, 0.7 * s, 'red', 3);
  }
  d.line([
    [cx - 1.2 * s, cy + 1.3 * s],
    [cx - 0.6 * s, cy + 2 * s],
    [cx, cy + 1.4 * s],
    [cx + 0.6 * s, cy + 2 * s],
    [cx + 1.2 * s, cy + 1.3 * s],
  ], 0.36 * s, 'ink', 2);
}

// A tiny heart stamp, ported from the kit's own tinyHeart(d,x,y,m,s) helper.
void _tinyHeart(SpriteDrawer d, double x, double y, {String m = 'red', int s = 2}) {
  d.fn((px, py) {
    final a = (px - x) / 1.8, b = (y - py) / 1.8 + 0.15;
    return math.pow(a * a + b * b - 1, 3) - a * a * b * b * b <= 0;
  }, m, s);
}
