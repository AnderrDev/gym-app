import 'package:flutter/material.dart';

import 'package:gym_flutter/core/platform/capabilities.dart';
import 'package:gym_flutter/core/theme/app_palette.dart';
import 'package:gym_flutter/core/theme/app_text_theme.dart';
import 'package:gym_flutter/core/theme/tokens/durations.dart';
import 'package:gym_flutter/core/theme/tokens/elevations.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Tema canónico de la app. `MaterialApp.router` consume `AppTheme.light()` y
/// `AppTheme.dark()`; el `themeMode` se resuelve desde `SettingsBloc`. Los
/// component themes aquí declarados deben cubrir todo el styling para que
/// `lib/features/` no necesite literales visuales — cuando un widget necesite
/// un color o text style debe leerlo vía `context.colors.*` / `context.text.*`
/// (ver `theme_context.dart`).
class AppTheme {
  AppTheme._();

  /// Tema claro (clinical white). Default histórico de la app.
  static ThemeData light() => _build(AppPalette.light(), Brightness.light);

  /// Tema oscuro (iOS dark). Nuevo en Phase Theme.
  static ThemeData dark() => _build(AppPalette.dark(), Brightness.dark);

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final textTheme = AppTextTheme.build(palette);
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      secondary: palette.accent,
      onSecondary: palette.onPrimary,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      surfaceContainerHighest: palette.surfaceHighlight,
      error: palette.error,
      onError: palette.onPrimary,
      outline: palette.divider,
      outlineVariant: palette.surfaceOverlay,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: Elevations.none,
        // Una sombra mínima separa la AppBar del contenido al hacer scroll
        // sin "pesar". El divider del tema sirve también de shadow tint.
        scrolledUnderElevation: Elevations.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: palette.divider,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: palette.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: Elevations.card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceHighlight,
        selectedColor: palette.primary,
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: palette.onPrimary,
        ),
        side: BorderSide(color: palette.divider),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: Elevations.overlay,
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: palette.surface,
        modalBarrierColor: palette.overlay,
        elevation: Elevations.overlay,
        showDragHandle: true,
        dragHandleColor: palette.surfaceOverlay,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xxl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceHighlight,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: palette.textPrimary,
        ),
        actionTextColor: palette.primary,
        behavior: SnackBarBehavior.floating,
        elevation: Elevations.overlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: palette.textDisabled,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: palette.textSecondary,
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: palette.primary,
        ),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: palette.error),
        prefixIconColor: palette.textSecondary,
        suffixIconColor: palette.textSecondary,
        border: _outlineBorder(palette.divider),
        enabledBorder: _outlineBorder(palette.divider),
        focusedBorder: _outlineBorder(palette.primary, width: 1.5),
        errorBorder: _outlineBorder(palette.error),
        focusedErrorBorder: _outlineBorder(palette.error, width: 1.5),
        disabledBorder: _outlineBorder(palette.surfaceHighlight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: palette.onPrimary,
          backgroundColor: palette.primary,
          disabledForegroundColor: palette.textDisabled,
          disabledBackgroundColor: palette.surfaceHighlight,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: Spacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          textStyle: textTheme.labelLarge,
          elevation: Elevations.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: palette.onPrimary,
          backgroundColor: palette.primary,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: Spacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: Spacing.md,
          ),
          side: BorderSide(color: palette.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.textPrimary,
          backgroundColor: Colors.transparent,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: palette.textPrimary, size: 24),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        linearTrackColor: palette.surfaceHighlight,
        circularTrackColor: palette.surfaceHighlight,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: palette.primary,
        unselectedLabelColor: palette.textSecondary,
        indicatorColor: palette.primary,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.surfaceHighlight,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        textStyle: textTheme.labelMedium,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: Capabilities.isWeb
            // En web todos los targets caen al fade corto (140ms, sin
            // slide horizontal). El slide-from-right de Cupertino o el
            // Material default se sienten "appy" cuando se navega en
            // browser — el feel canónico de SPA es transición de opacity
            // rápida o sin transición.
            ? const {
                TargetPlatform.iOS: _WebFadeTransitionsBuilder(),
                TargetPlatform.macOS: _WebFadeTransitionsBuilder(),
                TargetPlatform.android: _WebFadeTransitionsBuilder(),
                TargetPlatform.linux: _WebFadeTransitionsBuilder(),
                TargetPlatform.windows: _WebFadeTransitionsBuilder(),
              }
            : const {
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
              },
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.primary;
          return palette.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primary.withValues(alpha: 0.4);
          }
          return palette.surfaceHighlight;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(palette.onPrimary),
        side: BorderSide(color: palette.divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xs),
        ),
      ),
      // Extensions: AppPalette habilita acceso vía `context.colors`,
      // `_AppMotion` expone duraciones para sweeps.
      extensions: <ThemeExtension<dynamic>>[
        palette,
        const _AppMotion(fast: AppDurations.fast, medium: AppDurations.medium),
      ],
    );
  }

  static OutlineInputBorder _outlineBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Alias legacy. `MaterialApp.theme` lo consumía como `AppTheme.dark` antes
  /// del refactor a builder dual. Mantener hasta que `main.dart` y otros
  /// pocos call-sites migren a `AppTheme.light()/dark()`.
  @Deprecated('Usar AppTheme.light() o AppTheme.dark()')
  static ThemeData get darkLegacy => light();
}

/// PageTransitionsBuilder usado solo en web (todos los targets).
///
/// Salta el slide horizontal de Cupertino y el FadeForwards de Material —
/// renderiza un `FadeTransition` corto (~140 ms) sin desplazamiento. El
/// feel resultante es de "router de SPA" (la pantalla aparece) en vez de
/// "stack de pantallas físicas" (push desde la derecha).
///
/// Se usa la duración por defecto del Navigator (`transitionDuration` lo
/// puede sobrescribir el route). 140ms es lo bastante corto para sentirse
/// instantáneo en desktop browser sin parecer un cut sin transición.
class _WebFadeTransitionsBuilder extends PageTransitionsBuilder {
  const _WebFadeTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 140);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 90);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}

/// Extensión de tema con duraciones de animación expuestas en `Theme.of`.
class _AppMotion extends ThemeExtension<_AppMotion> {
  const _AppMotion({required this.fast, required this.medium});

  final Duration fast;
  final Duration medium;

  @override
  ThemeExtension<_AppMotion> copyWith({Duration? fast, Duration? medium}) =>
      _AppMotion(fast: fast ?? this.fast, medium: medium ?? this.medium);

  @override
  ThemeExtension<_AppMotion> lerp(
    covariant ThemeExtension<_AppMotion>? other,
    double t,
  ) => this;
}
