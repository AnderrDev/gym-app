import 'package:flutter/material.dart';
import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/molecules/app_card.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/weight_format.dart';

/// Previa del entrenamiento: qué toca hoy, cuánto dura y qué se hizo la
/// última vez en cada ejercicio, para empezar con los pesos en la cabeza.
class RoutineDayPreStartView extends StatelessWidget {
  final List<Exercise> exercises;
  final List<WorkoutSession> recentSessions;
  final Map<String, List<SetLog>> recentSessionsLogs;

  /// Mejor serie de la última sesión por ejercicio (`exerciseId`).
  final Map<String, SetLog?> lastPerformances;
  final bool hasAnotherActiveSession;
  final String? anotherActiveSessionDayName;
  final void Function(
    WorkoutSession session,
    List<SetLog> logs,
    List<Exercise> exercises,
  )
  onOpenLastSession;

  const RoutineDayPreStartView({
    super.key,
    required this.exercises,
    required this.recentSessions,
    required this.recentSessionsLogs,
    this.lastPerformances = const {},
    required this.hasAnotherActiveSession,
    required this.anotherActiveSessionDayName,
    required this.onOpenLastSession,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sets = exercises.fold<int>(0, (sum, ex) => sum + ex.targetSets);
    final minutes = estimatedWorkoutMinutes(exercises);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lgPlus,
            Spacing.sm,
            Spacing.lgPlus,
            Spacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: [
                  _SummaryChip(
                    icon: Icons.fitness_center_rounded,
                    label:
                        '${exercises.length} ${exercises.length == 1 ? 'ejercicio' : 'ejercicios'}',
                  ),
                  _SummaryChip(
                    icon: Icons.repeat_rounded,
                    label: '$sets series',
                  ),
                  if (minutes > 0)
                    _SummaryChip(
                      icon: Icons.schedule_rounded,
                      label: '≈ $minutes min',
                    ),
                ],
              ),
              if (hasAnotherActiveSession) ...[
                const SizedBox(height: Spacing.md),
                _ActiveSessionWarning(dayName: anotherActiveSessionDayName),
              ],
              const SizedBox(height: Spacing.lg),
              if (exercises.isEmpty)
                Text(
                  'Este día todavía no tiene ejercicios.',
                  style: context.text.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              else
                for (var i = 0; i < exercises.length; i++)
                  _ExerciseRow(
                    index: i,
                    exercise: exercises[i],
                    last: lastPerformances[exercises[i].id],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Duración aproximada en minutos, redondeada a 5: ~40 s por serie más el
/// descanso configurado entre series, y 1 min de cambio entre ejercicios.
@visibleForTesting
int estimatedWorkoutMinutes(List<Exercise> exercises) {
  var seconds = 0;
  for (final ex in exercises) {
    if (ex.targetSets <= 0) continue;
    seconds += ex.targetSets * 40 + (ex.targetSets - 1) * ex.restTimerSeconds;
  }
  if (seconds == 0) return 0;
  seconds += (exercises.length - 1) * 60;
  final minutes = (seconds / 60).ceil();
  return ((minutes + 4) ~/ 5) * 5;
}

String _load(double kg) => kg <= 0 ? 'Peso corporal' : '${formatWeight(kg)} kg';

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.textSecondary),
          const SizedBox(width: Spacing.xs),
          Text(
            label,
            style: context.text.labelLarge?.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.index,
    required this.exercise,
    required this.last,
  });

  final int index;
  final Exercise exercise;
  final SetLog? last;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ex = exercise;
    final last = this.last;
    return AppCard(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: BorderRadius.circular(Radii.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: context.text.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.name,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ex.targetSets} × ${ex.targetReps} · ${_load(ex.targetWeight)}',
                  style: context.text.bodyMedium,
                ),
                if (last != null) ...[
                  const SizedBox(height: Spacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Flexible(
                        child: Text(
                          'Última vez: ${_load(last.actualWeight)} × ${last.actualReps}',
                          style: context.text.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionWarning extends StatelessWidget {
  const _ActiveSessionWarning({required this.dayName});

  final String? dayName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: context.colors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: context.colors.warning.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: context.colors.warningText,
            size: 18,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              dayName != null
                  ? 'Ya tienes un entrenamiento en curso ($dayName). Retómalo para finalizarlo o descartarlo antes de iniciar otro.'
                  : 'Ya tienes un entrenamiento en curso. Retómalo para finalizarlo o descartarlo antes de iniciar otro.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.colors.warningText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
