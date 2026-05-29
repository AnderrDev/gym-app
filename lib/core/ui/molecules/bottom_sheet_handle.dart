import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';

/// Pequeño "drag handle" gris redondeado que aparece al tope de los bottom
/// sheets a lo largo de la app. Reemplaza el patrón duplicado
/// `Container(width: 40, height: 4, decoration: BoxDecoration(color: ..., borderRadius: BorderRadius.circular(2)))`.
class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({
    super.key,
    this.width = 40,
    this.height = 4,
    this.color,
    this.topPadding = 12,
    this.bottomPadding = 0,
  });

  final double width;
  final double height;

  /// Default null → resuelve a `context.colors.surfaceHighlight` en build.
  /// No puede ser un const default porque el tema activo se decide en
  /// runtime; el caller puede inyectar un color custom si quiere.
  final Color? color;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: Center(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color ?? context.colors.surfaceHighlight,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
