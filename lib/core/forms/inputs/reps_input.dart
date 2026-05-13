import 'package:formz/formz.dart';

enum RepsValidationError { empty, notAnInt, negative, tooLarge }

/// Repeticiones, entero ≥ 0 con tope superior pragmático.
class RepsInput extends FormzInput<String, RepsValidationError> {
  const RepsInput.pure() : super.pure('');
  const RepsInput.dirty([super.value = '']) : super.dirty();

  static const int maxReps = 999;

  static int? tryParse(String raw) {
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  int? get parsed => tryParse(value);

  @override
  RepsValidationError? validator(String value) {
    if (value.isEmpty) return RepsValidationError.empty;
    final parsed = tryParse(value);
    if (parsed == null) return RepsValidationError.notAnInt;
    if (parsed < 0) return RepsValidationError.negative;
    if (parsed > maxReps) return RepsValidationError.tooLarge;
    return null;
  }
}

extension RepsValidationErrorX on RepsValidationError {
  String get message {
    switch (this) {
      case RepsValidationError.empty:
        return 'Ingresá las reps';
      case RepsValidationError.notAnInt:
        return 'Solo enteros';
      case RepsValidationError.negative:
        return 'No puede ser negativo';
      case RepsValidationError.tooLarge:
        return 'Máximo ${RepsInput.maxReps} reps';
    }
  }
}
