import 'package:flutter/material.dart';
import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';

class RoutineDayPreStartView extends StatelessWidget {
  final List<Exercise> exercises;
  final List<WorkoutSession> recentSessions;
  final Map<String, List<SetLog>> recentSessionsLogs;
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
    required this.hasAnotherActiveSession,
    required this.anotherActiveSessionDayName,
    required this.onOpenLastSession,
  });

  @override
  Widget build(BuildContext context) {
    final sets = exercises.fold<int>(0, (sum, ex) => sum + ex.targetSets);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tu entrenamiento',
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                '${exercises.length} ejercicios · $sets series',
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Revisa el plan y empieza cuando estés listo. Podrás ajustar los pesos y cambiar ejercicios durante la sesión.',
                style: context.text.bodyMedium,
              ),
              if (hasAnotherActiveSession) ...[
                const SizedBox(height: Spacing.lg),
                _ActiveSessionWarning(dayName: anotherActiveSessionDayName),
              ],
              const SizedBox(height: Spacing.lg),
              if (exercises.isEmpty)
                const Text('Este día todavía no tiene ejercicios.')
              else
                ...exercises.asMap().entries.map((entry) {
                  final ex = entry.value;
                  final weight = ex.targetWeight > 0
                      ? '${ex.targetWeight.toStringAsFixed(ex.targetWeight % 1 == 0 ? 0 : 1)} kg'
                      : 'Peso por ajustar';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        border: Border.all(color: context.colors.divider),
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              '${entry.key + 1}'.padLeft(2, '0'),
                              style: context.text.labelLarge?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
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
                                const SizedBox(height: Spacing.xs),
                                Text(
                                  '${ex.targetSets} series × ${ex.targetReps} reps · $weight',
                                  style: context.text.bodyMedium,
                                ),
                                const SizedBox(height: Spacing.xs),
                                Text(
                                  'Descanso: ${ex.restTimerSeconds} s',
                                  style: context.text.bodySmall?.copyWith(
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
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
            color: context.colors.warning,
            size: 18,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              dayName != null
                  ? 'Ya tienes un entrenamiento en curso ($dayName). Retómalo para finalizarlo o descartarlo antes de iniciar otro.'
                  : 'Ya tienes un entrenamiento en curso. Retómalo para finalizarlo o descartarlo antes de iniciar otro.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.colors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
