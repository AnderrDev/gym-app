import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/workout_performance_analyzer.dart';

void main() {
  const exercise = Exercise(
    id: 'e1',
    routineDayId: 'd1',
    name: 'Press',
    targetMuscle: 'Pecho',
    targetSets: 2,
    targetReps: 10,
    targetWeight: 38,
    restTimerSeconds: 60,
  );

  List<SetLog> logs(String sessionId, double weight, int reps) => [
    for (var i = 1; i <= 2; i++)
      SetLog(
        sessionId: sessionId,
        exerciseId: 'e1',
        actualWeight: weight,
        actualReps: reps,
        setIndex: i,
      ),
  ];

  WorkoutSession session(String id, int day) => WorkoutSession(
    id: id,
    userId: 'u1',
    routineDayId: 'd1',
    sessionDate: DateTime(2026, 9, day),
  );

  test('subir el peso con menos reps no recomienda bajar', () {
    final result = WorkoutPerformanceAnalyzer.analyzePerformance([
      exercise,
    ], logs('today', 40, 8)).single;

    expect(result.feedback, 'HEAVIER_CONSOLIDATE');
    expect(result.recommendation.toLowerCase(), isNot(contains('baja')));
  });

  test('mismo peso con menos reps sí sugiere ajustar', () {
    final result = WorkoutPerformanceAnalyzer.analyzePerformance([
      exercise,
    ], logs('today', 38, 8)).single;

    expect(result.feedback, 'MODERATE_ADJUSTMENT');
  });

  test('historial en regresión no pisa una subida de peso de hoy', () {
    // Las dos sesiones previas regresan (menos reps, mismo peso), pero hoy
    // subió a 40 kg: no debe aparecer "RENDIMIENTO DECRECIENTE".
    final result = WorkoutPerformanceAnalyzer.analyzePerformance(
      [exercise],
      logs('today', 40, 8),
      history: [session('s2', 8), session('s1', 5)],
      historyLogs: {'s2': logs('s2', 38, 7), 's1': logs('s1', 38, 9)},
    ).single;

    expect(result.feedback, isNot('WEIGHT_REDUCTION_ADVISED'));
  });

  test('historial en regresión sin subida de peso → aconseja bajar', () {
    final result = WorkoutPerformanceAnalyzer.analyzePerformance(
      [exercise],
      logs('today', 38, 7),
      history: [session('s2', 8), session('s1', 5)],
      historyLogs: {'s2': logs('s2', 38, 7), 's1': logs('s1', 38, 9)},
    ).single;

    expect(result.feedback, 'WEIGHT_REDUCTION_ADVISED');
  });
}
