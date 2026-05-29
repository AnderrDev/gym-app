import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_summary_section_label.dart';

/// Sección "Para la próxima" — lista las recomendaciones del coach.
class WorkoutSummaryCoachingSection extends StatelessWidget {
  const WorkoutSummaryCoachingSection({super.key, required this.coaching});

  final List<CoachingAnalysis> coaching;

  @override
  Widget build(BuildContext context) {
    if (coaching.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkoutSummarySectionLabel(
          text: 'Para la próxima',
          icon: Icons.psychology_rounded,
          iconColor: context.colors.info,
        ),
        const SizedBox(height: Spacing.sm),
        ...coaching.map((c) => _CoachingRow(item: c)),
      ],
    );
  }
}

class _CoachingRow extends StatelessWidget {
  const _CoachingRow({required this.item});
  final CoachingAnalysis item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.exerciseName,
            style: context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.recommendation,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
