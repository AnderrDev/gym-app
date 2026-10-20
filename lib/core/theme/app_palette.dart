import 'package:flutter/material.dart';

/// Paleta de colores resuelta por brightness, expuesta como `ThemeExtension`.
///
/// Es la única fuente de color de la app: los widgets leen estos tokens vía
/// `context.colors.X` para que el cambio de tema (light/dark) sea automático.
///
/// Reglas de uso (las garantiza `test/core/theme/palette_contrast_test.dart`):
/// - Texto sobre `background`/`surface`: `textPrimary`, `textSecondary`,
///   `primary`, `error`, `info`, `successText`, `warningText` y los
///   `routineAccents` — todos ≥ 4.5:1.
/// - `success`/`warning` son colores de RELLENO (dots, barras, fondos de
///   chip). Como texto en light no llegan a 3:1 — usar `successText` /
///   `warningText`.
/// - Sobre un relleno saturado va su `on*`: `onPrimary`, `onSuccess`,
///   `onWarning`, `onError`.
/// - `textDisabled` es SOLO para controles deshabilitados (WCAG los exime);
///   nunca para texto con información.
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
    required this.onSuccess,
    required this.onWarning,
    required this.onError,
    required this.divider,
    required this.overlay,
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.success,
    required this.successText,
    required this.warning,
    required this.warningText,
    required this.info,
    required this.error,
    required this.routineAccents,
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

  // Texto/iconos pintados SOBRE el relleno homónimo.
  final Color onPrimary;
  final Color onSuccess;
  final Color onWarning;
  final Color onError;

  // Structural
  final Color divider;
  final Color overlay;

  // Brand
  final Color primary;
  final Color primaryDark;
  final Color accent;

  // Semantic
  final Color success;
  final Color successText;
  final Color warning;
  final Color warningText;
  final Color info;
  final Color error;

  /// Acentos de identidad por rutina/día, en orden estable (consumir vía
  /// `RoutineColor`). Ajustados por modo para que se lean como texto/icono.
  final List<Color> routineAccents;

  /// Paleta light (clinical white).
  factory AppPalette.light() => const AppPalette(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF1F4F9),
    surfaceHighlight: Color(0xFFE5EAF2),
    surfaceOverlay: Color(0xFFD2DAE5),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF636366),
    textDisabled: Color(0xFFC7C7CC),
    onPrimary: Color(0xFFFFFFFF),
    onSuccess: Color(0xFF1C1C1E),
    onWarning: Color(0xFF1C1C1E),
    onError: Color(0xFFFFFFFF),
    divider: Color(0xFFCDD5E1),
    overlay: Color(0x99000000),
    // Azul iOS oscurecido: #007AFF daba 4.0:1 con texto blanco (botones) y
    // como texto sobre blanco.
    primary: Color(0xFF0066CC),
    primaryDark: Color(0xFF004C99),
    accent: Color(0xFF5AC8FA),
    success: Color(0xFF34C759),
    successText: Color(0xFF1E7E34),
    warning: Color(0xFFFF9500),
    warningText: Color(0xFFB25000),
    info: Color(0xFF0071A4),
    error: Color(0xFFD70015),
    routineAccents: [
      Color(0xFF4D7A22), // lima
      Color(0xFFC13B3B), // coral
      Color(0xFF8A4FD6), // violeta
      Color(0xFF9E5F00), // ámbar
      Color(0xFF0F7A73), // cian
      Color(0xFFB8327F), // rosa
      Color(0xFF3F63D6), // azul
    ],
  );

  /// Paleta dark (iOS dark, contrastes Apple).
  factory AppPalette.dark() => const AppPalette(
    background: Color(0xFF0A0A0B),
    surface: Color(0xFF16171A),
    surfaceHighlight: Color(0xFF1F2126),
    surfaceOverlay: Color(0xFF2A2D33),
    textPrimary: Color(0xFFF2F2F7),
    textSecondary: Color(0xFFA1A1A6),
    textDisabled: Color(0xFF48484A),
    onPrimary: Color(0xFFFFFFFF),
    onSuccess: Color(0xFF1C1C1E),
    onWarning: Color(0xFF1C1C1E),
    onError: Color(0xFFFFFFFF),
    divider: Color(0xFF34373D),
    overlay: Color(0xCC000000),
    primary: Color(0xFF0A84FF),
    primaryDark: Color(0xFF0040DD),
    accent: Color(0xFF64D2FF),
    success: Color(0xFF30D158),
    successText: Color(0xFF30D158),
    warning: Color(0xFFFF9F0A),
    warningText: Color(0xFFFF9F0A),
    info: Color(0xFF64D2FF),
    error: Color(0xFFFF453A),
    routineAccents: [
      Color(0xFF8BC34A),
      Color(0xFFFF6B6B),
      Color(0xFFB085F5),
      Color(0xFFFFB454),
      Color(0xFF4ECDC4),
      Color(0xFFF15BB5),
      Color(0xFF82A5FF),
    ],
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
    Color? onSuccess,
    Color? onWarning,
    Color? onError,
    Color? divider,
    Color? overlay,
    Color? primary,
    Color? primaryDark,
    Color? accent,
    Color? success,
    Color? successText,
    Color? warning,
    Color? warningText,
    Color? info,
    Color? error,
    List<Color>? routineAccents,
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
      onSuccess: onSuccess ?? this.onSuccess,
      onWarning: onWarning ?? this.onWarning,
      onError: onError ?? this.onError,
      divider: divider ?? this.divider,
      overlay: overlay ?? this.overlay,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      successText: successText ?? this.successText,
      warning: warning ?? this.warning,
      warningText: warningText ?? this.warningText,
      info: info ?? this.info,
      error: error ?? this.error,
      routineAccents: routineAccents ?? this.routineAccents,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceHighlight: l(surfaceHighlight, other.surfaceHighlight),
      surfaceOverlay: l(surfaceOverlay, other.surfaceOverlay),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textDisabled: l(textDisabled, other.textDisabled),
      onPrimary: l(onPrimary, other.onPrimary),
      onSuccess: l(onSuccess, other.onSuccess),
      onWarning: l(onWarning, other.onWarning),
      onError: l(onError, other.onError),
      divider: l(divider, other.divider),
      overlay: l(overlay, other.overlay),
      primary: l(primary, other.primary),
      primaryDark: l(primaryDark, other.primaryDark),
      accent: l(accent, other.accent),
      success: l(success, other.success),
      successText: l(successText, other.successText),
      warning: l(warning, other.warning),
      warningText: l(warningText, other.warningText),
      info: l(info, other.info),
      error: l(error, other.error),
      routineAccents: [
        for (var i = 0; i < routineAccents.length; i++)
          l(
            routineAccents[i],
            other.routineAccents[i % other.routineAccents.length],
          ),
      ],
    );
  }
}
