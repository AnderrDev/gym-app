import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/utils/clock.dart';

void main() {
  group('Clock', () {
    test('SystemClock devuelve un DateTime cercano a now()', () {
      const clock = SystemClock();
      final before = DateTime.now();
      final got = clock.now();
      final after = DateTime.now();
      expect(
        got.isAtSameMomentAs(before) ||
            (got.isAfter(before) && got.isBefore(after)) ||
            got.isAtSameMomentAs(after),
        isTrue,
      );
    });

    test('FakeClock devuelve siempre el mismo valor', () {
      final fixed = DateTime(2026, 5, 4, 12);
      final clock = FakeClock(fixed);
      expect(clock.now(), fixed);
      expect(clock.now(), fixed);
    });

    test('FakeClock.set actualiza el valor devuelto', () {
      final clock = FakeClock(DateTime(2026));
      final next = DateTime(2027);
      clock.set(next);
      expect(clock.now(), next);
    });
  });
}
