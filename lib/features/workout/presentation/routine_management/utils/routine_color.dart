import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';

/// Devuelve un acento de color estable por nombre de rutina o por índice de
/// día. Sirve para que cada rutina/día se reconozca de un vistazo en listas
/// y headers sin pedir al usuario que elija color. La paleta vive en
/// `AppPalette.routineAccents` (una variante por modo, legible como texto);
/// el índice elegido es el mismo en light y dark.
class RoutineColor {
  RoutineColor._();

  /// Color de acento para una rutina dada. Si el nombre está vacío cae al
  /// primario.
  static Color accentFor(BuildContext context, String routineName) {
    if (routineName.isEmpty) return context.colors.primary;
    // 2^31-1: mantiene el acumulador positivo y dentro del rango int32.
    const positiveIntMask = 2147483647;
    final hash = routineName.codeUnits.fold<int>(
      0,
      (acc, c) => (acc + c) & positiveIntMask,
    );
    final pal = context.colors.routineAccents;
    return pal[hash % pal.length];
  }

  /// Color por índice numérico (día N o ejercicio N). Útil para listas
  /// numeradas donde no hay nombre estable.
  static Color byIndex(BuildContext context, int index) {
    final pal = context.colors.routineAccents;
    return pal[index % pal.length];
  }

  /// Relleno suave para poner [accent] (o `primary`) como texto encima:
  /// 8 % del acento sobre `background`, no sobre `surface`. Sobre el gris de
  /// las cards en light ningún tinte llega a 4.5:1; así todos superan 4.5.
  static Color tint(BuildContext context, Color accent) => Color.alphaBlend(
    accent.withValues(alpha: 0.08),
    context.colors.background,
  );
}
