import 'package:flutter/material.dart';
import 'app_theme.dart';

// The app's handful of UI colour tokens, reskinned per pixel theme: the real
// app chrome (bars, cards, buttons) reads the "m-" ("mock") tokens from the
// kit's own theme data, since those are what the artifact's own app
// mock-ups used; the plain tokens (bg/ink/accent/...) back the kit's own
// website chrome and aren't used here. Every theme entry below is read
// straight off the kit artifact's THEMES object.
class _ThemeColors {
  final Color bg, row, ink, sub, accent, accentInk, accentSoft, pip, line;
  const _ThemeColors({
    required this.bg,
    required this.row,
    required this.ink,
    required this.sub,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.pip,
    required this.line,
  });
}

const Map<String, _ThemeColors> _kThemeColors = {
  'dungeon': _ThemeColors(
    bg: Color(0xFF1B1B1B),
    row: Color(0xFF2A2A2A),
    ink: Color(0xFFFFFFFF),
    sub: Color(0xFFCFCFCF),
    accent: Color(0xFF9900FF),
    accentInk: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFC070FF),
    pip: Color(0xFF3A3A3A),
    line: Color(0xFF2C2C2C),
  ),
  'kawaii': _ThemeColors(
    bg: Color(0xFFFFF4F9),
    row: Color(0xFFFFE3F0),
    ink: Color(0xFF5A3A5E),
    sub: Color(0xFF8E6A8E),
    accent: Color(0xFFFF7FBF),
    accentInk: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFD8468C),
    pip: Color(0xFFF6CFE2),
    line: Color(0xFFF6D6E6),
  ),
};

// Theme-reactive replacements for the colour literals/ternaries that used to
// be hardcoded at nearly every call site across the app. Each falls back to
// the exact original value for the Default theme (or for any theme that
// doesn't define colours, which today is none), so nothing changes unless a
// pixel theme is actually selected in Settings - see app_theme.dart.
//
// These are plain value reads, not listenable - like the isDarkMode values
// they replace, a screen only picks up a newly-selected theme's colours the
// next time it rebuilds (e.g. navigating back to it), exactly matching how
// toggling Dark Mode already behaves today.
class AppColors {
  AppColors._();

  static _ThemeColors? get _c => _kThemeColors[AppTheme.instance.themeId];

  // The app's single accent colour (buttons, selected tabs, links, borders)
  // - replaces the literal `Color(0xFF9A00FE)` used at ~300 call sites.
  static Color get accent => _c?.accent ?? const Color(0xFF9A00FE);
  static Color get accentSoft => _c?.accentSoft ?? const Color(0xFFC070FF);
  static Color get accentInk => _c?.accentInk ?? Colors.white;

  // Page/scaffold background - replaces `isDarkMode ? Color(0xFF1A1A1A) : Colors.white`.
  static Color pageBg(bool isDarkMode) => _c?.bg ?? (isDarkMode ? const Color(0xFF1A1A1A) : Colors.white);
  // Card/row/panel background - replaces `isDarkMode ? Color(0xFF2A2A2A) : Colors.grey[100]`.
  static Color cardBg(bool isDarkMode) => _c?.row ?? (isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100]!);
  // Primary text - replaces `isDarkMode ? Colors.white : Colors.black87`.
  static Color text(bool isDarkMode) => _c?.ink ?? (isDarkMode ? Colors.white : Colors.black87);
  // Secondary/muted text - replaces `isDarkMode ? Colors.white70 : Colors.black54`.
  static Color textMuted(bool isDarkMode) => _c?.sub ?? (isDarkMode ? Colors.white70 : Colors.black54);
  // Dividers/borders.
  static Color line(bool isDarkMode) => _c?.line ?? (isDarkMode ? Colors.white24 : Colors.black12);
  // Inactive progress-bar segment background (the unfilled part of the XP bar).
  static Color pip(bool isDarkMode) => _c?.pip ?? (isDarkMode ? Colors.white12 : Colors.black12);
}
