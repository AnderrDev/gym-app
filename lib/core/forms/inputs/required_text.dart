import 'package:formz/formz.dart';

enum RequiredTextValidationError { empty, tooShort }

/// Texto obligatorio con mínimo de caracteres opcional. Útil para nombre
/// completo, nombre de rutina, nombre de día, etc.
class RequiredText extends FormzInput<String, RequiredTextValidationError> {
  const RequiredText.pure({this.minLength = 1}) : super.pure('');
  const RequiredText.dirty(super.value, {this.minLength = 1}) : super.dirty();

  final int minLength;

  @override
  RequiredTextValidationError? validator(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return RequiredTextValidationError.empty;
    if (trimmed.length < minLength) {
      return RequiredTextValidationError.tooShort;
    }
    return null;
  }
}

extension RequiredTextValidationErrorX on RequiredTextValidationError {
  String message(int minLength) {
    switch (this) {
      case RequiredTextValidationError.empty:
        return 'Este campo es obligatorio';
      case RequiredTextValidationError.tooShort:
        return 'Mínimo $minLength caracteres';
    }
  }
}
