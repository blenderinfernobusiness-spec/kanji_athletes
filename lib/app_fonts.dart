import 'package:flutter/material.dart';
import 'app_theme.dart';

// The kit's own pixel display font (Pixelify Sans) isn't bundled, so Press
// Start 2P (also OFL-licensed, same "8-bit" character) stands in for it -
// see assets/fonts/. Used for headings/buttons once a pixel theme is active;
// every AppBar across the app already picks this up for free via the
// ThemeData set in main.dart's _ThemedMaterialApp, since none of them give
// their title Text its own explicit style.
class AppFonts {
  AppFonts._();

  static bool get isPixel => AppTheme.instance.pixelTheme != null;

  // Wraps [style] with the pixel font and a touch of extra letter spacing
  // (pixel fonts read better loose) when a pixel theme is active - returns
  // [style] untouched for Default.
  static TextStyle display(TextStyle style) {
    if (!isPixel) return style;
    return style.copyWith(fontFamily: 'PressStart2P', letterSpacing: 1);
  }
}
