import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/i18n/app_strings.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/molecules/bottom_sheet_handle.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_summary_coaching_section.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_summary_comparison_section.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_summary_hero.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_summary_pr_section.dart';
import 'package:gym_flutter/features/workout/presentation/shared/widgets/workout_metric_grid.dart';

/// Bottom sheet de cierre de sesión. Rediseñado con jerarquía clara:
/// hero centrado, métricas en grilla, sección de PRs, comparación vs
/// anterior y coaching para la próxima. Cierra con un par de CTAs;
/// `FINALIZAR Y GUARDAR` dispara el commit al backend (el loader vive
/// en el page padre vía `RoutineDayLoadingPhase`).
class WorkoutSummaryBottomSheet extends StatelessWidget {
  final int totalTargetSets;
  final int totalCompletedSets;
  final double totalVolume;
  final List<Exercise> exercises;
  final List<SetLog> currentLogs;
  final List<SetLog> lastLogs;
  final List<CoachingAnalysis> analysis;
  final VoidCallback onContinue;
  final VoidCallback onFinishAndSave;

  const WorkoutSummaryBottomSheet({
    super.key,
    required this.totalTargetSets,
    required this.totalCompletedSets,
    required this.totalVolume,
    required this.exercises,
    required this.currentLogs,
    required this.lastLogs,
    required this.analysis,
    required this.onContinue,
    required this.onFinishAndSave,
  });

  @override
  Widget build(BuildContext context) {
    final isStrictlyCompleted =
        totalTargetSets > 0 && totalCompletedSets >= totalTargetSets;
    final prs = _computePrs();
    final comparisons = _computeComparisons();
    final coaching = analysis
        .where((a) => a.recommendation.isNotEmpty)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const BottomSheetHandle(
              topPadding: Spacing.sm,
              bottomPadding: Spacing.sm,
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  Spacing.xl,
                  Spacing.sm,
                  Spacing.xl,
                  Spacing.xxxl,
                ),
                children: [
                  WorkoutSummaryHero(
                    isStrictlyCompleted: isStrictlyCompleted,
                    missingSets: totalTargetSets - totalCompletedSets,
                  ),
                  const SizedBox(height: Spacing.lg),
                  WorkoutMetricGrid(
                    metrics: [
                      WorkoutMetric(
                        label: 'SERIES',
                        value: '$totalCompletedSets',
                        secondary: totalTargetSets > 0
                            ? '/ $totalTargetSets'
                            : null,
                        accent: context.colors.primary,
                        icon: Icons.task_alt_rounded,
                      ),
                      WorkoutMetric(
                        label: 'CARGA',
                        value: totalVolume.toStringAsFixed(0),
                        secondary: AppStrings.kgReps,
                        accent: context.colors.textPrimary,
                        icon: Icons.local_fire_department_rounded,
                      ),
                      WorkoutMetric(
                        label: 'RÉCORDS',
                        value: '${prs.length}',
                        secondary: prs.length == 1 ? 'nuevo' : 'nuevos',
                        accent: prs.isNotEmpty
                            ? context.colors.warning
                            : context.colors.textSecondary,
                        icon: Icons.emoji_events_rounded,
                      ),
                    ],
                  ),
                  if (prs.isNotEmpty) ...[
                    const SizedBox(height: Spacing.xl),
                    WorkoutSummaryPrSection(prs: prs),
                  ],
                  if (comparisons.isNotEmpty) ...[
                    const SizedBox(height: Spacing.xl),
                    WorkoutSummaryComparisonSection(comparisons: comparisons),
                  ],
                  if (coaching.isNotEmpty) ...[
                    const SizedBox(height: Spacing.xl),
                    WorkoutSummaryCoachingSection(coaching: coaching),
                  ],
                  const SizedBox(height: Spacing.xl),
                  _ActionRow(
                    onContinue: onContinue,
                    onFinishAndSave: onFinishAndSave,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<WorkoutSummaryPr> _computePrs() {
    final out = <WorkoutSummaryPr>[];
    for (final ex in exercises) {
      final curr = currentLogs.where((l) => l.exerciseId == ex.id);
      if (curr.isEmpty) continue;
      final currMax = curr.fold<double>(
        0,
        (m, l) => l.actualWeight > m ? l.actualWeight : m,
      );
      final prev = lastLogs.where((l) => l.exerciseId == ex.id);
      final prevMax = prev.isEmpty
          ? 0.0
          : prev.fold<double>(
              0,
              (m, l) => l.actualWeight > m ? l.actualWeight : m,
            );
      if (currMax > prevMax && currMax > 0) {
        // Reps usadas en la serie que rompió récord (la más pesada).
        final prSet = curr.reduce(
          (a, b) => a.actualWeight >= b.actualWeight ? a : b,
        );
        out.add(
          WorkoutSummaryPr(
            exerciseName: ex.name,
            currentWeight: currMax,
            previousWeight: prevMax,
            reps: prSet.actualReps,
          ),
        );
      }
    }
    return out;
  }

  List<WorkoutSummaryComparison> _computeComparisons() {
    if (lastLogs.isEmpty) return const [];
    final out = <WorkoutSummaryComparison>[];
    for (final ex in exercises) {
      final curr = currentLogs.where((l) => l.exerciseId == ex.id).toList();
      final prev = lastLogs.where((l) => l.exerciseId == ex.id).toList();
      if (curr.isEmpty && prev.isEmpty) continue;
      final currAvgW = _avgWeight(curr);
      final prevAvgW = _avgWeight(prev);
      out.add(
        WorkoutSummaryComparison(
          exerciseName: ex.name,
          currentSets: curr.length,
          previousSets: prev.length,
          currentAvgWeight: currAvgW,
          previousAvgWeight: prevAvgW,
        ),
      );
    }
    return out;
  }

  static double _avgWeight(List<SetLog> logs) {
    if (logs.isEmpty) return 0.0;
    final total = logs.fold<double>(0, (s, l) => s + l.actualWeight);
    return total / logs.length;
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onContinue, required this.onFinishAndSave});

  final VoidCallback onContinue;
  final VoidCallback onFinishAndSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: onContinue,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
            ),
            child: Text(
              AppStrings.continueUpper,
              style: context.text.labelMedium?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: onFinishAndSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.md),
              ),
            ),
            child: Text(
              AppStrings.finishAndSaveUpper,
              style: context.text.labelMedium?.copyWith(
                color: context.colors.onPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
