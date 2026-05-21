import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_summary_section_label.dart';

class WorkoutSummaryComparison {
  const WorkoutSummaryComparison({
    required this.exerciseName,
    required this.currentSets,
    required this.previousSets,
    required this.currentAvgWeight,
    required this.previousAvgWeight,
  });

  final String exerciseName;
  final int currentSets;
  final int previousSets;
  final double currentAvgWeight;
  final double previousAvgWeight;
}

/// Sección "Vs sesión anterior" del [WorkoutSummaryBottomSheet].
class WorkoutSummaryComparisonSection extends StatelessWidget {
  const WorkoutSummaryComparisonSection({super.key, required this.comparisons});

  final List<WorkoutSummaryComparison> comparisons;

  @override
  Widget build(BuildContext context) {
    if (comparisons.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkoutSummarySectionLabel(
          text: 'Vs sesión anterior',
          icon: Icons.compare_arrows_rounded,
          iconColor: context.colors.primary,
        ),
        const SizedBox(height: Spacing.sm),
        ...comparisons.map((c) => _ComparisonRow(data: c)),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.data});
  final WorkoutSummaryComparison data;

  @override
  Widget build(BuildContext context) {
    final delta = data.currentAvgWeight - data.previousAvgWeight;
    final isUp = delta > 0.05;
    final isDown = delta < -0.05;
    final color = isUp
        ? context.colors.success
        : isDown
        ? context.colors.error
        : context.colors.textSecondary;
    final icon = isUp
        ? Icons.trending_up_rounded
        : isDown
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;
    final deltaStr = delta.abs() < 0.05
        ? '='
        : (delta > 0 ? '+' : '−') + delta.abs().toStringAsFixed(1);
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.exerciseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${data.currentAvgWeight.toStringAsFixed(1)} kg avg · '
                  '${data.currentSets} series',
                  style: context.text.labelMedium?.copyWith(
                    color: context.colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                deltaStr,
                style: context.text.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'kg',
                style: context.text.labelMedium?.copyWith(color: color, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
