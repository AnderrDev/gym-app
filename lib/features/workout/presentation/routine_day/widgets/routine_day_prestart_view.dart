import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_coaching_summary.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_session_recap.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_versus_card.dart';

/// Vista pre-start del día: recap de la última sesión, lista de ejercicios
/// con barras "versus history" y coaching anterior. El CTA "Empezar
/// entrenamiento" lo provee el `bottomNavigationBar` del scaffold (sticky).
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
    final theme = Theme.of(context);
    final lastSession = recentSessions.firstOrNull;
    final hasHistory = lastSession != null;

    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasHistory) ...[
            RoutineDaySessionRecap(
              recentSessions: recentSessions,
              recentSessionsLogs: recentSessionsLogs,
              exercises: exercises,
              onOpenLastSession: onOpenLastSession,
            ),
            const SizedBox(height: Spacing.xl),
          ],
          Row(
            children: [
              Text(
                'PLAN DE HOY',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${exercises.length} ejercicios',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          ..._exerciseCardsWithSpacing(),
          if (lastSession?.coachingAnalysis?.isNotEmpty ?? false) ...[
            const SizedBox(height: Spacing.lg),
            RoutineDayCoachingSummary(coaching: lastSession!.coachingAnalysis!),
          ],
          if (hasAnotherActiveSession) ...[
            const SizedBox(height: Spacing.lg),
            _ActiveSessionWarning(dayName: anotherActiveSessionDayName),
          ],
        ],
      ),
    );
  }

  Iterable<Widget> _exerciseCardsWithSpacing() sync* {
    for (var i = 0; i < exercises.length; i++) {
      final ex = exercises[i];
      final history = _exerciseHistory(ex.id);
      yield RoutineDayVersusCard(
        exercise: ex,
        prevAvgWeight: history.avgWeight,
        prevAvgReps: history.avgReps,
      );
      if (i < exercises.length - 1) {
        yield const SizedBox(height: Spacing.sm);
      }
    }
  }

  _ExerciseHistory _exerciseHistory(String exerciseId) {
    final logs = <SetLog>[];
    for (final s in recentSessions) {
      logs.addAll(
        (recentSessionsLogs[s.id] ?? const <SetLog>[]).where(
          (l) => l.exerciseId == exerciseId,
        ),
      );
    }
    if (logs.isEmpty) return const _ExerciseHistory.empty();
    final avgWeight =
        logs.map((l) => l.actualWeight).reduce((a, b) => a + b) / logs.length;
    final avgReps =
        logs.map((l) => l.actualReps).reduce((a, b) => a + b) / logs.length;
    return _ExerciseHistory(avgWeight: avgWeight, avgReps: avgReps);
  }
}

class _ExerciseHistory {
  const _ExerciseHistory({required this.avgWeight, required this.avgReps});
  const _ExerciseHistory.empty() : avgWeight = null, avgReps = null;
  final double? avgWeight;
  final double? avgReps;
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
                  ? 'Ya tienes un entrenamiento en curso ($dayName). Finalízalo o retómalo antes de iniciar otro.'
                  : 'Ya tienes un entrenamiento en curso. Finalízalo o retómalo antes de iniciar otro.',
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
