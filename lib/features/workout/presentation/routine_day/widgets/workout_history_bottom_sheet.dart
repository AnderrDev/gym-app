import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/workout_performance_analyzer.dart';

class WorkoutHistoryBottomSheet extends StatelessWidget {
  final WorkoutSession session;
  final List<SetLog> logs;
  final List<Exercise> exercises;

  const WorkoutHistoryBottomSheet({
    super.key,
    required this.session,
    required this.logs,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${session.sessionDate.day}/${session.sessionDate.month}/${session.sessionDate.year}';
    final groupedLogs = WorkoutPerformanceAnalyzer.groupByExerciseName(
      logs,
      exercises,
    );
    final totalVolume = logs.fold(
      0.0,
      (s, l) => s + (l.actualWeight * l.actualReps),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: Spacing.md),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lgPlus,
                Spacing.sm,
                Spacing.lgPlus,
                Spacing.lgPlus,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SESIÓN ANTERIOR',
                          style: AppTextStyles.heading2.copyWith(fontSize: 20),
                        ),
                        Text(
                          'Completada el $dateLabel',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lgPlus,
                  0,
                  Spacing.lgPlus,
                  Spacing.xxxl,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(Spacing.lg),
                    margin: const EdgeInsets.only(bottom: Spacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.show_chart_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'VOLUMEN TOTAL: ${totalVolume.toStringAsFixed(0)} kg',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...groupedLogs.entries.map((entry) {
                    final coaching = session.coachingAnalysis?.firstWhereOrNull(
                      (a) =>
                          a.exerciseName == entry.key ||
                          a.exerciseId ==
                              exercises
                                  .firstWhereOrNull(
                                    (ex) => ex.name == entry.key,
                                  )
                                  ?.id,
                    );

                    return _HistoryExerciseCard(
                      exerciseName: entry.key,
                      logs: entry.value,
                      coaching: coaching,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryExerciseCard extends StatelessWidget {
  final String exerciseName;
  final List<SetLog> logs;
  final CoachingAnalysis? coaching;

  const _HistoryExerciseCard({
    required this.exerciseName,
    required this.logs,
    required this.coaching,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Text(
              exerciseName,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceHighlight),
          ...logs.map(
            (log) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.surfaceHighlight.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  _Circle(label: '${log.setIndex}'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '${log.actualWeight.toStringAsFixed(1)} kg',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${log.actualReps} reps',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (coaching != null) ...[
            const Divider(height: 1, color: AppColors.surfaceHighlight),
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: _CoachingAdvice(coaching: coaching!),
            ),
          ],
        ],
      ),
    );
  }
}

class _CoachingAdvice extends StatelessWidget {
  final CoachingAnalysis coaching;

  const _CoachingAdvice({required this.coaching});

  @override
  Widget build(BuildContext context) {
    final score = coaching.performanceScore ?? 1.0;
    final isGood = score >= 0.85;
    final isGreat = score >= 1.0;

    final accentColor = isGreat
        ? AppColors.success
        : (isGood ? Colors.amber[400]! : Colors.orange[400]!);

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'CONSEJO DEL COACH',
                style: AppTextStyles.label.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (coaching.recommendation.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: Spacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                WorkoutPerformanceAnalyzer.friendlyRecommendation(
                  coaching.recommendation,
                ),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (coaching.feedback?.isNotEmpty ?? false)
            Text(
              coaching.feedback!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final String label;

  const _Circle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
