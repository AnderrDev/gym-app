import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/presentation/widgets/glass_container.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_history_session.dart';
import 'package:gym_flutter/features/workout/presentation/shared/widgets/stat_stripe.dart';

class RoutineStatsVolumeChart extends StatelessWidget {
  const RoutineStatsVolumeChart({super.key, required this.stats});

  /// `stats` viene en orden descendente; el chart lo trabaja cronológico.
  final List<RoutineHistorySession> stats;

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
    final chronological = stats.reversed.toList();
    final values = chronological.map((s) => s.totalVolume).toList();
    final actual = values.last;
    final record = values.reduce((a, b) => a > b ? a : b);
    final delta = values.length < 2 ? null : actual - values[values.length - 2];
    final actualIsRecord = actual >= record;
    final pr = _computePrIndices(values);
    final yMin = values.reduce((a, b) => a < b ? a : b);
    final yMax = values.reduce((a, b) => a > b ? a : b);
    final yRange = (yMax - yMin).abs();
    final yPad = yRange == 0 ? (yMax == 0 ? 1.0 : yMax * 0.1) : yRange * 0.15;

    String fmt(double v) => v.toStringAsFixed(0);

    return GlassContainer(
      padding: const EdgeInsets.all(Spacing.lgPlus),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CARGA MOVIDA',
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'Suma de peso × reps de cada sesión',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textDisabled,
                        fontSize: 10,
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
            unit: 'kg·reps',
            recordReached: actualIsRecord,
          ),
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
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.surfaceHighlight,
                    strokeWidth: 1,
                  ),
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
                            fmt(value),
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 9,
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
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= chronological.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('d/M').format(
                              chronological[i].sessionDate,
                            ),
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 9,
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
                    getTooltipColor: (_) => AppColors.surface,
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
                        final date = DateFormat('d MMM', 'es').format(
                          chronological[i].sessionDate,
                        );
                        return LineTooltipItem(
                          '${fmt(s.y)} kg·reps',
                          AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                          children: [
                            TextSpan(
                              text: '\n$date',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
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
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, _) => pr.contains(spot.x.toInt()),
                      getDotPainter: (spot, xPercentage, bar, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.warning,
                            strokeWidth: 2,
                            strokeColor: AppColors.background,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.primary.withValues(alpha: 0),
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
