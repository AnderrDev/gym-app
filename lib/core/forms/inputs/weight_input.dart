import 'package:formz/formz.dart';

enum WeightValidationError { empty, notANumber, negative, tooLarge }

/// Peso en kilogramos. Acepta coma o punto como separador decimal.
class WeightInput extends FormzInput<String, WeightValidationError> {
  const WeightInput.pure() : super.pure('');
  const WeightInput.dirty([super.value = '']) : super.dirty();

  /// Tope superior pragmático: 1000 kg cubre cualquier ejercicio sensato y
  /// detecta typos (ej: olvidar el separador decimal).
  static const double maxKg = 1000;

  static double? tryParse(String raw) {
    if (raw.isEmpty) return null;
    return double.tryParse(raw.replaceAll(',', '.'));
  }

  /// Valor parseado (`null` si el input es inválido o vacío).
  double? get parsed => tryParse(value);

  @override
  WeightValidationError? validator(String value) {
    if (value.isEmpty) return WeightValidationError.empty;
    final parsed = tryParse(value);
    if (parsed == null) return WeightValidationError.notANumber;
    if (parsed < 0) return WeightValidationError.negative;
    if (parsed > maxKg) return WeightValidationError.tooLarge;
    return null;
  }
}

extension WeightValidationErrorX on WeightValidationError {
  String get message {
    switch (this) {
      case WeightValidationError.empty:
        return 'Ingresá el peso';
      case WeightValidationError.notANumber:
        return 'Peso inválido';
      case WeightValidationError.negative:
        return 'No puede ser negativo';
      case WeightValidationError.tooLarge:
        return 'Máximo ${WeightInput.maxKg.toStringAsFixed(0)} kg';
    }
  }
}
