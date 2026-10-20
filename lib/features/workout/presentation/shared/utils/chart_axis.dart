// Helpers de ejes compartidos por las gráficas de progreso.

import 'package:gym_flutter/features/workout/presentation/shared/utils/weight_format.dart';

/// "850", "1,2k", "12k" (coma decimal, como el resto de pesos de la app):
/// en el eje Y "12500 kg·reps" a 9 px no cabía.
String compactAxisNumber(double v) {
  final abs = v.abs();
  if (abs >= 10000) return '${(v / 1000).toStringAsFixed(0)}k';
  if (abs >= 1000) {
    return '${(v / 1000).toStringAsFixed(1).replaceAll('.', ',')}k';
  }
  return formatDecimal(v);
}

/// Intervalo del eje X para no pasar de ~[maxLabels] fechas: con muchas
/// sesiones las etiquetas se pisaban.
double dateAxisInterval(int points, {int maxLabels = 6}) =>
    points <= maxLabels ? 1 : (points / maxLabels).ceilToDouble();

/// fl_chart puede pedir títulos en posiciones no enteras: sólo se pinta la
/// fecha en índices exactos (si no, se repetía la misma fecha).
bool isExactIndex(double value) => value == value.roundToDouble();
