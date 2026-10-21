import 'package:flutter/material.dart';
import 'package:gym_flutter/core/utils/date_format.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_history_session.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/weight_format.dart';

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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.divider),
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
                '${formatVolume(session.totalVolume)} kg de volumen',
                style: context.text.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          if (session.estimated1RM > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Peso máx. ${formatLoad(session.maxWeight)} · '
              '1RM estimado ${formatDecimal(session.estimated1RM)} kg',
              style: context.text.bodySmall?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
                      '${formatLoad(log.actualWeight)} × ${log.actualReps}',
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
