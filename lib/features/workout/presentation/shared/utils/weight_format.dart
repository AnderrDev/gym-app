import 'package:intl/intl.dart';

/// Número con un decimal como mucho y coma decimal (es): `40` → "40",
/// `37.5` → "37,5". Evita el `toStringAsFixed(0)` que redondeaba 37.5 a
/// "38". Los campos de peso aceptan coma o punto al leer.
String formatDecimal(double value) {
  final text = value % 1 == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return text.replaceAll('.', ',');
}

/// Peso en kg sin unidad: "40", "57,5".
String formatWeight(double kg) => formatDecimal(kg);

/// "60 kg" o "Peso corporal" cuando el peso es 0 (ejercicios sin carga):
/// "0 kg × 10" parecía un error.
String formatLoad(double kg) =>
    kg == 0 ? 'Peso corporal' : '${formatWeight(kg)} kg';

/// Volumen (suma de peso × reps) redondeado y con separador de miles es:
/// `12450.0` → "12.450", `1800` → "1.800".
String formatVolume(double kg) => _volumeFormat.format(kg.round());

final _volumeFormat = NumberFormat.decimalPattern('es');
