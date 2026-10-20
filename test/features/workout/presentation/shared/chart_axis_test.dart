import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/chart_axis.dart';

void main() {
  test('compactAxisNumber abrevia miles', () {
    expect(compactAxisNumber(850), '850');
    expect(compactAxisNumber(1250), '1,3k');
    expect(compactAxisNumber(12500), '13k');
    expect(compactAxisNumber(22.5), '22,5');
  });

  test('dateAxisInterval limita las fechas visibles', () {
    expect(dateAxisInterval(4), 1);
    expect(dateAxisInterval(6), 1);
    expect(dateAxisInterval(30), 5);
  });

  test('isExactIndex descarta posiciones intermedias', () {
    expect(isExactIndex(3), isTrue);
    expect(isExactIndex(2.5), isFalse);
  });
}
