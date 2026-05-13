import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Estilos cacheados una sola vez. Antes eran `get` que reconstruían
/// `TextStyle` (y resolvían la fuente vía `GoogleFonts`) en cada lectura,
/// multiplicado por ~125 call-sites + rebuilds. Como `final` se computan al
/// primer acceso y se reutiliza la misma instancia.
class AppTextStyles {
  AppTextStyles._();

  // Space Grotesk for Headings and Numbers (Technical/Scientific vibe)
  static final TextStyle heading1 = GoogleFonts.spaceGrotesk(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static final TextStyle heading2 = GoogleFonts.spaceGrotesk(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle displayNumber = GoogleFonts.spaceGrotesk(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  // Manrope for body text (High readability)
  static final TextStyle bodyLarge = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodyMedium = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static final TextStyle label = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static final TextStyle bodySmall = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
}
