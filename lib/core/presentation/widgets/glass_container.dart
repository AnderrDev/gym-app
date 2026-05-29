import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/ui/adaptive/adaptive_blur.dart';

/// Card-style con efecto glass — wrapper de [AdaptiveBlur] que agrega
/// padding/margin/border al estilo "tarjeta". En mobile usa
/// `BackdropFilter` real, en web cae a un tint sólido (ver
/// [AdaptiveBlur]). Los call sites no se enteran del switch.
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
    final radius = borderRadius ?? BorderRadius.circular(16);
    // `textPrimary` se invierte entre light/dark, así el tinte del glass
    // siempre contrasta con el fondo de la app.
    final card = AdaptiveBlur(
      blurSigma: blur,
      tintColor: context.colors.textPrimary,
      tintOpacity: opacity,
      borderRadius: radius,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: (borderColor ?? context.colors.textPrimary).withValues(
              alpha: borderOpacity,
            ),
            width: 1.0,
          ),
        ),
        child: child,
      ),
    );
    if (margin == null) return card;
    return Padding(padding: margin!, child: card);
  }
}
