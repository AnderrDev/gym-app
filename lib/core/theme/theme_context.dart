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
  ///
  /// Si el `ThemeData` activo no registró `AppPalette` (típico en widget
  /// tests con `MaterialApp` default), cae al palette light por defecto en
  /// vez de romper. En la app real `main.dart` siempre usa
  /// `AppTheme.light()/dark()`, que sí registran la extension.
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light();

  /// `TextTheme` derivado del `ColorScheme` activo.
  TextTheme get text => Theme.of(this).textTheme;

  /// `ColorScheme` Material 3.
  ColorScheme get scheme => Theme.of(this).colorScheme;

  /// Brightness resuelto del tema activo.
  Brightness get brightness => Theme.of(this).brightness;

  /// `true` si el tema activo está en modo oscuro.
  bool get isDark => brightness == Brightness.dark;
}
