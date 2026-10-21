import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gym_flutter/core/utils/date_format.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/molecules/app_card.dart';
import 'package:gym_flutter/features/workout/presentation/shared/widgets/stat_stripe.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/chart_axis.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/weight_format.dart';

/// Un punto de la gráfica: fecha (de la sesión o del lunes de la semana) y
/// volumen.
typedef VolumePoint = ({DateTime date, double volume});

/// Volumen a lo largo del tiempo con actual / récord / cambio frente al
/// punto anterior y desde el primero. Cada punto es una sesión de un mismo
/// día de rutina o una semana: mezclar sesiones de días distintos (Torso
/// contra Pierna) daba subidas y bajadas que no significaban nada.
class RoutineStatsVolumeChart extends StatelessWidget {
  const RoutineStatsVolumeChart({
    super.key,
    required this.points,
    required this.subtitle,
    required this.deltaCaption,
  });

  /// En orden cronológico.
  final List<VolumePoint> points;
  final String subtitle;

  /// Frente a qué es el cambio, p. ej. "VS ANTERIOR".
  final String deltaCaption;

  static Set<int> _computePrIndices(List<double> values) {
    final prs = <int>{};
    var runningMax = double.negativeInfinity;
    for (var i = 0; i < values.length; i++) {
      if (i > 0 && values[i] > runningMax) prs.add(i);
      if (values[i] > runningMax) runningMax = values[i];
    }
    return prs;
  }

  @override
  Widget build(BuildContext context) {
    final chronological = points;
    final values = chronological.map((p) => p.volume).toList();
    final actual = values.last;
    final record = values.reduce((a, b) => a > b ? a : b);
    final delta = values.length < 2 ? null : actual - values[values.length - 2];
    final actualIsRecord = actual >= record;
    final pr = _computePrIndices(values);
    final yMin = values.reduce((a, b) => a < b ? a : b);
    final yMax = values.reduce((a, b) => a > b ? a : b);
    final yRange = (yMax - yMin).abs();
    final yPad = yRange == 0 ? (yMax == 0 ? 1.0 : yMax * 0.1) : yRange * 0.15;

    String fmt(double v) => formatVolume(v);

    return AppCard(
      padding: const EdgeInsets.all(Spacing.lgPlus),
      borderRadius: BorderRadius.circular(Radii.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                color: context.colors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VOLUMEN',
                      style: context.text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StatStripe(
            actualLabel: fmt(actual),
            recordLabel: fmt(record),
            delta: delta,
            deltaCaption: deltaCaption,
            formatter: fmt,
            unit: 'kg',
            recordReached: actualIsRecord,
          ),
          if (values.length >= 2) ...[
            const SizedBox(height: Spacing.sm),
            PeriodChangeLine(
              since: chronological.first.date,
              first: values.first,
              last: actual,
              unit: 'kg',
              formatter: fmt,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: yMin - yPad,
                maxY: yMax + yPad,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yRange == 0 ? null : yRange / 3,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: context.colors.divider, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            compactAxisNumber(value),
                            style: context.text.labelSmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: dateAxisInterval(chronological.length),
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (!isExactIndex(value) ||
                            i < 0 ||
                            i >= chronological.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            AppDateFormat.dayMonth(chronological[i].date),
                            style: context.text.labelSmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => context.colors.surfaceHighlight,
                    tooltipBorderRadius: const BorderRadius.all(
                      Radius.circular(8),
                    ),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    getTooltipItems: (spots) {
                      return spots.map((s) {
                        final i = s.x.toInt();
                        if (i < 0 || i >= chronological.length) return null;
                        final date = AppDateFormat.dayMonthShort(
                          chronological[i].date,
                        );
                        return LineTooltipItem(
                          '${fmt(s.y)} kg',
                          (context.text.bodySmall ?? const TextStyle())
                              .copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                          children: [
                            TextSpan(
                              text: '\n$date',
                              style: context.text.labelSmall?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < values.length; i++)
                        FlSpot(i.toDouble(), values[i]),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: context.colors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      // Con un solo punto no hay línea: sin punto visible la
                      // gráfica parecía vacía.
                      checkToShowDot: (spot, _) =>
                          values.length == 1 || pr.contains(spot.x.toInt()),
                      getDotPainter: (spot, xPercentage, bar, index) =>
                          FlDotCirclePainter(
                            radius: 5,
                            color: pr.contains(spot.x.toInt())
                                ? context.colors.warning
                                : context.colors.primary,
                            strokeWidth: 2,
                            strokeColor: context.colors.surface,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          context.colors.primary.withValues(alpha: 0.2),
                          context.colors.primary.withValues(alpha: 0),
                        ],
                      ),
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
