import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';

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
    final isStrictlyCompleted = totalCompletedSets >= totalTargetSets;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Icon(
                    isStrictlyCompleted
                        ? Icons.check_circle_rounded
                        : Icons.pending_actions_rounded,
                    color: isStrictlyCompleted
                        ? AppColors.success
                        : AppColors.primary,
                    size: 52,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isStrictlyCompleted
                        ? '¡RUTINA COMPLETADA!'
                        : 'SESIÓN FINALIZADA',
                    style: AppTextStyles.heading1.copyWith(fontSize: 22),
                  ),
                  Text(
                    isStrictlyCompleted
                        ? 'Has cumplido con todo el volumen programado.'
                        : 'Faltan ${totalTargetSets - totalCompletedSets} series para el objetivo completo.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                        label: 'SERIES',
                        value: '$totalCompletedSets/$totalTargetSets',
                      ),
                      _StatItem(
                        label: 'VOLUMEN',
                        value: '${totalVolume.toStringAsFixed(0)} kg',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Divider(height: 24, color: AppColors.surfaceHighlight),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                children: [
                  if (lastLogs.isNotEmpty) ...[
                    Text(
                      'ACTUAL VS. SESIÓN ANTERIOR',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...exercises.map((ex) {
                      final currExerciseLogs = currentLogs
                          .where((l) => l.exerciseId == ex.id)
                          .toList();
                      final prevExerciseLogs = lastLogs
                          .where((l) => l.exerciseId == ex.id)
                          .toList();

                      return _ExerciseComparisonRow(
                        exercise: ex,
                        currentLogs: currExerciseLogs,
                        previousLogs: prevExerciseLogs,
                      );
                    }),
                    const SizedBox(height: 8),
                    const Divider(
                      height: 24,
                      color: AppColors.surfaceHighlight,
                    ),
                  ],
                  if (analysis.any((a) => a.recommendation.isNotEmpty)) ...[
                    Text(
                      'COACHING & AJUSTES PARA LA PRÓXIMA SESIÓN',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...analysis
                        .where((a) => a.recommendation.isNotEmpty)
                        .map(
                          (item) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.surfaceHighlight,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.exerciseName,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.recommendation,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: onContinue,
                          child: Text(
                            'CONTINUAR',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: onFinishAndSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'FINALIZAR Y GUARDAR',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.background,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseComparisonRow extends StatelessWidget {
  final Exercise exercise;
  final List<SetLog> currentLogs;
  final List<SetLog> previousLogs;

  const _ExerciseComparisonRow({
    required this.exercise,
    required this.currentLogs,
    required this.previousLogs,
  });

  @override
  Widget build(BuildContext context) {
    final currSets = currentLogs.length;
    final prevSets = previousLogs.length;
    final currAvgW = currSets > 0
        ? currentLogs.map((l) => l.actualWeight).reduce((a, b) => a + b) /
              currSets
        : 0.0;
    final currAvgR = currSets > 0
        ? currentLogs
                  .map((l) => l.actualReps.toDouble())
                  .reduce((a, b) => a + b) /
              currSets
        : 0.0;
    final prevAvgW = prevSets > 0
        ? previousLogs.map((l) => l.actualWeight).reduce((a, b) => a + b) /
              prevSets
        : 0.0;
    final prevAvgR = prevSets > 0
        ? previousLogs
                  .map((l) => l.actualReps.toDouble())
                  .reduce((a, b) => a + b) /
              prevSets
        : 0.0;

    IconData trendIcon = Icons.remove_rounded;
    Color trendColor = AppColors.textSecondary;
    if (currSets > 0 && prevSets > 0) {
      if (currAvgW > prevAvgW || currAvgR > prevAvgR) {
        trendIcon = Icons.trending_up_rounded;
        trendColor = AppColors.success;
      } else if (currAvgW < prevAvgW || currAvgR < prevAvgR) {
        trendIcon = Icons.trending_down_rounded;
        trendColor = AppColors.error;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(trendIcon, color: trendColor, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOY',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 9,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currSets > 0
                          ? '$currSets series — ${currAvgW.toStringAsFixed(1)} kg × ${currAvgR.toStringAsFixed(0)}r'
                          : 'Sin datos',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: currSets > 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: AppColors.surfaceHighlight,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ANTERIOR',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prevSets > 0
                            ? '$prevSets series — ${prevAvgW.toStringAsFixed(1)} kg × ${prevAvgR.toStringAsFixed(0)}r'
                            : 'Sin datos',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppColors.textDisabled,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
