import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';

/// Tarjeta con las recomendaciones del coach generadas en la sesión anterior.
/// Si no hay recomendaciones se renderiza vacío.
class RoutineDayCoachingSummary extends StatelessWidget {
  const RoutineDayCoachingSummary({super.key, required this.coaching});

  final List<CoachingAnalysis> coaching;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final relevant = coaching
        .where((c) => c.recommendation.isNotEmpty)
        .toList();
    if (relevant.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'COACHING DE LA SESIÓN ANTERIOR',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          ...relevant.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.arrow_right_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.exerciseName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          c.recommendation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
