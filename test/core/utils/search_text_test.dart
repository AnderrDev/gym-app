import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/utils/search_text.dart';

void main() {
  test('normalizeForSearch ignora mayúsculas y tildes', () {
    expect(normalizeForSearch('Bíceps Martillo'), 'biceps martillo');
    expect(
      normalizeForSearch('  EXTENSIÓN de Cuádriceps '),
      'extension de cuadriceps',
    );
    expect(normalizeForSearch('Peña'), 'pena');
  });
}
