import 'package:flutter/material.dart';

import 'package:gym_flutter/core/presentation/widgets/glass_container.dart';
import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Variante visual de [AppCard].
enum AppCardVariant {
  /// Card normal — surface elevada con borde sutil.
  surface,

  /// Card translúcida (auth pages, hero cards).
  glass,
}

/// Card unificada. Reemplaza a los `Container(decoration: BoxDecoration(...))`
/// repetidos. La variante `glass` delega en `GlassContainer` que ya estaba en
/// el repo y queda como caso de uso interno de `AppCard.glass`.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.surface,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.borderColor,
  });

  /// Atajo para crear la variante glass sin pasar enum.
  const AppCard.glass({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.borderColor,
  }) : variant = AppCardVariant.glass;

  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(Spacing.lg);
    final effectiveRadius = borderRadius ?? BorderRadius.circular(Radii.lg);

    if (variant == AppCardVariant.glass) {
      final glassRadius = effectiveRadius is BorderRadius
          ? effectiveRadius
          : BorderRadius.circular(Radii.lg);
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: GlassContainer(
          padding: effectivePadding,
          borderRadius: glassRadius,
          borderColor: borderColor ?? context.colors.glassBorder,
          child: _wrapTap(child),
        ),
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: context.colors.surface,
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius is BorderRadius
              ? effectiveRadius
              : BorderRadius.circular(Radii.lg),
          child: Container(
            padding: effectivePadding,
            decoration: BoxDecoration(
              borderRadius: effectiveRadius,
              border: Border.all(
                color: borderColor ?? context.colors.divider,
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _wrapTap(Widget c) {
    if (onTap == null) return c;
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius is BorderRadius
          ? (borderRadius as BorderRadius?)
          : null,
      child: c,
    );
  }
}
