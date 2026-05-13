import 'package:formz/formz.dart';

enum PasswordValidationError { empty, tooShort }

class Password extends FormzInput<String, PasswordValidationError> {
  const Password.pure() : super.pure('');
  const Password.dirty([super.value = '']) : super.dirty();

  static const int minLength = 8;

  @override
  PasswordValidationError? validator(String value) {
    if (value.isEmpty) return PasswordValidationError.empty;
    if (value.length < minLength) return PasswordValidationError.tooShort;
    return null;
  }
}

extension PasswordValidationErrorX on PasswordValidationError {
  String get message {
    switch (this) {
      case PasswordValidationError.empty:
        return 'Ingresá tu contraseña';
      case PasswordValidationError.tooShort:
        return 'Mínimo ${Password.minLength} caracteres';
    }
  }
}
