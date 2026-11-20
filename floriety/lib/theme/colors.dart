import 'package:flutter/material.dart';

class AppColors {
  // ---- DARK MODE COLORS ----
  static const Color surface = Color(0xFF0D0F0D);
  static const Color surfaceContainerLowest = Color(0xFF000000);
  static const Color surfaceContainerLow = Color(0xFF121412);
  static const Color surfaceContainer = Color(0xFF1A1C1A);
  static const Color surfaceContainerHigh = Color(0xFF1E201E);
  static const Color surfaceContainerHighest = Color(0xFF242624);

  static const Color primary = Color(0xFF5DFF3C);
  static const Color primaryContainer = Color(0xFF3AF114);
  static const Color onPrimary = Color(0xFF0D5D00);
  static const Color onSurface = Color(0xFFFAF9F5);
  static const Color onSurfaceVariant = Color(0xFFABABA8);
  static const Color outlineVariant = Color(0xFF494A49);
  static const Color surfaceVariant = Color(0xFF282A28);

  static const ColorScheme colorScheme = ColorScheme.dark(
    surface: surface,
    primary: primary,
    primaryContainer: primaryContainer,
    onPrimary: onPrimary,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    outlineVariant: outlineVariant,
  );

  // ---- LIGHT MODE COLORS ----
  static const Color lightSurface = Color(0xFFF8FAF7);
  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLow = Color(0xFFEEF2ED);
  static const Color lightSurfaceContainer = Color(0xFFE4EAE3);
  static const Color lightSurfaceContainerHigh = Color(0xFFD8DFD7);
  static const Color lightSurfaceContainerHighest = Color(0xFFCDD5CC);

  // In light mode: green is slightly darker so it's visible on white bg
  static const Color lightPrimary = Color(0xFF2E8B00);
  static const Color lightPrimaryContainer = Color(0xFF1E6B00);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF1A1C1A);
  static const Color lightOnSurfaceVariant = Color(0xFF5A5E59);
  static const Color lightOutlineVariant = Color(0xFFB0B5AF);
  static const Color lightSurfaceVariant = Color(0xFFDDE5DC);

  static const ColorScheme lightColorScheme = ColorScheme.light(
    surface: lightSurface,
    primary: lightPrimary,
    primaryContainer: lightPrimaryContainer,
    onPrimary: lightOnPrimary,
    onSurface: lightOnSurface,
    onSurfaceVariant: lightOnSurfaceVariant,
    outlineVariant: lightOutlineVariant,
  );
}
