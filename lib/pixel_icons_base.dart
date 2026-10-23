import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'pixel_sprites.dart';

// Theme-agnostic icon draw functions, shared by every pixel theme - each
// one only refers to materials by name (see pixel_sprites.dart's
// SpritePalette), so the exact same instructions render completely
// differently under a different theme's palette. Ported from the kit
// artifact's base ICONS object.



Future<void> library(SpriteDrawer d, String? param) async {
  d.rect(3, 2, 26, 28, 'wood', 4);
  d.rect(5, 4, 22, 10, 'woodDark', 1);
  d.rect(5, 17, 22, 10, 'woodDark', 1);
  double shelf(double y0, List<List<Object>> bricks) {
    var x = 5.0;
    for (final b in bricks) {
      final w = (b[0] as num).toDouble(), h = (b[1] as num).toDouble(), m = b[2] as String;
      d.rect(x, y0 - h, w, h, m);
      d.rect(x, y0 - h + 2, w, 1, 'gold', 3);
      x += w;
    }
    return x;
  }

  final e = shelf(14, [
    [3, 9, 'red'],
    [2, 7, 'blue'],
    [3, 10, 'purple'],
    [2, 8, 'green'],
    [3, 9, 'leather'],
    [2, 7, 'teal'],
    [2, 10, 'gold'],
  ]);
  d.circ(e + 2.4, 11.5, 2.3, 'amethyst');
  d.rect(e + 1.7, 7.6, 1.4, 2, 'parchment');
  shelf(27, [
    [2, 8, 'blue'],
    [3, 10, 'red'],
    [3, 9, 'green'],
    [2, 10, 'purple'],
    [3, 8, 'leather'],
  ]);
  d.rect(18.5, 24.5, 8, 2.5, 'teal');
  d.rect(19.5, 22, 7, 2.5, 'red');
  d.rect(20, 20, 5.5, 2, 'gold');
  d.rect(3, 14, 26, 3, 'wood', 4);
  d.rect(3, 27, 26, 3, 'wood', 4);
}

Future<void> study(SpriteDrawer d, String? param) async {
  d.poly([
    [2, 11],
    [16, 13],
    [30, 11],
    [30, 27],
    [16, 29.5],
    [2, 27],
  ], 'purple');
  d.poly([
    [3, 8.5],
    [15, 10.5],
    [15, 27],
    [3, 25],
  ], 'parchment');
  d.poly([
    [29, 8.5],
    [17, 10.5],
    [17, 27],
    [29, 25],
  ], 'parchment');
  d.rect(15, 10.5, 2, 17, 'parchment', 1);
  for (var i = 0; i < 4; i++) {
    d.line([
      [5.5, 13.5 + i * 3],
      [12.5, 14.8 + i * 3],
    ], 0.6, 'ink', 3);
    d.line([
      [19.5, 14.8 + i * 3],
      [26.5, 13.5 + i * 3],
    ], 0.6, 'ink', 3);
  }
  d.rect(21, 24, 2, 6.5, 'red');
  d.clear((x, y) => y > 29.4 && (x - 22).abs() < 0.6);
  d.rect(16, 1, 1, 5, 'amethyst', 3);
  d.rect(14, 3, 5, 1, 'amethyst', 3);
  d.rect(7, 4, 1.4, 1.4, 'amethyst', 3);
  d.rect(25, 3, 1.4, 1.4, 'amethyst', 3);
}

Future<void> itembox(SpriteDrawer d, String? param) async {
  d.rect(3, 13, 26, 15, 'wood', 4);
  d.rect(3, 8.6, 26, 4.4, 'wood', 4);
  d.ell(16, 8.8, 13, 3.6, 'wood', 4, (x, y) => y < 8.8);
  d.rect(3, 12.5, 26, 1.4, 'woodDark', 1);
  d.rect(5, 7, 2.5, 21, 'iron');
  d.rect(24.5, 7, 2.5, 21, 'iron');
  d.rect(12.5, 10, 7, 8, 'gold');
  d.poly([
    [16, 11],
    [18.4, 13.8],
    [16, 16.6],
    [13.6, 13.8],
  ], 'amethyst');
  d.rect(15.5, 16.8, 1, 1, 'ink', 2);
  d.rect(28, 3, 1.4, 1.4, 'amethyst', 3);
  d.rect(2, 4, 1.4, 1.4, 'amethyst', 3);
  d.rect(29.5, 5.5, 1, 1, 'amethyst', 3);
}

Future<void> dictComplete(SpriteDrawer d, String? param) async {
  d.rect(24, 5, 4.5, 23, 'paper');
  for (var i = 0; i < 7; i++) {
    d.rect(26, 7 + i * 3, 2.5, 0.7, 'paper', 1);
  }
  d.rect(5, 3, 21, 26, 'purple');
  d.rect(5, 3, 3, 26, 'purple', 1);
  d.poly([
    [26, 3],
    [20.5, 3],
    [26, 8.5],
  ], 'gold');
  d.poly([
    [26, 29],
    [20.5, 29],
    [26, 23.5],
  ], 'gold');
  d.rect(10, 7, 13, 15, 'parchment');
  await d.glyph('辞', 16.5, 14.6, 11, 'ink', 2);
  d.rect(10, 24.5, 13, 1.2, 'gold', 3);
}

Future<void> dictKanji(SpriteDrawer d, String? param) async {
  d.rect(2, 28, 28, 3, 'stoneDark', 4);
  d.rect(5, 10, 22, 18, 'stone', 4);
  d.ell(16, 10.5, 11, 6.5, 'stone', 4, (x, y) => y < 10.5);
  await d.glyph('漢', 16, 17.5, 15, 'stoneDark', 1);
  d.line([
    [22.5, 22],
    [24, 24.5],
    [23, 27],
  ], 0.5, 'stoneDark', 1);
  d.rect(5, 24.5, 3, 3.5, 'green', 4);
  d.rect(8, 26.5, 3, 1.5, 'green', 3);
  d.ell(22, 4.6, 3, 1.4, 'green', 0, (x, y) => y < 5.2);
}

Future<void> dictVocab(SpriteDrawer d, String? param) async {
  d.rect(8, 5, 16, 22, 'parchment');
  d.rect(5, 3, 22, 3, 'wood');
  d.circ(4.5, 4.5, 2, 'gold');
  d.circ(27.5, 4.5, 2, 'gold');
  d.rect(5, 26, 22, 3, 'wood');
  d.circ(4.5, 27.5, 2, 'gold');
  d.circ(27.5, 27.5, 2, 'gold');
  await d.glyph('単', 16, 14.6, 12, 'ink', 2);
  d.circ(20.5, 22.5, 2.2, 'red');
  d.rect(19.8, 21.6, 1, 1, 'red', 3);
}

Future<void> level(SpriteDrawer d, String? param) async {
  d.poly([
    [4, 3],
    [28, 3],
    [28, 15],
    [16, 29],
    [4, 15],
  ], 'gold');
  d.poly([
    [7, 6],
    [25, 6],
    [25, 14.5],
    [16, 25.5],
    [7, 14.5],
  ], 'purple');
  await d.glyph(param ?? '1', 16, 14.2, 13, 'paper', 3, weight: FontWeight.w900);
}

Future<void> gem(SpriteDrawer d, String? param) async {
  d.poly([
    [10, 4],
    [22, 4],
    [28, 11],
    [16, 29],
    [4, 11],
  ], 'amethyst');
  d.poly([
    [10, 4],
    [22, 4],
    [19, 11],
    [13, 11],
  ], 'amethyst', 3);
  d.poly([
    [19, 11],
    [28, 11],
    [16, 29],
  ], 'amethyst', 1);
  d.rect(12, 6, 2, 1, 'paper', 3);
  d.rect(4, 3, 1, 1, 'amethyst', 3);
  d.rect(27, 2, 1.4, 1.4, 'amethyst', 3);
}

Future<void> stats(SpriteDrawer d, String? param) async {
  d.rect(2, 28, 28, 2.5, 'stoneDark', 4);
  d.rect(4, 19, 7, 9, 'dirt', 4);
  d.rect(4, 19, 7, 2.6, 'green', 4);
  d.rect(12.5, 12, 7, 16, 'stone', 4);
  d.rect(21, 10, 7, 18, 'amethyst', 4);
  d.poly([
    [21.5, 10],
    [23.5, 3],
    [25.2, 10],
  ], 'amethyst', 3);
  d.poly([
    [25, 10],
    [27, 5.5],
    [28, 10],
  ], 'amethyst', 2);
}

Future<void> settings(SpriteDrawer d, String? param) async {
  d.fn((x, y) {
    final dx = x - 16, dy = y - 16;
    final r = math.sqrt(dx * dx + dy * dy);
    final a = math.atan2(dy, dx);
    return r <= (math.cos(a * 8) > 0.25 ? 13.5 : 10.5) && r >= 4.4;
  }, 'iron');
  d.circ(16, 16, 2.7, 'amethyst');
}

Future<void> tabCards(SpriteDrawer d, String? param) async {
  d.rect(12, 3, 16, 20, 'parchment');
  d.rect(8, 6, 16, 20, 'paper');
  await d.glyph('?', 21.2, 10, 7, 'purple', 2);
  d.rect(4, 9.5, 16, 20, 'parchment');
  d.poly([
    [4, 9.5],
    [9, 9.5],
    [4, 14.5],
  ], 'purple');
  await d.glyph('あ', 12, 19.8, 11, 'ink', 2);
}

Future<void> tabReading(SpriteDrawer d, String? param) async {
  d.circ(16, 4.4, 2.4, 'iron');
  d.clear(circleTest(16, 4.4, 1.1));
  d.poly([
    [8.5, 11],
    [23.5, 11],
    [16, 6],
  ], 'iron');
  d.rect(9, 11, 14, 15, 'iron');
  d.rect(11, 13, 10, 11, 'gold', 3);
  d.ell(16, 19.4, 2.4, 3.6, 'orange');
  d.ell(16, 20.4, 1, 1.6, 'paper', 3);
  d.rect(8, 26, 16, 3, 'iron');
}

Future<void> tabLessons(SpriteDrawer d, String? param) async {
  d.rect(6, 22, 3, 8, 'wood', 4);
  d.rect(23, 22, 3, 8, 'wood', 4);
  d.rect(3, 4, 26, 19, 'wood', 4);
  d.rect(5, 6, 22, 15, 'woodDark', 4);
  d.rect(7, 8, 8, 10, 'parchment');
  d.rect(17, 7, 9, 7, 'paper');
  d.rect(16, 15.5, 9, 4.5, 'parchment');
  for (final r in [
    [8.5, 11.0, 5.0],
    [8.5, 13.0, 4.0],
    [8.5, 15.0, 5.0],
    [18.5, 10.0, 6.0],
    [18.5, 12.0, 4.0],
    [17.5, 17.5, 6.0],
  ]) {
    d.rect(r[0], r[1], r[2], 0.8, 'ink', 3);
  }
  d.circ(11, 8.6, 1, 'red');
  d.circ(21.5, 7.6, 1, 'purple');
  d.circ(20.5, 16.2, 0.9, 'gold');
}

Future<void> addDeck(SpriteDrawer d, String? param) async {
  d.rect(4, 4, 24, 24, 'wood', 4);
  d.rect(4, 4, 24, 3, 'woodDark', 4);
  d.rect(4, 25, 24, 3, 'woodDark', 4);
  d.rect(4, 4, 3, 24, 'woodDark', 4);
  d.rect(25, 4, 3, 24, 'woodDark', 4);
  d.rect(14, 9, 4, 14, 'purple');
  d.rect(9, 14, 14, 4, 'purple');
}

Future<void> deckGrammar(SpriteDrawer d, String? param) async {
  d.poly([
    [6, 5.5],
    [26, 5.5],
    [26, 28],
    [16, 23],
    [6, 28],
  ], 'purple');
  d.line([
    [8, 8],
    [24, 8],
  ], 0.5, 'gold', 3);
  d.line([
    [8, 20],
    [24, 20],
  ], 0.5, 'gold', 1);
  d.rect(4, 3, 24, 2.6, 'wood', 4);
  d.circ(4, 4.3, 1.6, 'gold');
  d.circ(28, 4.3, 1.6, 'gold');
  await d.glyph(param ?? 'N5', 16, 14, 10, 'gold', 3, weight: FontWeight.w900);
}

const List<int> grassHeights = [0, 1, 0, 2, 1, 0, 0, 2, 1, 0, 1, 3, 0, 1, 0, 2, 0, 1, 2, 0, 1, 0, 2, 1, 0, 1, 0];

Future<void> deckKana(SpriteDrawer d, String? param) async {
  d.rect(3, 3, 26, 26, 'dirt', 4);
  d.fn((x, y) {
    if (x < 3 || x >= 29 || y < 3) return false;
    final idx = x.floor() - 3;
    if (idx < 0 || idx >= grassHeights.length) return false;
    return y < 9 + grassHeights[idx];
  }, 'green', 4);
  await d.glyph(param ?? 'あ', 16, 19.2, 13, 'parchment', 3);
}

Future<void> deckKanji(SpriteDrawer d, String? param) async {
  d.rect(2, 2, 28, 28, 'stone', 4);
  for (final row in [
    [8.0, 0.0],
    [14.0, 3.0],
    [20.0, 0.0],
    [26.0, 3.0],
  ]) {
    final y = row[0], o = row[1];
    d.rect(2, y, 28, 0.8, 'stoneDark', 2);
    for (var x = 2 + o; x < 30; x += 6) {
      d.rect(x, y - 6 + 0.8, 0.8, 5.2, 'stoneDark', 2);
    }
  }
  d.ell(16, 13.5, 7, 4.5, 'wood', 4, (x, y) => y < 13.5);
  d.rect(9, 13.5, 14, 16.5, 'wood', 4);
  d.rect(13.4, 9.5, 0.8, 20.5, 'wood', 1);
  d.rect(17.8, 9.5, 0.8, 20.5, 'wood', 1);
  d.rect(9, 16, 14, 1.5, 'iron');
  d.rect(9, 24, 14, 1.5, 'iron');
  d.circ(20.5, 20.5, 1, 'gold');
  for (final x in [4.8, 27.2]) {
    d.rect(x - 0.8, 17, 1.6, 5, 'wood');
    d.ell(x, 15, 1.6, 2.4, 'orange');
    d.ell(x, 15.6, 0.7, 1, 'gold', 3);
  }
  d.rect(10, 2.8, 12, 5.4, 'gold');
  await d.glyph(param ?? '90', 16, 5.6, 6, 'ink', 2, weight: FontWeight.w900);
}

Future<void> deckMistakes(SpriteDrawer d, String? param) async {
  d.fn((x, y) {
    final a = (x - 16) / 11, b = (16.5 - y) / 11;
    return math.pow(a * a + b * b - 1, 3) - a * a * b * b * b <= 0;
  }, 'red');
  d.clear(capsuleTest([
    [16, 6],
    [13.5, 11.5],
    [18, 16],
    [14.5, 21],
    [16, 27],
  ], 0.7));
  d.rect(7, 8, 2, 2, 'red', 3);
  d.rect(9, 7, 2, 1, 'red', 3);
}

Future<void> runeKana(SpriteDrawer d, String? param) async {
  d.rect(1, 1, 14, 14, 'stone', 4);
  await d.glyph(param ?? 'あ', 8, 8.3, 10, 'amethyst', 3);
}

Future<void> bookVocab(SpriteDrawer d, String? param) async {
  d.rect(11, 3, 3, 10.5, 'paper');
  d.rect(2.5, 2, 10, 12, 'blue');
  d.rect(2.5, 2, 2, 12, 'blue', 1);
  d.rect(6, 5, 4, 2, 'gold', 3);
}

// The four ore tiers (new -> mastered) share one shape, just recoloured -
// matches the kit's own oreDraw(m) helper.
Future<void> Function(SpriteDrawer, String?) oreDraw(String material) {
  return (d, param) async {
    d.rect(1, 1, 14, 14, 'stone', 4);
    for (final spot in [
      [3.0, 3.0],
      [9.0, 2.5],
      [11.0, 8.0],
      [4.0, 9.5],
      [7.5, 12.0],
    ]) {
      final x = spot[0], y = spot[1];
      d.rect(x, y, 2, 2, material, 2);
      d.rect(x, y, 1, 1, material, 3);
      d.rect(x + 1, y + 1, 1, 1, material, 1);
    }
  };
}

Future<void> torch(SpriteDrawer d, String? param) async {
  d.rect(7, 7, 2, 8, 'wood');
  d.ell(8, 5, 2.2, 3, 'orange');
  d.ell(8, 5.6, 1, 1.4, 'gold', 3);
}

Future<void> quill(SpriteDrawer d, String? param) async {
  d.poly([
    [14.5, 1],
    [15, 3],
    [9, 10],
    [6.2, 9.8],
    [7, 7],
  ], 'paper');
  d.line([
    [14, 2.2],
    [6.5, 10],
  ], 0.45, 'purple', 2);
  d.line([
    [6.5, 9.8],
    [2.5, 14],
  ], 0.7, 'ink', 2);
}

Future<void> brush(SpriteDrawer d, String? param) async {
  d.line([
    [14, 2],
    [7.5, 8.5],
  ], 1.1, 'gold');
  d.line([
    [8.4, 7.6],
    [6.6, 9.4],
  ], 1.25, 'iron');
  d.poly([
    [6.2, 8.2],
    [8.2, 10.2],
    [4.5, 14.5],
    [1.5, 15],
    [2, 12.5],
  ], 'ink');
}

Future<void> bell(SpriteDrawer d, String? param) async {
  d.circ(16, 4.4, 2, 'gold');
  d.clear(circleTest(16, 4.4, 0.9));
  d.ell(16, 13, 7, 7.5, 'gold', 0, (x, y) => y < 13);
  d.poly([
    [9, 13],
    [23, 13],
    [25, 22],
    [27.5, 25.5],
    [4.5, 25.5],
    [7, 22],
  ], 'gold');
  d.rect(4.5, 24, 23, 1.5, 'gold', 1);
  d.circ(16, 27.2, 2.2, 'iron');
  d.fn((x, y) {
    final r = math.sqrt((x - 16) * (x - 16) + (y - 16) * (y - 16));
    return (x > 27 || x < 5) && r > 12.6 && r < 13.9 && (y - 15).abs() < 5.5;
  }, 'amethyst', 3);
}

Future<void> flag(SpriteDrawer d, String? param) async {
  d.poly([
    [8.2, 5],
    [27, 5],
    [23, 11],
    [27, 17],
    [8.2, 17],
  ], 'purple');
  d.poly([
    [15, 7.6],
    [17.6, 11],
    [15, 14.4],
    [12.4, 11],
  ], 'gold');
  d.rect(6, 3, 2.2, 27, 'wood');
  d.circ(7.1, 3, 1.6, 'gold');
}

Future<void> undo(SpriteDrawer d, String? param) async {
  d.fn((x, y) {
    final r = math.sqrt((x - 9) * (x - 9) + (y - 9.5) * (y - 9.5));
    return r >= 3.4 && r <= 5.6 && (x >= 8.5 || y >= 9.5);
  }, 'paper');
  d.poly([
    [9, 1.5],
    [9, 8.5],
    [4.5, 5],
  ], 'paper');
}

Future<void> back(SpriteDrawer d, String? param) async {
  d.rect(5, 6.8, 9, 2.6, 'paper');
  d.poly([
    [1.5, 8.1],
    [7.5, 2.5],
    [7.5, 13.7],
  ], 'paper');
}

Future<void> frame(SpriteDrawer d, String? param) async {
  d.rect(1, 1, 22, 22, 'stone', 4);
  d.rect(7, 7, 10, 10, 'paper', 3);
  d.rect(6, 6, 12, 1, 'stoneDark', 2);
  d.rect(6, 6, 1, 12, 'stoneDark', 2);
  d.rect(6, 17, 12, 1, 'stone', 3);
  d.rect(17, 6, 1, 12, 'stone', 3);
  for (final spot in [
    [3.5, 3.5],
    [20.5, 3.5],
    [3.5, 20.5],
    [20.5, 20.5],
  ]) {
    d.circ(spot[0], spot[1], 1.3, 'gold');
  }
}

Future<void> skull(SpriteDrawer d, String? param) async {
  d.circ(16, 13, 9.5, 'bone');
  d.rect(10.5, 18, 11, 8, 'bone');
  d.ell(12.2, 14, 2.6, 3, 'ink', 2);
  d.ell(19.8, 14, 2.6, 3, 'ink', 2);
  d.rect(11, 12.6, 1, 1, 'paper', 3);
  d.rect(18.6, 12.6, 1, 1, 'paper', 3);
  d.poly([
    [16, 17.6],
    [17.5, 21],
    [14.5, 21],
  ], 'ink', 2);
  for (final x in [13.5, 16.0, 18.5]) {
    d.rect(x - 0.4, 23.4, 0.8, 2.6, 'ink', 2);
  }
  d.line([
    [16, 3.8],
    [17.2, 6.6],
    [15.6, 8.8],
  ], 0.5, 'ink', 2);
}

Future<void> shield(SpriteDrawer d, String? param) async {
  d.poly([
    [5, 4],
    [27, 4],
    [27, 15],
    [16, 29],
    [5, 15],
  ], 'iron');
  d.poly([
    [8, 7],
    [24, 7],
    [24, 14.5],
    [16, 25],
    [8, 14.5],
  ], 'blue');
  d.poly([
    [16, 9.5],
    [20, 15],
    [16, 21],
    [12, 15],
  ], 'gold');
  for (final spot in [
    [7.0, 6.0],
    [25.0, 6.0],
  ]) {
    d.rect(spot[0] - 0.5, spot[1] - 0.5, 1, 1, 'paper', 3);
  }
}

Future<void> sword(SpriteDrawer d, String? param) async {
  d.poly([
    [25.5, 3],
    [29, 3],
    [29, 6.5],
    [13, 22.5],
    [9.5, 19],
  ], 'iron');
  d.line([
    [27, 5],
    [12.5, 19.5],
  ], 0.45, 'iron', 3);
  d.line([
    [7, 17],
    [15, 25],
  ], 1.3, 'gold');
  d.line([
    [10.5, 21.5],
    [5.2, 26.8],
  ], 1.2, 'leather');
  d.circ(4, 28, 1.9, 'gold');
}

Future<void> crown(SpriteDrawer d, String? param) async {
  d.circ(4, 9.5, 1.5, 'gold');
  d.circ(16, 6.5, 1.6, 'gold');
  d.circ(28, 9.5, 1.5, 'gold');
  d.poly([
    [4, 10],
    [10, 17],
    [16, 7],
    [22, 17],
    [28, 10],
    [26, 25],
    [6, 25],
  ], 'gold');
  d.rect(6, 22, 20, 3, 'gold', 1);
  d.circ(16, 19, 1.9, 'red');
  d.circ(10, 20, 1.4, 'amethyst');
  d.circ(22, 20, 1.4, 'blue');
}
