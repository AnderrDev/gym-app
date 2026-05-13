import 'package:gym_flutter/core/i18n/coaching_messages.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';

class WorkoutPerformanceAnalyzer {
  const WorkoutPerformanceAnalyzer._();

  static List<CoachingAnalysis> analyzePerformance(
    List<Exercise> exercises,
    List<SetLog> logs, {
    List<WorkoutSession> history = const [],
    Map<String, List<SetLog>> historyLogs = const {},
  }) {
    final results = <CoachingAnalysis>[];

    for (final ex in exercises) {
      final exLogs = logs.where((l) => l.exerciseId == ex.id).toList();
      final completedSets = exLogs.length;

      var weightMet = true;
      var repsMet = true;
      var recommendation = '';
      var performanceScore = 1.0;
      String? feedback;

      double currentAvgWeight = 0;
      double currentAvgReps = 0;

      if (completedSets > 0) {
        currentAvgWeight =
            exLogs.map((l) => l.actualWeight).reduce((a, b) => a + b) /
            completedSets;
        currentAvgReps =
            exLogs.map((l) => l.actualReps).reduce((a, b) => a + b) /
            completedSets;

        weightMet = currentAvgWeight >= ex.targetWeight;
        repsMet = currentAvgReps >= ex.targetReps;

        final weightRatio = ex.targetWeight > 0
            ? currentAvgWeight / ex.targetWeight
            : 1.0;
        final repsRatio = ex.targetReps > 0
            ? currentAvgReps / ex.targetReps
            : 1.0;
        final setsRatio = ex.targetSets > 0
            ? (completedSets / ex.targetSets).clamp(0.0, 1.0)
            : 1.0;

        performanceScore =
            (weightRatio * 0.45 + repsRatio * 0.45 + setsRatio * 0.1);
      }

      final historyStats = <Map<String, double>>[];
      for (final session in history) {
        final sessionLogs = historyLogs[session.id] ?? const <SetLog>[];
        final exPastLogs = sessionLogs
            .where((l) => l.exerciseId == ex.id)
            .toList();

        if (exPastLogs.isNotEmpty) {
          final avgW =
              exPastLogs.map((l) => l.actualWeight).reduce((a, b) => a + b) /
              exPastLogs.length;
          final avgR =
              exPastLogs.map((l) => l.actualReps).reduce((a, b) => a + b) /
              exPastLogs.length;
          historyStats.add({'weight': avgW, 'reps': avgR});
        }
      }

      if (completedSets > 0) {
        if (historyStats.length >= 2) {
          final last = historyStats[0];
          final previous = historyStats[1];

          final isRegressing =
              last['reps']! < previous['reps']! &&
              last['weight']! <= previous['weight']!;
          final isStagnated =
              last['reps']! < ex.targetReps &&
              previous['reps']! < ex.targetReps;

          if (isRegressing || (isStagnated && currentAvgReps < ex.targetReps)) {
            recommendation =
                '📉 RENDIMIENTO DECRECIENTE: Llevas dos sesiones sin alcanzar las reps objetivo. Te aconsejo bajar un poco el peso (2.5 - 5kg) para recuperar la progresión y técnica.';
            feedback = 'WEIGHT_REDUCTION_ADVISED';
            performanceScore = performanceScore.clamp(0.0, 0.7);
          }
        }

        if (recommendation.isEmpty) {
          if (completedSets < ex.targetSets) {
            recommendation =
                'Sigue así. Te faltan ${ex.targetSets - completedSets} series para completar el objetivo.';
            feedback = 'IN_PROGRESS';
          } else if (!weightMet) {
            recommendation =
                'Peso por debajo del objetivo. Prioriza la técnica hoy, pero intenta subir 1-2kg la próxima sesión.';
            feedback = 'KEEP_CONSISTENCY';
          } else if (!repsMet) {
            recommendation =
                'Reps por debajo del objetivo. Si te sientes pesado, baja 2.5kg para asegurar el rango de reps.';
            feedback = 'MODERATE_ADJUSTMENT';
          } else {
            if (currentAvgWeight > ex.targetWeight ||
                currentAvgReps > ex.targetReps) {
              recommendation =
                  '🚀 ¡SUPERACIÓN! Has superado los objetivos. Sube el peso un nivel la próxima sesión sin miedo.';
              feedback = 'PROGRESSIVE_OVERLOAD';
              performanceScore = 1.2;
            } else {
              recommendation =
                  '🎯 OBJETIVO CUMPLIDO. Has mantenido la intensidad. Prepárate para subir carga pronto.';
              feedback = 'READY_TO_PROGRESS';
              performanceScore = 1.0;
            }
          }
        }
      } else {
        recommendation = '';
        performanceScore = 1.0;
        feedback = 'PENDING';
      }

      results.add(
        CoachingAnalysis(
          exerciseId: ex.id,
          exerciseName: ex.name,
          completedSets: completedSets,
          targetSets: ex.targetSets,
          weightMet: weightMet,
          repsMet: repsMet,
          recommendation: recommendation,
          performanceScore: performanceScore,
          feedback: feedback,
        ),
      );
    }

    return results;
  }

  static Map<String, List<SetLog>> groupByExerciseName(
    List<SetLog> logs,
    List<Exercise> exercises,
  ) {
    final exerciseMap = {for (final e in exercises) e.id: e.name};
    final grouped = <String, List<SetLog>>{};

    for (final log in logs) {
      final name = exerciseMap[log.exerciseId] ?? 'Ejercicio';
      grouped.putIfAbsent(name, () => []).add(log);
    }

    return grouped;
  }

  static String friendlyRecommendation(String recommendation) {
    return CoachingMessages.long(recommendation);
  }
}
