import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_history_session.dart';

/// Card de detalle de una sesión histórica de un ejercicio: fecha + volumen
/// total + chips con cada serie. Usado por `ExerciseStatsBottomSheet`.
class ExerciseHistorySessionItem extends StatelessWidget {
  const ExerciseHistorySessionItem({super.key, required this.session});

  final ExerciseHistorySession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'es')
                    .format(session.sessionDate)
                    .toUpperCase(),
                style: AppTextStyles.label.copyWith(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${session.totalVolume.toStringAsFixed(0)} kg Vol.',
                style: AppTextStyles.label.copyWith(
                  fontSize: 10,
                  color: AppColors.textDisabled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: session.logs
                .map(
                  (log) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${log.actualWeight.toStringAsFixed(0)}kg x ${log.actualReps}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
