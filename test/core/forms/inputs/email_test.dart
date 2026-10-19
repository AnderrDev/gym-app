import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/forms/inputs/email.dart';

void main() {
  group('Email input', () {
    test('pure no expone error pero is invalid', () {
      const email = Email.pure();
      expect(email.isPure, isTrue);
      expect(email.isValid, isFalse);
    });

    test('vacío → empty', () {
      const email = Email.dirty();
      expect(email.error, EmailValidationError.empty);
    });

    test('mal formato → invalid', () {
      const email = Email.dirty('no-es-email');
      expect(email.error, EmailValidationError.invalid);
    });

    test('formato típico → válido', () {
      const email = Email.dirty('user@example.com');
      expect(email.isValid, isTrue);
      expect(email.error, isNull);
    });

    test('plus addressing → válido', () {
      const email = Email.dirty('user+tag@example.com');
      expect(email.isValid, isTrue);
    });

    test('subdominios → válido', () {
      const email = Email.dirty('user@a.b.example.com');
      expect(email.isValid, isTrue);
    });

    test('extension messages cubren ambos casos', () {
      expect(EmailValidationError.empty.message, contains('email'));
      expect(EmailValidationError.invalid.message, contains('inválido'));
    });
  });
}
