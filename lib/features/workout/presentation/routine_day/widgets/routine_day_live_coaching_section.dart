import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/workout_performance_analyzer.dart';

class RoutineDayLiveCoachingSection extends StatelessWidget {
  final List<Exercise> exercises;
  final List<WorkoutSession> recentSessions;
  final Map<String, List<SetLog>> recentSessionsLogs;
  final List<SetLog> logs;

  const RoutineDayLiveCoachingSection({
    super.key,
    required this.exercises,
    required this.recentSessions,
    required this.recentSessionsLogs,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    final analysis = WorkoutPerformanceAnalyzer.analyzePerformance(
      exercises,
      logs,
      history: recentSessions,
      historyLogs: recentSessionsLogs,
    );
    final relevant = analysis
        .where((a) => a.completedSets! > 0 && a.recommendation.isNotEmpty)
        .toList();
    if (relevant.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        padding: const EdgeInsets.all(Spacing.lgPlus),
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: context.colors.primary.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Spacing.sm),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: context.colors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ANÁLISIS DE INTELIGENCIA',
                        style: AppTextStyles.label.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Recomendaciones del Coach Pro',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...relevant.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: Spacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: Spacing.xs),
                      child: Icon(
                        Icons.arrow_right_rounded,
                        color: context.colors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.exerciseName.toUpperCase(),
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.recommendation,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.colors.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 32, color: context.colors.surfaceHighlight),
            Center(
              child: Text(
                'Ajustes automáticos aplicados para tu próxima sesión.',
                style: AppTextStyles.label.copyWith(
                  color: context.colors.textDisabled,
                  fontStyle: FontStyle.italic,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
