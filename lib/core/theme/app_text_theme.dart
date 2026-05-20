import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gym_flutter/core/theme/app_palette.dart';

/// `TextTheme` Material 3 de la app. Usa Space Grotesk para headlines/displays
/// (acento técnico) y Manrope para cuerpo y labels (legibilidad).
///
/// Los colores no se hornean en los `TextStyle`: se derivan del `AppPalette`
/// que recibe el builder, así el mismo `TextTheme` adapta automáticamente al
/// brightness activo cuando lo expone `AppTheme.light()`/`AppTheme.dark()`.
class AppTextTheme {
  AppTextTheme._();

  /// Construye el `TextTheme` para la paleta dada.
  /// El displayLarge usa `palette.primary` (acento brand) y el resto deriva
  /// jerarquía desde `textPrimary` / `textSecondary`.
  static TextTheme build(AppPalette palette) {
    final headline = GoogleFonts.spaceGroteskTextTheme();
    final body = GoogleFonts.manropeTextTheme();

    return TextTheme(
      displayLarge: headline.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: palette.primary,
      ),
      displayMedium: headline.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: palette.textPrimary,
      ),
      displaySmall: headline.displaySmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      headlineLarge: headline.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: palette.textPrimary,
      ),
      headlineMedium: headline.headlineMedium?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      headlineSmall: headline.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      titleLarge: headline.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        fontSize: 16,
        color: palette.textPrimary,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontSize: 14,
        color: palette.textSecondary,
      ),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: 12,
        color: palette.textSecondary,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: palette.textSecondary,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: palette.textSecondary,
      ),
    );
  }

  /// Alias legacy: `AppTextTheme.dark` se usaba antes del refactor. Mantener
  /// hasta que las pocas referencias residuales (si las hay) migren.
  @Deprecated('Usar AppTextTheme.build(palette) o Theme.of(context).textTheme')
  static TextTheme get dark => build(AppPalette.light());
}
