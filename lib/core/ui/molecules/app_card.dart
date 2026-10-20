import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Card unificada — `surface` sólida con borde `divider`. Reemplaza a los
/// `Container(decoration: BoxDecoration(...))` repetidos. La app no usa
/// superficies translúcidas (glass): sobre fondos lisos sólo ensuciaban el
/// color y bajaban el contraste del contenido.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(Radii.lg);
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: context.colors.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: padding ?? const EdgeInsets.all(Spacing.lg),
            decoration: BoxDecoration(
              borderRadius: radius,
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
}
