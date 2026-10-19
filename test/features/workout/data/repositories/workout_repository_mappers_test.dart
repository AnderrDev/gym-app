import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/data/repositories/workout_repository_mappers.dart';

void main() {
  group('mapRoutineSessionRows', () {
    Map<String, dynamic> row(String date, double weight) => {
      'session_date': date,
      'routine_day_id': 'd1',
      'routine_days': {'name': 'Push'},
      'set_logs': [
        {'actual_weight': weight, 'actual_reps': 10},
      ],
    };

    test('devuelve la sesión más reciente primero aunque la query venga '
        'ascendente', () {
      // La query de getRoutineStats ordena ascendente; la gráfica y la lista
      // asumen descendente. Antes la gráfica tomaba la sesión más antigua
      // como "actual".
      final result = mapRoutineSessionRows([
        row('2026-10-01', 50),
        row('2026-10-08', 60),
        row('2026-10-15', 70),
      ]);
      expect(result.map((s) => s.sessionDate), [
        DateTime(2026, 10, 15),
        DateTime(2026, 10, 8),
        DateTime(2026, 10, 1),
      ]);
      expect(result.first.totalVolume, 700);
    });
  });
}
