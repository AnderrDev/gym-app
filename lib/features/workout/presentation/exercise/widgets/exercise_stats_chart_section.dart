import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_stats_series.dart';
import 'package:gym_flutter/features/workout/presentation/shared/widgets/stat_stripe.dart';

/// Sección de chart dentro del `ExerciseStatsBottomSheet`: header (icono +
/// título + subtítulo), barra de métrica vs récord, y chart embebido en
/// un container con borde redondeado.
class ExerciseStatsChartSection extends StatelessWidget {
  const ExerciseStatsChartSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.unit,
    required this.series,
    required this.formatter,
    required this.chart,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String unit;
  final ExerciseStatsSeries series;
  final String Function(double) formatter;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: context.colors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.labelMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.textDisabled,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatStripe(
          actualLabel: formatter(series.actual),
          recordLabel: formatter(series.record),
          delta: series.delta,
          unit: unit,
          recordReached: series.actualIsRecord,
        ),
        const SizedBox(height: 12),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(10, 16, 20, 10),
          decoration: BoxDecoration(
            color: context.colors.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.colors.surfaceHighlight),
          ),
          child: chart,
        ),
      ],
    );
  }
}
