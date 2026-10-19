import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/forms/inputs/reps_input.dart';

void main() {
  group('RepsInput', () {
    test('vacío → empty', () {
      const r = RepsInput.dirty();
      expect(r.error, RepsValidationError.empty);
    });

    test('decimal → notAnInt (solo enteros)', () {
      const r = RepsInput.dirty('8.5');
      expect(r.error, RepsValidationError.notAnInt);
    });

    test('negativo → negative', () {
      const r = RepsInput.dirty('-1');
      expect(r.error, RepsValidationError.negative);
    });

    test('valor sensato → válido', () {
      const r = RepsInput.dirty('10');
      expect(r.isValid, isTrue);
      expect(r.parsed, 10);
    });

    test('por encima del tope → tooLarge', () {
      const r = RepsInput.dirty('1500');
      expect(r.error, RepsValidationError.tooLarge);
    });
  });
}
