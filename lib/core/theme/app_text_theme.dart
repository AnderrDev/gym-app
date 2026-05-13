import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';

/// `TextTheme` Material 3 de la app. Usa Space Grotesk para headlines/displays
/// (acento técnico) y Manrope para cuerpo y labels (legibilidad).
class AppTextTheme {
  AppTextTheme._();

  static TextTheme get dark {
    final headline = GoogleFonts.spaceGroteskTextTheme();
    final body = GoogleFonts.manropeTextTheme();

    return TextTheme(
      displayLarge: headline.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      displayMedium: headline.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      displaySmall: headline.displaySmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineLarge: headline.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      headlineMedium: headline.headlineMedium?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineSmall: headline.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: headline.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: 12,
        color: AppColors.textSecondary,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}
