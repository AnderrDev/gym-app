import 'package:flutter/material.dart';
import 'package:gym_flutter/core/utils/date_format.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
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
        color: context.colors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppDateFormat.weekdayLongFull(
                  session.sessionDate,
                ).toUpperCase(),
                style: context.text.labelMedium?.copyWith(
                  fontSize: 10,
                  color: context.colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${session.totalVolume.toStringAsFixed(0)} kg Vol.',
                style: context.text.labelMedium?.copyWith(
                  fontSize: 10,
                  color: context.colors.textDisabled,
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
                      color: context.colors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${log.actualWeight.toStringAsFixed(0)}kg x ${log.actualReps}',
                      style: context.text.bodySmall?.copyWith(
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
