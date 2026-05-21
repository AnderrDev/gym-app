import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_summary_section_label.dart';

/// Detalle de un PR (record personal) computado por el summary.
class WorkoutSummaryPr {
  const WorkoutSummaryPr({
    required this.exerciseName,
    required this.currentWeight,
    required this.previousWeight,
    required this.reps,
  });

  final String exerciseName;
  final double currentWeight;
  final double previousWeight;
  final int reps;

  double get delta => currentWeight - previousWeight;
}

/// Sección "Nuevos récords" del [WorkoutSummaryBottomSheet].
class WorkoutSummaryPrSection extends StatelessWidget {
  const WorkoutSummaryPrSection({super.key, required this.prs});

  final List<WorkoutSummaryPr> prs;

  @override
  Widget build(BuildContext context) {
    if (prs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkoutSummarySectionLabel(
          text: 'Nuevos récords',
          icon: Icons.emoji_events_rounded,
          iconColor: context.colors.warning,
        ),
        const SizedBox(height: Spacing.sm),
        ...prs.map((pr) => _PrRow(pr: pr)),
      ],
    );
  }
}

class _PrRow extends StatelessWidget {
  const _PrRow({required this.pr});
  final WorkoutSummaryPr pr;

  String _fmt(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: context.colors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: context.colors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events_rounded,
            color: context.colors.warning,
            size: 18,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pr.exerciseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_fmt(pr.currentWeight)} kg × ${pr.reps} reps',
                  style: context.text.labelMedium?.copyWith(
                    color: context.colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${_fmt(pr.delta)} kg',
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.warning,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
