import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pixel_sprites.dart';
import 'pixel_theme_dungeon.dart';
import 'pixel_theme_kawaii.dart';

// "Default" isn't a PixelTheme at all - it means "leave the app exactly as
// it's always looked" (the real bookshelf/book/chest photos, the plain
// purple accent). Every other id here re-skins a handful of icons with a
// PixelTheme's hand-drawn sprites - see ThemedIcon below, which falls back
// to the Default-theme widget whenever the active theme doesn't define a
// given icon (either because the theme is Default, or because this icon
// hasn't been ported for it yet).
const String kDefaultThemeId = 'default';

final Map<String, PixelTheme> kPixelThemes = {
  kDungeonTheme.id: kDungeonTheme,
  kKawaiiTheme.id: kKawaiiTheme,
};

// Display order + labels for the Settings picker, Default first.
const List<MapEntry<String, String>> kThemeChoices = [
  MapEntry(kDefaultThemeId, 'Default'),
  MapEntry('dungeon', 'Dungeon'),
  MapEntry('kawaii', 'Kawaii'),
];

// The single source of truth for which theme is active - a ChangeNotifier
// (not a Provider/InheritedWidget, to match this app's existing pattern of
// threading isDarkMode through explicit constructor params rather than a
// theming framework) that any screen can listen to directly via
// AnimatedBuilder.
class AppTheme extends ChangeNotifier {
  AppTheme._();
  static final AppTheme instance = AppTheme._();

  static const _prefsKey = 'app_theme_id';
  String _themeId = kDefaultThemeId;
  String get themeId => _themeId;
  PixelTheme? get pixelTheme => kPixelThemes[_themeId];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeId = prefs.getString(_prefsKey) ?? kDefaultThemeId;
    notifyListeners();
  }

  Future<void> setTheme(String id) async {
    if (id == _themeId) return;
    _themeId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, id);
  }
}

// Drop-in replacement for any existing icon/photo widget: shows the active
// theme's pixel-art sprite for [iconId] when one exists, or [fallback] (the
// app's original image/icon) otherwise - so every call site degrades
// gracefully to today's look for Default, and for any theme that simply
// hasn't drawn this particular icon yet.
class ThemedIcon extends StatelessWidget {
  final String iconId;
  final double size;
  final Widget fallback;
  final String? param;
  const ThemedIcon({super.key, required this.iconId, required this.size, required this.fallback, this.param});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppTheme.instance,
      builder: (context, _) {
        final theme = AppTheme.instance.pixelTheme;
        if (theme == null || !theme.icons.containsKey(iconId)) return fallback;
        return PixelSprite(theme: theme, iconId: iconId, size: size, param: param);
      },
    );
  }
}

// A chunky, square-ish bordered shape for buttons/cards when a pixel theme
// is active, using that theme's own sprite-outline colour as the border -
// this is what actually reads as "pixel art panel" rather than Material's
// smooth rounded corners. Returns null for Default, so callers should keep
// their existing shape in that case (`pixelShape() ?? RoundedRectangleBorder(...)`).
OutlinedBorder? pixelShape({double radius = 3, double borderWidth = 3}) {
  final theme = AppTheme.instance.pixelTheme;
  if (theme == null) return null;
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
    side: BorderSide(color: theme.palette.outline, width: borderWidth),
  );
}

// Same idea as pixelShape, but as a BoxDecoration for plain Containers that
// aren't a Material button/card (so can't take a ShapeBorder).
BoxDecoration? pixelPanelDecoration({required Color fill, double radius = 3, double borderWidth = 3}) {
  final theme = AppTheme.instance.pixelTheme;
  if (theme == null) return null;
  return BoxDecoration(
    color: fill,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: theme.palette.outline, width: borderWidth),
  );
}

// A chunky RPG-style segmented progress bar (the XP bar), matching the
// kit's own design: a pip-coloured background, a solid-colour fill with an
// inset top highlight/bottom shadow for a beveled look, and visible divider
// lines running through the filled portion so it reads as discrete
// segments rather than a smooth gradient - a single widget doing what the
// kit's own CSS did with a repeating-linear-gradient overlay. [fallback] is
// shown instead for Default (callers build it with their own existing bar,
// e.g. a plain LinearProgressIndicator, so nothing changes there).
class PixelProgressBar extends StatelessWidget {
  final double value;
  final Color pipColor;
  final Color fillColor;
  final Widget fallback;
  final double height;
  const PixelProgressBar({
    super.key,
    required this.value,
    required this.pipColor,
    required this.fillColor,
    required this.fallback,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance.pixelTheme;
    if (theme == null) return fallback;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _PixelProgressPainter(value: value.clamp(0, 1), pip: pipColor, fill: fillColor, outline: theme.palette.outline),
        size: Size.infinite,
      ),
    );
  }
}

class _PixelProgressPainter extends CustomPainter {
  final double value;
  final Color pip;
  final Color fill;
  final Color outline;
  _PixelProgressPainter({required this.value, required this.pip, required this.fill, required this.outline});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = pip);
    final fillWidth = size.width * value;
    if (fillWidth > 0.5) {
      canvas.drawRect(Rect.fromLTWH(0, 0, fillWidth, size.height), Paint()..color = fill);
      final bevel = (size.height / 5).clamp(1.5, 3.0);
      canvas.drawRect(Rect.fromLTWH(0, 0, fillWidth, bevel), Paint()..color = Colors.white.withValues(alpha: 0.28));
      canvas.drawRect(Rect.fromLTWH(0, size.height - bevel, fillWidth, bevel), Paint()..color = Colors.black.withValues(alpha: 0.28));
      final pipPaint = Paint()..color = Colors.black.withValues(alpha: 0.35);
      const pipSpacing = 20.0, pipWidth = 2.0;
      for (var x = pipSpacing; x < fillWidth; x += pipSpacing) {
        canvas.drawRect(Rect.fromLTWH(x - pipWidth, 0, pipWidth, size.height), pipPaint);
      }
    }
    canvas.drawRect(rect.deflate(1), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = outline);
  }

  @override
  bool shouldRepaint(covariant _PixelProgressPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.pip != pip || oldDelegate.fill != fill || oldDelegate.outline != outline;
}

