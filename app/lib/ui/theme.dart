import 'package:flutter/material.dart';

// "Dawn" tokens, see memory/decisions.md. Flat colors, one radius, no shadows.
const paper = Color(0xFFF6F1EA);
const ink = Color(0xFF1C1B1A);
const coral = Color(0xFFE86A4F);
const moss = Color(0xFF3E8E6A);
const brick = Color(0xFFC9503C);
const radius = 16.0;

/// Card frame color per rarity tier (decisions.md "Card collection").
const rarityColor = {
  'common': Color(0xFF8C857B),
  'uncommon': Color(0xFF4F8F5B),
  'rare': Color(0xFF3B7DB8),
  'epic': Color(0xFF8A4FB0),
  'legendary': Color(0xFFD9A21B),
};
const unknownColor = Color(0xFFDDD5CA); // not discovered yet

/// A color theme (decisions.md "Themes"); success, fail and rarity colors are shared.
typedef Palette = ({
  Brightness brightness,
  Color background,
  Color text,
  Color accent,
  Color onAccent, // button text on the accent (WCAG AA checked)
  Color surface, // chips, tiles, round buttons
});

/// The bird themes (decisions.md "Themes"), all WCAG AA checked: text on background and
/// on surface ≥ 4.5, accent on background ≥ 3, button text on the accent ≥ 4.5.
const palettes = <String, Palette>{
  // Slate plumage, orange-yellow beak.
  'blackbird': (
    brightness: Brightness.dark,
    background: Color(0xFF1E2124),
    text: Color(0xFFECEAE6),
    accent: Color(0xFFE8A33D),
    onAccent: ink,
    surface: Color(0xFF2F3337),
  ),
  // Mossy green, the serin's bright yellow.
  'serin': (
    brightness: Brightness.dark,
    background: Color(0xFF33501F),
    text: Color(0xFFF2F6E6),
    accent: Color(0xFFF5D83C),
    onAccent: ink,
    surface: Color(0xFF46672F),
  ),
  // Pale sky, cobalt cap.
  'bluetit': (
    brightness: Brightness.light,
    background: Color(0xFFEEF3F7),
    text: Color(0xFF1D2A36),
    accent: Color(0xFF2F6DB5),
    onAccent: Color(0xFFFFFFFF),
    surface: Color(0xFFD5E1EA),
  ),
  // Creamy white, black wingtips, the brick-red spot on the bill.
  'gull': (
    brightness: Brightness.light,
    background: Color(0xFFFAF7F0),
    text: Color(0xFF1A1A1A),
    accent: Color(0xFFB5442E),
    onAccent: Color(0xFFFFFFFF),
    surface: Color(0xFFE2E3E0),
  ),
};

/// "Phone" follows the phone's dark mode with these two.
const lightTheme = 'bluetit', darkTheme = 'blackbird';

/// Cards are printed on paper in every theme: ink on paper, coral accents.
final cardTheme = _themeOf((
  brightness: Brightness.light,
  background: paper,
  text: ink,
  accent: coral,
  onAccent: ink,
  surface: unknownColor,
));

ThemeData themeFor(String name) =>
    _themeOf(palettes[name] ?? palettes[lightTheme]!);

ThemeData _themeOf(Palette p) {
  return ThemeData(
    colorScheme: ColorScheme(
      brightness: p.brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.accent,
      onSecondary: p.onAccent,
      secondaryContainer: p.surface,
      onSecondaryContainer: p.text,
      surface: p.background,
      onSurface: p.text,
      error: brick,
      onError: paper,
    ),
    scaffoldBackgroundColor: p.background,
    shadowColor: Colors.transparent,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        textStyle: const TextStyle(fontSize: 18),
      ),
    ),
    // The chosen option (Settings) is filled with the theme's accent.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: p.accent,
        selectedForegroundColor: p.onAccent,
      ),
    ),
  );
}
