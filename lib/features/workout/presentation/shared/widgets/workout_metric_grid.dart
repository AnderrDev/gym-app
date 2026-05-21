import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Metric mostrada dentro de [WorkoutMetricGrid] / [WorkoutMetricCard].
class WorkoutMetric {
  const WorkoutMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.secondary,
    this.valueFontSize = 22,
  });

  final String label;
  final String value;
  final String? secondary;
  final IconData icon;
  final Color accent;
  final double valueFontSize;
}

/// Grid horizontal de 3 [WorkoutMetricCard]. Usado en
/// `workout_summary_bottom_sheet` y `workout_history_bottom_sheet`.
class WorkoutMetricGrid extends StatelessWidget {
  const WorkoutMetricGrid({
    super.key,
    required this.metrics,
    this.spacing = Spacing.sm,
  }) : assert(metrics.length > 0, 'WorkoutMetricGrid needs at least 1 metric');

  final List<WorkoutMetric> metrics;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < metrics.length; i++) {
      children.add(Expanded(child: WorkoutMetricCard(metric: metrics[i])));
      if (i < metrics.length - 1) {
        children.add(SizedBox(width: spacing));
      }
    }
    return Row(children: children);
  }
}

/// Tarjeta individual con icono + label + valor grande + secundario opcional.
class WorkoutMetricCard extends StatelessWidget {
  const WorkoutMetricCard({super.key, required this.metric});

  final WorkoutMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(metric.icon, color: metric.accent, size: 14),
              const SizedBox(width: 4),
              Text(
                metric.label,
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.textSecondary,
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: metric.value,
                  style: context.text.headlineMedium?.copyWith(
                    color: metric.accent,
                    fontWeight: FontWeight.w900,
                    fontSize: metric.valueFontSize,
                  ),
                ),
                if (metric.secondary != null)
                  TextSpan(
                    text: ' ${metric.secondary}',
                    style: context.text.labelMedium?.copyWith(
                      color: context.colors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
