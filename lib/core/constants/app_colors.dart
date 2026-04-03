import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark Mode / Black palette
  static const Color background = Color(0xFF101010); // Solid almost black
  static const Color surface = Color(0xFF1C1C1E); // Elevated dark gray
  static const Color surfaceHighlight = Color(0xFF2C2C2E);

  // Yellow / Accent palette (no neon, just solid premium yellow)
  static const Color primary = Color(0xFFFFD60A); // Premium Yellow
  static const Color primaryDark = Color(0xFFCCAB08);
  static const Color accent = Color(0xFFFFD60A); 

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A5);
  static const Color textDisabled = Color(0xFF4C4C50);

  static const Color error = Color(0xFFFF453A);
  static const Color success = Color(0xFF32D74B); // SF Pro Success Green
}
