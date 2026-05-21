import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';

/// Devuelve un acento de color estable por nombre de rutina o por índice de
/// día. Sirve para que cada rutina/día se reconozca de un vistazo en listas
/// y headers sin pedir al usuario que elija color. La paleta canónica vive
/// en `AppColors.accentPalette` para no introducir hex literals en features.
class RoutineColor {
  RoutineColor._();

  /// Color de acento para una rutina dada. Si el nombre está vacío cae al
  /// primario brand-stable (no varía con el tema — el acento de rutina debe
  /// ser predecible cross-modo).
  static Color accentFor(String routineName) {
    if (routineName.isEmpty) return AppColors.primary;
    // 2^31-1: mantiene el acumulador positivo y dentro del rango int32.
    const positiveIntMask = 2147483647;
    final hash = routineName.codeUnits.fold<int>(
      0,
      (acc, c) => (acc + c) & positiveIntMask,
    );
    return AppColors.accentPalette[hash % AppColors.accentPalette.length];
  }

  /// Color por índice numérico (día N o ejercicio N). Útil para listas
  /// numeradas donde no hay nombre estable.
  static Color byIndex(int index) {
    final pal = AppColors.accentPalette;
    return pal[index % pal.length];
  }
}
