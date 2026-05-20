import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_palette.dart';

/// Accesos ergonómicos al tema sin tener que tipear
/// `Theme.of(context).extension<AppPalette>()!` o
/// `Theme.of(context).textTheme` cada vez.
///
/// Patrón canónico para nuevos widgets:
///
/// ```dart
/// Container(
///   color: context.colors.surface,
///   child: Text('Hola', style: context.text.bodyLarge),
/// );
/// ```
extension AppThemeAccess on BuildContext {
  /// Paleta resuelta para el brightness actual.
  AppPalette get colors {
    final ext = Theme.of(this).extension<AppPalette>();
    assert(
      ext != null,
      'AppPalette no está registrada en ThemeData.extensions. '
      'Revisar AppTheme.light()/dark().',
    );
    return ext ?? AppPalette.light();
  }

  /// `TextTheme` derivado del `ColorScheme` activo.
  TextTheme get text => Theme.of(this).textTheme;

  /// `ColorScheme` Material 3.
  ColorScheme get scheme => Theme.of(this).colorScheme;

  /// Brightness resuelto del tema activo.
  Brightness get brightness => Theme.of(this).brightness;

  /// `true` si el tema activo está en modo oscuro.
  bool get isDark => brightness == Brightness.dark;
}
