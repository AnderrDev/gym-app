import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/forms/inputs/weight_input.dart';

void main() {
  group('WeightInput', () {
    test('vacío → empty', () {
      const w = WeightInput.dirty();
      expect(w.error, WeightValidationError.empty);
    });

    test('NaN → notANumber', () {
      const w = WeightInput.dirty('foo');
      expect(w.error, WeightValidationError.notANumber);
    });

    test('negativo → negative', () {
      const w = WeightInput.dirty('-5');
      expect(w.error, WeightValidationError.negative);
    });

    test('valor sensato → válido y parsed correcto', () {
      const w = WeightInput.dirty('80.5');
      expect(w.isValid, isTrue);
      expect(w.parsed, 80.5);
    });

    test('coma decimal → válido', () {
      const w = WeightInput.dirty('80,5');
      expect(w.isValid, isTrue);
      expect(w.parsed, 80.5);
    });

    test('por encima del tope → tooLarge', () {
      const w = WeightInput.dirty('1500');
      expect(w.error, WeightValidationError.tooLarge);
    });
  });
}
