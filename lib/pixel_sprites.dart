import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// Pixel-art sprite engine - a Dart port of the "Study Dojo Pixel Kit"
// canvas-drawing algorithm (a web artifact the user generated with Claude
// separately). Each icon is defined as a tiny set of shape calls (rect,
// ellipse, polygon, line, glyph) against a low-resolution grid; every shape
// picks a named "material" (wood, stone, gold, ...) and this engine works
// out per-pixel highlight/shadow shading automatically from which
// neighbouring pixels belong to a different material, then adds a one-pixel
// outline around the whole sprite - the same "coal to amethyst ore" pixel
// style used throughout the kit. See pixel_theme_dungeon.dart for the first
// theme's actual icon definitions.

// One material's three tones. Shade 1/2/3 pin a shape to dark/mid/light
// outright (used for highlights, carved text, etc); shade 0 (the default)
// lets the engine auto-shade based on neighbouring pixels, and shade 4 asks
// for a dithered/textured mix of all three tones (used for broad surfaces
// like wood or stone faces).
class SpriteMaterial {
  final Color dark, mid, light;
  const SpriteMaterial(this.dark, this.mid, this.light);
}

class SpritePalette {
  final Map<String, SpriteMaterial> materials;
  final Color outline;
  const SpritePalette(this.materials, this.outline);

  SpritePalette withOverrides(Map<String, SpriteMaterial> overrides, {Color? outline}) {
    return SpritePalette({...materials, ...overrides}, outline ?? this.outline);
  }
}

// The base material set every theme starts from, lifted straight from the
// kit's own MAT_LIST - a theme only needs to list the materials it actually
// recolours (see pixel_theme_dungeon.dart's empty override map: Dungeon uses
// every one of these completely unmodified).
const SpritePalette kBasePalette = SpritePalette({
  'wood': SpriteMaterial(Color(0xFF5A3A22), Color(0xFF7D5233), Color(0xFFA06E45)),
  'woodDark': SpriteMaterial(Color(0xFF33221A), Color(0xFF46301F), Color(0xFF5A3F28)),
  'stone': SpriteMaterial(Color(0xFF4A4A55), Color(0xFF6B6B78), Color(0xFF8E8E9C)),
  'stoneDark': SpriteMaterial(Color(0xFF2C2C35), Color(0xFF3C3C47), Color(0xFF4D4D59)),
  'gold': SpriteMaterial(Color(0xFFA8741A), Color(0xFFE0A82A), Color(0xFFFFD75A)),
  'iron': SpriteMaterial(Color(0xFF6E7884), Color(0xFFA3ADB8), Color(0xFFDFE5EC)),
  'purple': SpriteMaterial(Color(0xFF5A00A0), Color(0xFF9000F0), Color(0xFFC070FF)),
  'amethyst': SpriteMaterial(Color(0xFF4B1A8A), Color(0xFF8A3FE0), Color(0xFFD4A4FF)),
  'parchment': SpriteMaterial(Color(0xFFB89A6A), Color(0xFFE0C890), Color(0xFFF6E8C0)),
  'paper': SpriteMaterial(Color(0xFFB8B8C4), Color(0xFFE6E6EE), Color(0xFFFFFFFF)),
  'red': SpriteMaterial(Color(0xFF7A1A22), Color(0xFFC8323A), Color(0xFFF0646A)),
  'green': SpriteMaterial(Color(0xFF2F6A24), Color(0xFF4F9A32), Color(0xFF7CC84A)),
  'dirt': SpriteMaterial(Color(0xFF5A3A24), Color(0xFF7A5234), Color(0xFF9A6A44)),
  'blue': SpriteMaterial(Color(0xFF1F3F8A), Color(0xFF3A6AD0), Color(0xFF7AA8F0)),
  'sky': SpriteMaterial(Color(0xFF3A5AA0), Color(0xFF6A9AE0), Color(0xFFA8D0FF)),
  'orange': SpriteMaterial(Color(0xFFB8401A), Color(0xFFF07A1A), Color(0xFFFFC23A)),
  'cloud': SpriteMaterial(Color(0xFFA8B4C8), Color(0xFFD8E0EC), Color(0xFFFFFFFF)),
  'ink': SpriteMaterial(Color(0xFF140F1C), Color(0xFF221A2E), Color(0xFF3A2F4A)),
  'teal': SpriteMaterial(Color(0xFF1A6A6A), Color(0xFF2AA6A0), Color(0xFF6AE0D0)),
  'leather': SpriteMaterial(Color(0xFF4A2A2A), Color(0xFF6E3C34), Color(0xFF93564A)),
  'fur': SpriteMaterial(Color(0xFF6A4020), Color(0xFFA0682E), Color(0xFFD0985A)),
  'bone': SpriteMaterial(Color(0xFF9A8C72), Color(0xFFD8CCB0), Color(0xFFF6EEDC)),
}, Color(0xFF140F1C));

bool _inPoly(List<List<double>> p, double x, double y) {
  var c = false;
  var j = p.length - 1;
  for (var i = 0; i < p.length; i++) {
    final xi = p[i][0], yi = p[i][1], xj = p[j][0], yj = p[j][1];
    if (((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) c = !c;
    j = i;
  }
  return c;
}

bool Function(double, double) _inCap(List<List<double>> pts, double r) {
  return (x, y) {
    for (var i = 0; i < pts.length - 1; i++) {
      final x0 = pts[i][0], y0 = pts[i][1], x1 = pts[i + 1][0], y1 = pts[i + 1][1];
      final dx = x1 - x0, dy = y1 - y0;
      final l = dx * dx + dy * dy == 0 ? 1.0 : dx * dx + dy * dy;
      var t = ((x - x0) * dx + (y - y0) * dy) / l;
      t = t.clamp(0.0, 1.0);
      final hx = x0 + t * dx, hy = y0 + t * dy;
      if ((x - hx) * (x - hx) + (y - hy) * (y - hy) <= r * r) return true;
    }
    return false;
  };
}

bool Function(double, double) circleTest(double cx, double cy, double r) =>
    (x, y) => (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r;

// A rounded-capsule "is this point within [r] of any segment of this
// polyline" test, for carving a thin curved slit out of a shape (e.g. the
// crack down the middle of the Mistakes heart).
bool Function(double, double) capsuleTest(List<List<double>> pts, double r) => _inCap(pts, r);

int _byte(double channel) => (channel * 255.0).round().clamp(0, 255);

double _hash(int x, int y) {
  var h = (x * 374761393 + y * 668265263) & 0xFFFFFFFF;
  h = (h ^ (h >> 13)) & 0xFFFFFFFF;
  h = (h * 1274126177) & 0xFFFFFFFF;
  return ((h ^ (h >> 16)) & 0xFFFFFFFF) / 4294967296.0;
}

// The logical drawing surface for one sprite: a [bw]x[bh] grid of "base
// units" rasterised at [k] device pixels per unit. Every shape call fills
// in whichever grid cells its test predicate covers; finish() (in
// _rasterize below) turns that into actual colours afterwards, once every
// shape has been drawn, so later shapes always paint over earlier ones.
class SpriteDrawer {
  final int bw, bh;
  final double k;
  late final int nx, ny;
  late final List<int> matIdx; // 0 = empty, else 1-based index into materialNames
  late final List<int> shadeGrid; // 0 auto, 1 dark, 2 mid, 3 light, 4 textured
  final SpritePalette palette;
  late final List<String> materialNames;
  final Map<String, int> _matLookup = {};

  SpriteDrawer(this.bw, this.bh, this.k, this.palette) {
    nx = (bw * k).round();
    ny = (bh * k).round();
    matIdx = List.filled(nx * ny, 0);
    shadeGrid = List.filled(nx * ny, 0);
    materialNames = palette.materials.keys.toList();
    for (var i = 0; i < materialNames.length; i++) {
      _matLookup[materialNames[i]] = i + 1;
    }
  }

  int matIndex(String name) {
    final i = _matLookup[name];
    if (i == null) throw ArgumentError('Unknown sprite material "$name"');
    return i;
  }

  void put(int x, int y, int mi, int sh) {
    if (x >= 0 && x < nx && y >= 0 && y < ny) {
      final i = y * nx + x;
      matIdx[i] = mi;
      shadeGrid[i] = sh;
    }
  }

  void _fill(bool Function(double, double) test, String? m, int sh) {
    final mi = m == null ? 0 : matIndex(m);
    for (var py = 0; py < ny; py++) {
      final gy = (py + 0.5) / k;
      for (var px = 0; px < nx; px++) {
        if (test((px + 0.5) / k, gy)) put(px, py, mi, sh);
      }
    }
  }

  void rect(double x, double y, double w, double h, String m, [int sh = 0]) {
    final mi = matIndex(m);
    final x0 = (x * k).round(), x1 = ((x + w) * k).round();
    final y0 = (y * k).round(), y1 = ((y + h) * k).round();
    for (var py = y0; py < y1; py++) {
      for (var px = x0; px < x1; px++) {
        put(px, py, mi, sh);
      }
    }
  }

  void ell(double cx, double cy, double rx, double ry, String m, [int sh = 0, bool Function(double, double)? t]) {
    _fill((x, y) {
      final a = (x - cx) / rx, b = (y - cy) / ry;
      return a * a + b * b <= 1 && (t == null || t(x, y));
    }, m, sh);
  }

  void circ(double cx, double cy, double r, String m, [int sh = 0, bool Function(double, double)? t]) =>
      ell(cx, cy, r, r, m, sh, t);

  void poly(List<List<double>> pts, String m, [int sh = 0]) => _fill((x, y) => _inPoly(pts, x, y), m, sh);

  void line(List<List<double>> pts, double r, String m, [int sh = 0]) => _fill(_inCap(pts, r), m, sh);

  void fn(bool Function(double, double) test, String m, [int sh = 0]) => _fill(test, m, sh);

  void clear(bool Function(double, double) test) => _fill(test, null, 0);

  // True if every grid cell within [r] base-units of (cx, cy) is still
  // empty - used by sprinkle to avoid stamping a decoration on top of
  // something the icon's own draw already placed there.
  bool emptyNear(double cx, double cy, double r) {
    final py0 = ((cy - r) * k).floor(), py1 = ((cy + r) * k).ceil();
    final px0 = ((cx - r) * k).floor(), px1 = ((cx + r) * k).ceil();
    for (var py = py0; py <= py1; py++) {
      for (var px = px0; px <= px1; px++) {
        if (px < 0 || py < 0 || px >= nx || py >= ny || matIdx[py * nx + px] != 0) return false;
      }
    }
    return true;
  }

  // Scatters up to [n] copies of [shape] (a small draw callback taking the
  // stamp's centre) at pseudo-random positions at least [r] base-units from
  // the sprite's edge, skipping any spot that would overlap something
  // already drawn - [seed] makes placement deterministic per icon (see
  // PixelTheme.deco). Matches the kit's own decoration sprinkle (e.g.
  // Kawaii's scattered hearts).
  void sprinkle(int seed, int n, double r, void Function(double x, double y) shape) {
    var placed = 0;
    for (var t = 0; t < 90 && placed < n; t++) {
      final x = r + 1 + _hash(seed, t * 3 + 1) * (bw - 2 * r - 2);
      final y = r + 1 + _hash(t * 5 + 2, seed) * (bh - 2 * r - 2);
      if (!emptyNear(x, y, r)) continue;
      shape(x, y);
      placed++;
    }
  }

  // Renders [ch] (a kana/kanji character, a digit string, etc) through
  // Flutter's own text layout at 3x the target size (matching the kit's own
  // supersample-then-threshold trick), then stamps every pixel whose alpha
  // beat the threshold into the grid as material [m]. Async because
  // rasterizing text requires a round trip through the engine's image
  // decoder - see PixelSpriteCache, which awaits every icon's draw once and
  // caches the result.
  Future<void> glyph(String ch, double cx, double cy, double size, String m, int sh, {FontWeight weight = FontWeight.w700}) async {
    final p = math.max(5, (size * k).round());
    final s = p * 3;
    final painter = TextPainter(
      text: TextSpan(text: ch, style: TextStyle(fontSize: p.toDouble(), fontWeight: weight, color: Colors.black)),
      textDirection: TextDirection.ltr,
    )..layout();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, s.toDouble(), s.toDouble()));
    painter.paint(canvas, Offset((s - painter.width) / 2, (s - painter.height) / 2));
    final picture = recorder.endRecording();
    final img = await picture.toImage(s, s);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    picture.dispose();
    if (bytes == null) return;
    final mi = matIndex(m);
    final ox = (cx * k - s / 2).round(), oy = (cy * k - s / 2).round();
    for (var j = 0; j < s; j++) {
      for (var i = 0; i < s; i++) {
        final a = bytes.getUint8((j * s + i) * 4 + 3);
        if (a > 110) put(ox + i, oy + j, mi, sh);
      }
    }
  }
}

// Turns a SpriteDrawer's grid into RGBA pixel bytes: every filled cell gets
// its material's dark/mid/light tone (explicit shade) or an automatic one
// based on whether its unlike neighbours sit above/left (lit from the
// bottom-right, so the highlight faces up-left) or below/right (shadow),
// then every cell adjacent to a filled one - working outward a few passes -
// gets painted the outline colour, giving every sprite a crisp dark border
// regardless of shape.
Uint8List _rasterize(SpriteDrawer d) {
  final t = math.max(1, (d.k * 0.6).round());
  final cell = math.max(1, d.k.round());
  final ot = math.max(1, (d.k * 0.75).floor());
  final px = Uint8List(d.nx * d.ny * 4);

  int atMat(int x, int y) => (x < 0 || y < 0 || x >= d.nx || y >= d.ny) ? 0 : d.matIdx[y * d.nx + x];
  int atShade(int x, int y) => (x < 0 || y < 0 || x >= d.nx || y >= d.ny) ? 0 : d.shadeGrid[y * d.nx + x];
  bool differs(int nMat, int nShade, int m) {
    if (nMat == 0) return true;
    return nMat != m && (nShade == 0 || nShade == 4);
  }

  for (var y = 0; y < d.ny; y++) {
    for (var x = 0; x < d.nx; x++) {
      final mi = d.matIdx[y * d.nx + x];
      if (mi == 0) continue;
      final sh = d.shadeGrid[y * d.nx + x];
      final mat = d.palette.materials[d.materialNames[mi - 1]]!;
      Color col;
      if (sh >= 1 && sh <= 3) {
        col = sh == 1 ? mat.dark : sh == 2 ? mat.mid : mat.light;
      } else {
        var tl = false, br = false;
        for (var i = 1; i <= t; i++) {
          if (differs(atMat(x - i, y), atShade(x - i, y), mi) || differs(atMat(x, y - i), atShade(x, y - i), mi)) tl = true;
          if (differs(atMat(x + i, y), atShade(x + i, y), mi) || differs(atMat(x, y + i), atShade(x, y + i), mi)) br = true;
        }
        if (br && !tl) {
          col = mat.dark;
        } else if (tl && !br) {
          col = mat.light;
        } else if (sh == 4 && !tl && !br) {
          final h = _hash((x / cell).floor(), (y / cell).floor());
          col = h < 0.16 ? mat.dark : (h > 0.84 ? mat.light : mat.mid);
        } else {
          col = mat.mid;
        }
      }
      final q = (y * d.nx + x) * 4;
      px[q] = _byte(col.r);
      px[q + 1] = _byte(col.g);
      px[q + 2] = _byte(col.b);
      px[q + 3] = 255;
    }
  }

  var mask = List<bool>.generate(d.nx * d.ny, (i) => d.matIdx[i] != 0);
  for (var k2 = 0; k2 < ot; k2++) {
    final next = List<bool>.from(mask);
    for (var y = 0; y < d.ny; y++) {
      for (var x = 0; x < d.nx; x++) {
        final i = y * d.nx + x;
        if (mask[i]) continue;
        final has = (x > 0 && mask[i - 1]) || (x < d.nx - 1 && mask[i + 1]) || (y > 0 && mask[i - d.nx]) || (y < d.ny - 1 && mask[i + d.nx]);
        if (has) {
          next[i] = true;
          final q = i * 4;
          px[q] = _byte(d.palette.outline.r);
          px[q + 1] = _byte(d.palette.outline.g);
          px[q + 2] = _byte(d.palette.outline.b);
          px[q + 3] = 255;
        }
      }
    }
    mask = next;
  }
  return px;
}

// One icon's recipe: its base grid size and the shape calls that draw it.
// [param] carries whatever small bit of dynamic data the icon needs (the
// level number for "level", a kana character for "deckKana", ...) - icons
// that don't need one just ignore it.
class SpriteIconDef {
  final int baseWidth;
  final int baseHeight;
  final Future<void> Function(SpriteDrawer d, String? param) draw;
  const SpriteIconDef({required this.baseWidth, int? baseHeight, required this.draw}) : baseHeight = baseHeight ?? baseWidth;
}

// An optional decoration pass a theme runs on every icon after its own
// draw() finishes - e.g. Kawaii stamping a face on specific icons and
// scattering a couple of hearts on everything. [seed] is a deterministic
// per-icon value (see strHash) so sprinkle placement doesn't change between
// renders of the same icon.
typedef PixelThemeDeco = void Function(SpriteDrawer d, String iconId, int seed);

class PixelTheme {
  final String id;
  final String name;
  final SpritePalette palette;
  final Map<String, SpriteIconDef> icons;
  final PixelThemeDeco? deco;
  // When set, this theme always runs in that brightness regardless of the
  // app's own Dark Mode setting - Dungeon is built dark, Kawaii is built
  // light, and mixing either with the "wrong" mode would fight its own
  // palette. Null (the default) means this theme has no opinion and follows
  // whatever Dark Mode is currently set to.
  final bool? forcedDarkMode;
  const PixelTheme({
    required this.id,
    required this.name,
    required this.palette,
    required this.icons,
    this.deco,
    this.forcedDarkMode,
  });
}

// A simple deterministic string hash, for seeding sprinkle() per icon id so
// the same icon always scatters its decorations in the same spots.
int strHash(String s) {
  var h = 7;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x7FFFFFFF;
  }
  return h;
}

// Generates and caches every sprite that's actually been requested, keyed by
// theme + icon + resolution + dynamic param - each one is only ever drawn
// once per combination for the life of the app.
class PixelSpriteCache {
  PixelSpriteCache._();
  static final Map<String, Future<ui.Image>> _cache = {};

  static Future<ui.Image> get(PixelTheme theme, String iconId, {String? param, double k = 3}) {
    final key = '${theme.id}:$iconId:${param ?? ""}:$k';
    return _cache.putIfAbsent(key, () => _build(theme, iconId, param, k));
  }

  static Future<ui.Image> _build(PixelTheme theme, String iconId, String? param, double k) async {
    final def = theme.icons[iconId];
    if (def == null) throw ArgumentError('Theme "${theme.id}" has no icon "$iconId"');
    final d = SpriteDrawer(def.baseWidth, def.baseHeight, k, theme.palette);
    await def.draw(d, param);
    theme.deco?.call(d, iconId, strHash(iconId));
    final rgba = _rasterize(d);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(rgba, d.nx, d.ny, ui.PixelFormat.rgba8888, completer.complete);
    return completer.future;
  }
}

// Displays one themed pixel-art icon, matching the kit's own recommendation
// to scale sprites with nearest-neighbour (no blur) so they stay crisp.
class PixelSprite extends StatelessWidget {
  final PixelTheme theme;
  final String iconId;
  final double size;
  final String? param;
  const PixelSprite({super.key, required this.theme, required this.iconId, required this.size, this.param});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<ui.Image>(
        future: PixelSpriteCache.get(theme, iconId, param: param),
        builder: (context, snapshot) {
          final image = snapshot.data;
          if (image == null) return const SizedBox.shrink();
          return RawImage(image: image, width: size, height: size, filterQuality: FilterQuality.none, fit: BoxFit.contain);
        },
      ),
    );
  }
}
