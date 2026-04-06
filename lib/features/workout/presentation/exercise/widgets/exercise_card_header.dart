import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_card_coaching.dart';

class ExerciseCardHeader extends StatelessWidget {
  final Exercise exercise;
  final SetLog? lastPerformance;
  final CoachingAnalysis? coachingAnalysis;
  final bool readOnly;
  final bool isExpanded;
  final bool allDone;
  final int targetSets;
  final int doneCount;
  final double progressFraction;
  final bool showLiveAdvice;
  final String? liveAdvice;
  final Animation<double> pulseAnimation;
  final VoidCallback onToggleExpanded;
  final VoidCallback onOpenTargetEditor;
  final VoidCallback onOpenInsights;
  final VoidCallback onOpenProgress;
  final String Function(String) recommendationText;

  const ExerciseCardHeader({
    super.key,
    required this.exercise,
    required this.lastPerformance,
    required this.coachingAnalysis,
    required this.readOnly,
    required this.isExpanded,
    required this.allDone,
    required this.targetSets,
    required this.doneCount,
    required this.progressFraction,
    required this.showLiveAdvice,
    required this.liveAdvice,
    required this.pulseAnimation,
    required this.onToggleExpanded,
    required this.onOpenTargetEditor,
    required this.onOpenInsights,
    required this.onOpenProgress,
    required this.recommendationText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      onTap: onToggleExpanded,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: allDone
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    allDone ? Icons.check_circle : Icons.fitness_center,
                    size: 20,
                    color: allDone
                        ? const Color(0xFF4CAF50)
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'TARGET: ${exercise.targetWeight.toStringAsFixed(0)}kg x ${exercise.targetReps}',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$targetSets series',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (lastPerformance != null) ...[
                            Text(
                              '  •  ',
                              style: TextStyle(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.history,
                              size: 12,
                              color: AppColors.primary.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Record: ${lastPerformance!.actualWeight.toStringAsFixed(0)}kg x ${lastPerformance!.actualReps}',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.primary.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (!readOnly)
                  IconButton(
                    icon: const Icon(Icons.settings_remote, size: 20),
                    color: AppColors.primary.withValues(alpha: 0.6),
                    tooltip: 'Cambiar Objetivo Remotamente',
                    onPressed: onOpenTargetEditor,
                  ),
                const SizedBox(width: 4),
                Text(
                  '$doneCount/$targetSets',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: readOnly
                        ? AppColors.textSecondary
                        : (allDone
                              ? const Color(0xFF4CAF50)
                              : AppColors.primary),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.insights, size: 20),
                  color: AppColors.primary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onOpenInsights,
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.open_in_full_rounded, size: 18),
                  color: AppColors.primary.withValues(alpha: 0.9),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Ver progreso completo',
                  onPressed: onOpenProgress,
                ),
                const SizedBox(width: 4),
                if (coachingAnalysis != null &&
                    coachingAnalysis!.feedback != 'PENDING') ...[
                  ExerciseCardCoachingBadge(
                    coaching: coachingAnalysis!,
                    pulseAnimation: pulseAnimation,
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: progressFraction),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 5,
                      backgroundColor: AppColors.background,
                      color: allDone
                          ? const Color(0xFF4CAF50)
                          : AppColors.primary,
                    );
                  },
                ),
              ),
            ),
            if (coachingAnalysis != null &&
                coachingAnalysis!.feedback != 'PENDING' &&
                !isExpanded) ...[
              const SizedBox(height: 12),
              ExerciseCardCoachingAdvice(
                coaching: coachingAnalysis!,
                compact: true,
                recommendationText: recommendationText,
              ),
            ],
            if (showLiveAdvice && liveAdvice != null) ...[
              const SizedBox(height: 12),
              ExerciseCardLiveAdvice(text: liveAdvice!),
            ],
          ],
        ),
      ),
    );
  }
}
