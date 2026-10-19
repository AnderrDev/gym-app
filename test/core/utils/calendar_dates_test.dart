import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/utils/calendar_dates.dart';

void main() {
  group('AppCalendar', () {
    test('addDays cruza el fin del horario de verano sin perder el día', () {
      // En Europe/Madrid el 25-oct-2026 dura 25h; sumar 7*24h caía en el
      // domingo 23:00 y la navegación semanal se quedaba atascada.
      final next = AppCalendar.addDays(DateTime(2026, 10, 19), 7);
      expect(next, DateTime(2026, 10, 26));
      expect(AppCalendar.startOfWeek(next), DateTime(2026, 10, 26));
    });

    test('addDays cruza el inicio del horario de verano', () {
      expect(
        AppCalendar.addDays(DateTime(2027, 3, 22), 7),
        DateTime(2027, 3, 29),
      );
    });

    test('addDays negativo y entre meses', () {
      expect(
        AppCalendar.addDays(DateTime(2026, 11, 2), -7),
        DateTime(2026, 10, 26),
      );
      expect(
        AppCalendar.addDays(DateTime(2026, 12, 28), 7),
        DateTime(2027, 1, 4),
      );
    });

    test('startOfWeek devuelve el lunes a medianoche', () {
      expect(
        AppCalendar.startOfWeek(DateTime(2026, 10, 25, 22, 30)),
        DateTime(2026, 10, 19),
      );
      expect(
        AppCalendar.startOfWeek(DateTime(2026, 10, 19)),
        DateTime(2026, 10, 19),
      );
    });
  });
}
