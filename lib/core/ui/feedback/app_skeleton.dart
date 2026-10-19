import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';

/// Wrapper de shimmer alineado con la paleta dark.
///
/// Para una pantalla específica, componer múltiples [AppSkeletonTile] dentro
/// del mismo [AppSkeleton] para que compartan el mismo gradient en
/// movimiento.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? context.colors.surfaceHighlight,
      highlightColor: highlightColor ?? context.colors.surfaceOverlay,
      child: child,
    );
  }
}

/// Bloque rectangular para usar como pieza dentro de un [AppSkeleton].
class AppSkeletonTile extends StatelessWidget {
  const AppSkeletonTile({super.key, this.width, this.height = 16, this.radius});

  /// Variante circular (avatar/icon).
  const AppSkeletonTile.circle({super.key, double size = 40})
    : width = size,
      height = size,
      radius = const Radius.circular(999);

  /// Variante línea (texto).
  const AppSkeletonTile.line({super.key, this.width, this.height = 12})
    : radius = const Radius.circular(Radii.xs);

  final double? width;
  final double height;
  final Radius? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surfaceHighlight,
        borderRadius: BorderRadius.all(
          radius ?? const Radius.circular(Radii.sm),
        ),
      ),
    );
  }
}
