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

final dawnTheme = ThemeData(
  colorScheme: const ColorScheme.light(
    primary: coral,
    onPrimary: ink,
    surface: paper,
    onSurface: ink,
    error: brick,
  ),
  scaffoldBackgroundColor: paper,
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
