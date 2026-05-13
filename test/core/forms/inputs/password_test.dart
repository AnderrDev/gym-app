import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/forms/inputs/password.dart';

void main() {
  group('Password input', () {
    test('vacío → empty', () {
      const p = Password.dirty();
      expect(p.error, PasswordValidationError.empty);
    });

    test('corto → tooShort', () {
      const p = Password.dirty('1234567');
      expect(p.error, PasswordValidationError.tooShort);
    });

    test('exacto en minLength → válido', () {
      final p = Password.dirty('a' * Password.minLength);
      expect(p.isValid, isTrue);
    });

    test('largo → válido', () {
      const p = Password.dirty('Str0ng!Pass');
      expect(p.isValid, isTrue);
    });

    test('extension messages cubren ambos casos', () {
      expect(PasswordValidationError.empty.message, contains('contraseña'));
      expect(PasswordValidationError.tooShort.message, contains('Mínimo'));
    });
  });
}
