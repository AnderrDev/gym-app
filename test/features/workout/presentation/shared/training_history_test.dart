import 'package:flutter_test/flutter_test.dart';

import 'package:gym_flutter/features/workout/domain/entities/routine_history_session.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/training_history.dart';

RoutineHistorySession _session(DateTime date, double volume) =>
    RoutineHistorySession(
      sessionDate: date,
      routineDayId: 'd1',
      routineDayName: 'Torso',
      totalVolume: volume,
      totalReps: 10,
      setCount: 3,
    );

void main() {
  group('weeklyTotals', () {
    test('agrupa por semana de lunes a domingo e incluye semanas vacías', () {
      final weeks = weeklyTotals(
        [
          _session(DateTime(2026, 10, 19), 1000), // lunes
          _session(DateTime(2026, 10, 25), 500), // domingo, misma semana
          _session(DateTime(2026, 10, 5), 800), // hace dos semanas
          _session(DateTime(2026, 8, 3), 999), // fuera de la ventana
        ],
        lastWeekStart: DateTime(2026, 10, 22), // cualquier día de la semana
        weeks: 3,
      );

      expect(weeks.map((w) => w.weekStart), [
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 12),
        DateTime(2026, 10, 19),
      ]);
      expect(weeks.map((w) => w.sessions), [1, 0, 2]);
      expect(weeks.map((w) => w.volume), [800, 0, 1500]);
    });

    test('no se descuadra con el cambio de hora de octubre', () {
      // 25-oct-2026 cambia la hora en Europa: sumar 7×24 h desde el lunes
      // 19 caía en el domingo.
      final weeks = weeklyTotals(
        [_session(DateTime(2026, 10, 26), 100)],
        lastWeekStart: DateTime(2026, 10, 26),
        weeks: 2,
      );
      expect(weeks.last.weekStart, DateTime(2026, 10, 26));
      expect(weeks.last.sessions, 1);
      expect(weeks.first.weekStart, DateTime(2026, 10, 19));
    });
  });

  group('percentChange', () {
    test('calcula el cambio relativo', () {
      expect(percentChange(110, 100), closeTo(10, 1e-9));
      expect(percentChange(50, 100), closeTo(-50, 1e-9));
    });

    test('sin base con la que comparar devuelve null, no +100 %', () {
      expect(percentChange(1200, 0), isNull);
    });
  });
}
