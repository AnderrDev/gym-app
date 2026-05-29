import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/forms/inputs/required_text.dart';

void main() {
  group('RequiredText input', () {
    test('vacío → empty', () {
      const t = RequiredText.dirty('');
      expect(t.error, RequiredTextValidationError.empty);
    });

    test('solo espacios → empty (trim)', () {
      const t = RequiredText.dirty('   ');
      expect(t.error, RequiredTextValidationError.empty);
    });

    test('cumple minLength → válido', () {
      const t = RequiredText.dirty('Ander', minLength: 2);
      expect(t.isValid, isTrue);
    });

    test('por debajo de minLength → tooShort', () {
      const t = RequiredText.dirty('A', minLength: 2);
      expect(t.error, RequiredTextValidationError.tooShort);
    });

    test('extension formatea minLength en mensaje', () {
      expect(
        RequiredTextValidationError.tooShort.message(3),
        contains('Mínimo 3'),
      );
    });
  });
}
