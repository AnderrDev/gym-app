import 'package:flutter_test/flutter_test.dart';

import 'package:gym_flutter/features/workout/presentation/shared/utils/weight_format.dart';

void main() {
  test('formatDecimal usa coma y un decimal como mucho', () {
    expect(formatDecimal(40), '40');
    expect(formatDecimal(57.5), '57,5');
    expect(formatDecimal(-2.5), '-2,5');
    expect(formatDecimal(12.25), '12,3');
  });

  test('formatLoad muestra peso corporal en vez de 0 kg', () {
    expect(formatLoad(0), 'Peso corporal');
    expect(formatLoad(62.5), '62,5 kg');
  });
}
