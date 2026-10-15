import 'package:flutter/material.dart';
import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/workout_completion.dart';

/// Consulta de una sesión cerrada: resultados reales, sin controles de edición.
class RoutineDayCompletedView extends StatelessWidget {
  const RoutineDayCompletedView({
    super.key,
    required this.exercises,
    required this.logs,
    required this.totalVolume,
  });

  final List<Exercise> exercises;
  final List<SetLog> logs;
  final double totalVolume;

  @override
  Widget build(BuildContext context) {
    final target = exercises.fold<int>(0, (sum, ex) => sum + ex.targetSets);
    final done = completedTargetSets(exercises, logs);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Entrenamiento finalizado',
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                '$done de $target series objetivo · ${logs.length} series registradas',
                style: context.text.bodyMedium,
              ),
              const SizedBox(height: Spacing.sm),
              LinearProgressIndicator(
                value: target > 0 ? (done / target).clamp(0.0, 1.0) : 0,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Volumen total: ${totalVolume.toStringAsFixed(0)} kg · Sesión guardada',
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              for (final ex in exercises) ...[
                _ExerciseResult(
                  exercise: ex,
                  logs: logs.where((log) => log.exerciseId == ex.id).toList()
                    ..sort((a, b) => a.setIndex.compareTo(b.setIndex)),
                ),
                const SizedBox(height: Spacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseResult extends StatelessWidget {
  const _ExerciseResult({required this.exercise, required this.logs});
  final Exercise exercise;
  final List<SetLog> logs;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Spacing.md),
    decoration: BoxDecoration(
      color: context.colors.surface,
      border: Border.all(color: context.colors.divider),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exercise.name,
          style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (exercise.replacesExerciseName != null)
          Text(
            'Sustituye a ${exercise.replacesExerciseName}',
            style: context.text.bodySmall,
          ),
        if (exercise.isExtra)
          Text('Ejercicio extra', style: context.text.bodySmall),
        const SizedBox(height: Spacing.sm),
        if (logs.isEmpty)
          Text(
            'Sin series registradas',
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        for (final log in logs)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Serie ${log.setIndex} · ${log.actualWeight.toStringAsFixed(log.actualWeight % 1 == 0 ? 0 : 1)} kg × ${log.actualReps} reps',
              style: context.text.bodyMedium,
            ),
          ),
      ],
    ),
  );
}
