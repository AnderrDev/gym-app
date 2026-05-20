import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:gym_flutter/core/platform/capabilities.dart';

/// Widget que pinta un "glass effect" detrás de [child].
///
/// En plataformas con [Capabilities.supportsCheapBlur] (= mobile nativo)
/// usa un `BackdropFilter` real con `ImageFilter.blur` — samplea el
/// contenido detrás y lo desenfoca. En web (canvaskit) esto es caro: el
/// blur fuerza operaciones pixel-by-pixel en CPU y mata el frame
/// budget en pantallas con varias cards. Acá caemos a un `Container`
/// con un tint sólido equivalente que se ve casi igual y vuelve el
/// repaint barato.
///
/// El `tintColor` y la `tintOpacity` se aplican EN AMBOS modos; el
/// `blurSigma` solo aplica donde el blur es barato. Esto permite que
/// el call site tenga el mismo input visual sin if-elses externos.
class AdaptiveBlur extends StatelessWidget {
  const AdaptiveBlur({
    super.key,
    required this.child,
    this.blurSigma = 20.0,
    this.tintColor,
    this.tintOpacity = 0.05,
    this.borderRadius,
  });

  final Widget child;

  /// Sigma del `ImageFilter.blur` (mismo en X e Y). Ignorado cuando
  /// `Capabilities.supportsCheapBlur` es false.
  final double blurSigma;

  /// Tint que se superpone — null = `Colors.transparent`. En tema
  /// claro suele ser `AppColors.textPrimary` con baja alpha para
  /// que el tinte vaya hacia oscuro sobre blanco.
  final Color? tintColor;

  /// Alpha del tint. Aplicado en ambos modos.
  final double tintOpacity;

  /// Si se pasa, el widget recorta a este radio (necesario cuando el
  /// blur sample necesita conocer bounds).
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final tint = (tintColor ?? Colors.transparent).withValues(alpha: tintOpacity);
    final tinted = Container(color: tint, child: child);

    if (!Capabilities.supportsCheapBlur) {
      // Web / canvaskit: skip BackdropFilter, solo tint.
      if (borderRadius != null) {
        return ClipRRect(borderRadius: borderRadius!, child: tinted);
      }
      return tinted;
    }

    final blurred = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: tinted,
    );
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: blurred);
    }
    return blurred;
  }
}
