import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  final Color? borderColor;
  final double borderOpacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.15,
    this.borderRadius,
    this.padding,
    this.margin,
    this.borderColor,
    this.borderOpacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(16);

    return margin != null
        ? Padding(padding: margin!, child: _buildGlass(defaultBorderRadius))
        : _buildGlass(defaultBorderRadius);
  }

  Widget _buildGlass(BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // `textPrimary` invierte automaticamente entre light/dark, asi el
            // tinte del glass siempre contrasta con el fondo de la app.
            color: AppColors.textPrimary.withValues(alpha: opacity),
            borderRadius: radius,
            border: Border.all(
              color: (borderColor ?? AppColors.textPrimary).withValues(
                alpha: borderOpacity,
              ),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
