import 'package:flutter/material.dart';
import 'colors.dart';

class AppComponents {
  static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    shape: const StadiumBorder(),
    elevation: 0,
    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
  );

  static final ButtonStyle secondaryGhostButton = OutlinedButton.styleFrom(
    foregroundColor: AppColors.onSurface,
    side: const BorderSide(color: Color.fromRGBO(73, 74, 73, 0.2)), // outline-variant @ 20%
    shape: const StadiumBorder(),
    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surfaceContainerHigh,
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration glassOverlayDecoration = BoxDecoration(
    color: AppColors.surfaceVariant.withOpacity(0.4),
    borderRadius: BorderRadius.circular(24),
  );

  // Example ambient glow for FABs or active items.
  static List<BoxShadow> ambientGlow = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.1),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];
}
