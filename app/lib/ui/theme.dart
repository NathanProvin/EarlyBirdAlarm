import 'package:flutter/material.dart';

// "Dawn" tokens, see memory/decisions.md. Flat colors, one radius, no shadows.
const paper = Color(0xFFF6F1EA);
const ink = Color(0xFF1C1B1A);
const coral = Color(0xFFE86A4F);
const moss = Color(0xFF3E8E6A);
const brick = Color(0xFFC9503C);
const radius = 16.0;

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      textStyle: const TextStyle(fontSize: 18),
    ),
  ),
);
