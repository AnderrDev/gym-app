import 'package:gym_flutter/core/i18n/coaching_messages.dart';
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

    expect(result.recommendation, CoachingRecommendation.maintain);
    expect(result.feedback!.toLowerCase(), isNot(contains('baja')));
  });

  test('mismo peso con menos reps sí sugiere ajustar', () {
    final result = WorkoutPerformanceAnalyzer.analyzePerformance([
      exercise,
    ], logs('today', 38, 8)).single;

    expect(result.recommendation, CoachingRecommendation.increaseReps);
  });

  test('historial en regresión no pisa una subida de peso de hoy', () {
    // Las dos sesiones previas regresan (menos reps, mismo peso), pero hoy
    // subió a 40 kg: no debe aparecer 'RENDIMIENTO DECRECIENTE'.
    final result = WorkoutPerformanceAnalyzer.analyzePerformance(
      [exercise],
      logs('today', 40, 8),
      history: [session('s2', 8), session('s1', 5)],
      historyLogs: {'s2': logs('s2', 38, 7), 's1': logs('s1', 38, 9)},
    ).single;

    expect(result.recommendation, isNot(CoachingRecommendation.decreaseWeight));
  });

  test('historial en regresión sin subida de peso → aconseja bajar', () {
    final result = WorkoutPerformanceAnalyzer.analyzePerformance(
      [exercise],
      logs('today', 38, 7),
      history: [session('s2', 8), session('s1', 5)],
      historyLogs: {'s2': logs('s2', 38, 7), 's1': logs('s1', 38, 9)},
    ).single;

    expect(result.recommendation, CoachingRecommendation.decreaseWeight);
  });
  test('superar el objetivo prevalece sobre una regresión histórica', () {
    final result = WorkoutPerformanceAnalyzer.analyzePerformance(
      [exercise],
      logs('today', 40, 10),
      history: [session('s2', 8), session('s1', 5)],
      historyLogs: {'s2': logs('s2', 42, 7), 's1': logs('s1', 42, 9)},
    ).single;
    expect(result.recommendation, CoachingRecommendation.increaseWeight);
    expect(result.feedback!.toLowerCase(), isNot(contains('bajar')));
  });

  test(
    'subir sobre el objetivo con menos reps no se invalida por el historial',
    () {
      final result = WorkoutPerformanceAnalyzer.analyzePerformance(
        [exercise],
        logs('today', 40, 8),
        history: [session('s2', 8), session('s1', 5)],
        historyLogs: {'s2': logs('s2', 42, 7), 's1': logs('s1', 42, 9)},
      ).single;
      expect(result.recommendation, CoachingRecommendation.maintain);
      expect(result.feedback, contains('mantén este peso'));
    },
  );

  test('series pendientes no reciben un consejo de bajar por historial', () {
    final result = WorkoutPerformanceAnalyzer.analyzePerformance(
      [exercise],
      logs('today', 38, 7).take(1).toList(),
      history: [session('s2', 8), session('s1', 5)],
      historyLogs: {'s2': logs('s2', 38, 7), 's1': logs('s1', 38, 9)},
    ).single;
    expect(result.recommendation, CoachingRecommendation.inProgress);
    expect(result.hasActionableAdvice, isFalse);
  });
}
