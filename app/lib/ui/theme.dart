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

const palettes = <String, Palette>{
  'dawn': (
    brightness: Brightness.light,
    background: paper,
    text: ink,
    accent: coral,
    onAccent: ink,
    surface: unknownColor,
  ),
  'dusk': (
    brightness: Brightness.dark,
    background: Color(0xFF1A1B2E),
    text: Color(0xFFECE8F5),
    accent: Color(0xFFF2A541),
    onAccent: ink,
    surface: Color(0xFF2C2D45),
  ),
  'forest': (
    brightness: Brightness.light,
    background: Color(0xFFEDF0E6),
    text: Color(0xFF1F2A22),
    accent: Color(0xFF1E6B66),
    onAccent: Color(0xFFFFFFFF),
    surface: Color(0xFFD6DDCC),
  ),
};

ThemeData themeFor(String name) {
  final p = palettes[name] ?? palettes['dawn']!;
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
  );
}
