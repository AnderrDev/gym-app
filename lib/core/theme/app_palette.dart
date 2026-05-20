import 'package:flutter/material.dart';

/// Paleta de colores resuelta por brightness, expuesta como `ThemeExtension`.
///
/// Widgets deben leer estos tokens vía `context.colors.X` en lugar de
/// `AppColors.X` para que el cambio de tema (light/dark) sea automático.
/// `AppColors` queda solo para colores brand-stable (primary/accent/semantic
/// y la paleta de acentos por rutina) y para legado durante la migración.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceHighlight,
    required this.surfaceOverlay,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.onPrimary,
    required this.divider,
    required this.overlay,
    required this.glassFill,
    required this.glassBorder,
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.success,
    required this.warning,
    required this.info,
    required this.error,
  });

  // Surfaces — jerarquía de "altura" sobre el scaffold.
  final Color background;
  final Color surface;
  final Color surfaceHighlight;
  final Color surfaceOverlay;

  // Text — pintado sobre `surface`/`background`.
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  /// Color para texto/iconos pintados SOBRE `primary`/`error`/`success`/etc.
  final Color onPrimary;

  // Structural
  final Color divider;
  final Color overlay;

  // Glass surfaces (auth, hero cards)
  final Color glassFill;
  final Color glassBorder;

  // Brand (estables, idénticos en ambos modos salvo ajuste fino)
  final Color primary;
  final Color primaryDark;
  final Color accent;

  // Semantic
  final Color success;
  final Color warning;
  final Color info;
  final Color error;

  /// Paleta light (clinical white). Coincide con `AppColors.*` legado.
  factory AppPalette.light() => const AppPalette(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF1F4F9),
    surfaceHighlight: Color(0xFFE5EAF2),
    surfaceOverlay: Color(0xFFD2DAE5),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF6E6E73),
    textDisabled: Color(0xFFC7C7CC),
    onPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFDCE3EE),
    overlay: Color(0x99000000),
    glassFill: Color(0x0F000000),
    glassBorder: Color(0x1F000000),
    primary: Color(0xFF007AFF),
    primaryDark: Color(0xFF0051D5),
    accent: Color(0xFF5AC8FA),
    success: Color(0xFF34C759),
    warning: Color(0xFFFF9500),
    info: Color(0xFF5AC8FA),
    error: Color(0xFFFF3B30),
  );

  /// Paleta dark (iOS dark, contrastes Apple). `primary` usa el variant azul
  /// más claro recomendado para fondos oscuros.
  factory AppPalette.dark() => const AppPalette(
    background: Color(0xFF0A0A0B),
    surface: Color(0xFF16171A),
    surfaceHighlight: Color(0xFF1F2126),
    surfaceOverlay: Color(0xFF2A2D33),
    textPrimary: Color(0xFFF2F2F7),
    textSecondary: Color(0xFFA1A1A6),
    textDisabled: Color(0xFF48484A),
    onPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFF2C2E33),
    overlay: Color(0xCC000000),
    glassFill: Color(0x14FFFFFF),
    glassBorder: Color(0x24FFFFFF),
    primary: Color(0xFF0A84FF),
    primaryDark: Color(0xFF0040DD),
    accent: Color(0xFF64D2FF),
    success: Color(0xFF30D158),
    warning: Color(0xFFFF9F0A),
    info: Color(0xFF64D2FF),
    error: Color(0xFFFF453A),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHighlight,
    Color? surfaceOverlay,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? onPrimary,
    Color? divider,
    Color? overlay,
    Color? glassFill,
    Color? glassBorder,
    Color? primary,
    Color? primaryDark,
    Color? accent,
    Color? success,
    Color? warning,
    Color? info,
    Color? error,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceHighlight: surfaceHighlight ?? this.surfaceHighlight,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      onPrimary: onPrimary ?? this.onPrimary,
      divider: divider ?? this.divider,
      overlay: overlay ?? this.overlay,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      error: error ?? this.error,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHighlight:
          Color.lerp(surfaceHighlight, other.surfaceHighlight, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}
