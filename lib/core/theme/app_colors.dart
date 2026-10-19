import 'package:flutter/material.dart';

/// Paleta canónica de la app. Cualquier color hex literal en `lib/features/`
/// está prohibido — añadí un token nuevo aquí en su lugar.
class AppColors {
  AppColors._();

  // — Surfaces (Light clinical — blanco con jerarquía azul tenue)
  // `surface` está deliberadamente más contrastado que `background` para que
  // las cards se separen visualmente sobre blanco puro.
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF1F4F9);
  static const Color surfaceHighlight = Color(0xFFE5EAF2);
  static const Color surfaceOverlay = Color(0xFFD2DAE5);

  // — Brand (Clinical Blue — iOS system)
  static const Color primary = Color(0xFF007AFF);
  static const Color primaryDark = Color(0xFF0051D5);
  static const Color accent = Color(0xFF5AC8FA);

  /// Color de texto/iconos cuando se pinta SOBRE `primary`, `error`, `success`
  /// u otras fills saturadas. En la paleta actual es blanco; cuando volvamos
  /// a dark esto será negro/oscuro.
  static const Color onPrimary = Color(0xFFFFFFFF);

  // — Text (jerarquía iOS sobre claro)
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6E6E73);
  static const Color textDisabled = Color(0xFFC7C7CC);

  // — Semantic (Apple system, válidos en light)
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color info = Color(0xFF5AC8FA);
  static const Color error = Color(0xFFFF3B30);

  // — Structural
  static const Color divider = Color(0xFFDCE3EE);
  static const Color overlay = Color(
    0x99000000,
  ); // 60% black scrim (más liviano en light)

  // — Glass surfaces (auth pages, hero cards) — tinte oscuro sobre claro
  static const Color glassFill = Color(0x0F000000); // ~6% black
  static const Color glassBorder = Color(0x1F000000); // ~12% black

  // — Accent palette (identidad por rutina/día). Distintos a `primary` para
  // que cada rutina/día tenga su propio color reconocible. Mantener saturada
  // pero legible sobre fondo blanco.
  static const Color accentLime = Color(0xFF8BC34A);
  static const Color accentCoral = Color(0xFFFF6B6B);
  static const Color accentViolet = Color(0xFF9B5DE5);
  static const Color accentAmber = Color(0xFFFFB454);
  static const Color accentCyan = Color(0xFF4ECDC4);
  static const Color accentRose = Color(0xFFF15BB5);
  static const Color accentBlue = Color(0xFF82A5FF);

  /// Paleta de acentos en orden estable. Consumir vía índice (mod len) para
  /// derivar colores deterministas por nombre/índice.
  static const List<Color> accentPalette = [
    accentLime,
    accentCoral,
    accentViolet,
    accentAmber,
    accentCyan,
    accentRose,
    accentBlue,
  ];
}
