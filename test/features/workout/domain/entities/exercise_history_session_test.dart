import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_history_session.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';

void main() {
  SetLog set(double weight, int reps, [int index = 1]) => SetLog(
    sessionId: 's1',
    exerciseId: 'e1',
    actualWeight: weight,
    actualReps: reps,
    setIndex: index,
  );

  ExerciseHistorySession session(List<SetLog> logs) =>
      ExerciseHistorySession(sessionDate: DateTime(2026, 10, 1), logs: logs);

  group('estimated1RM', () {
    test('con 1 rep el 1RM es el propio peso', () {
      expect(session([set(100, 1)]).estimated1RM, 100);
    });

    test('Epley para series de pocas reps', () {
      expect(session([set(100, 5)]).estimated1RM, closeTo(116.67, 0.01));
    });

    test('ignora series de más de 12 reps si hay alguna fiable', () {
      // 40×30 daría 80 con Epley; la serie de 60×8 (76) es la fiable.
      final rm = session([set(40, 30, 1), set(60, 8, 2)]).estimated1RM;
      expect(rm, closeTo(76, 0.01));
    });

    test('sin series fiables usa las que hay', () {
      expect(session([set(20, 20)]).estimated1RM, closeTo(33.33, 0.01));
    });

    test('sin series → 0', () {
      expect(session(const []).estimated1RM, 0);
    });
  });
}
