import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_history_session.dart';

/// Charts del bottom sheet de estadísticas por ejercicio. Tres charts:
/// peso máximo, 1RM estimado, volumen total. Comparten el mismo layout y
/// títulos.

class ExerciseMaxWeightChart extends StatelessWidget {
  const ExerciseMaxWeightChart({super.key, required this.history});
  final List<ExerciseHistorySession> history;

  @override
  Widget build(BuildContext context) {
    final reversed = history.reversed.toList();
    final spots = <FlSpot>[];
    for (var i = 0; i < reversed.length; i++) {
      spots.add(FlSpot(i.toDouble(), reversed[i].maxWeight));
    }
    if (spots.length == 1) spots.add(FlSpot(1.0, reversed.first.maxWeight));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: AppColors.surfaceHighlight, strokeWidth: 1),
        ),
        titlesData: buildExerciseStatsTitles(reversed),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
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
    );
  }
}

class ExerciseEstimated1RMChart extends StatelessWidget {
  const ExerciseEstimated1RMChart({super.key, required this.history});
  final List<ExerciseHistorySession> history;

  @override
  Widget build(BuildContext context) {
    final reversed = history.reversed.toList();
    final spots = <FlSpot>[];
    for (var i = 0; i < reversed.length; i++) {
      spots.add(FlSpot(i.toDouble(), reversed[i].estimated1RM));
    }
    if (spots.length == 1) {
      spots.add(FlSpot(1.0, reversed.first.estimated1RM));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: AppColors.surfaceHighlight, strokeWidth: 1),
        ),
        titlesData: buildExerciseStatsTitles(reversed),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.info,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.info.withValues(alpha: 0.15),
                  AppColors.info.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseVolumeChart extends StatelessWidget {
  const ExerciseVolumeChart({super.key, required this.history});
  final List<ExerciseHistorySession> history;

  @override
  Widget build(BuildContext context) {
    final reversed = history.reversed.toList();
    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < reversed.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: reversed[i].totalVolume,
              color: AppColors.primary.withValues(alpha: 0.8),
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: buildExerciseStatsTitles(reversed),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }
}

/// Helper compartido por los tres charts. Formato `d/M` en X, integer en Y.
FlTitlesData buildExerciseStatsTitles(List<ExerciseHistorySession> history) {
  return FlTitlesData(
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 40,
        getTitlesWidget: (value, meta) => Text(
          value.toStringAsFixed(0),
          style: AppTextStyles.label.copyWith(
            color: AppColors.textDisabled,
            fontSize: 9,
          ),
        ),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          final i = value.toInt();
          if (i >= 0 && i < history.length) {
            return Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: Text(
                DateFormat('d/M').format(history[i].sessionDate),
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textDisabled,
                  fontSize: 8,
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    ),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );
}
