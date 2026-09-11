import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gym_flutter/core/utils/date_format.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_history_session.dart';

/// Charts del bottom sheet de estadísticas por ejercicio. Tres charts:
/// peso máximo, 1RM estimado, carga movida. Comparten:
/// - Eje Y con grid + labels con unidad.
/// - Tooltip en tap mostrando fecha + valor exacto.
/// - Dot resaltado cuando la sesión rompió récord histórico.

class ExerciseMaxWeightChart extends StatelessWidget {
  const ExerciseMaxWeightChart({super.key, required this.history});
  final List<ExerciseHistorySession> history;

  @override
  Widget build(BuildContext context) {
    final reversed = history.reversed.toList();
    final values = reversed.map((s) => s.maxWeight).toList();
    return _LineMetricChart(
      sessions: reversed,
      values: values,
      color: context.colors.primary,
      unit: 'kg',
      valueFormatter: _intFormat,
    );
  }
}

class ExerciseEstimated1RMChart extends StatelessWidget {
  const ExerciseEstimated1RMChart({super.key, required this.history});
  final List<ExerciseHistorySession> history;

  @override
  Widget build(BuildContext context) {
    final reversed = history.reversed.toList();
    final values = reversed.map((s) => s.estimated1RM).toList();
    return _LineMetricChart(
      sessions: reversed,
      values: values,
      color: context.colors.info,
      unit: 'kg',
      valueFormatter: _oneDecimalFormat,
    );
  }
}

class ExerciseVolumeChart extends StatelessWidget {
  const ExerciseVolumeChart({super.key, required this.history});
  final List<ExerciseHistorySession> history;

  @override
  Widget build(BuildContext context) {
    final reversed = history.reversed.toList();
    final values = reversed.map((s) => s.totalVolume).toList();
    // Volumen es una métrica acumulada; usamos línea (no barras) para que
    // el usuario pueda comparar la tendencia con peso máx y 1RM en el
    // mismo lenguaje visual.
    return _LineMetricChart(
      sessions: reversed,
      values: values,
      color: context.colors.primary.withValues(alpha: 0.85),
      unit: 'kg·reps',
      valueFormatter: _intFormat,
    );
  }
}

String _intFormat(double v) => v.toStringAsFixed(0);
String _oneDecimalFormat(double v) =>
    v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// Implementación compartida: line chart con grid, eje Y con unidad,
/// tooltip y PR-dots.
class _LineMetricChart extends StatelessWidget {
  const _LineMetricChart({
    required this.sessions,
    required this.values,
    required this.color,
    required this.unit,
    required this.valueFormatter,
  });

  final List<ExerciseHistorySession> sessions;
  final List<double> values;
  final Color color;
  final String unit;
  final String Function(double) valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    // PRs: una sesión rompe récord si su valor supera al máximo histórico
    // acumulado anterior. Marca con un dot grande.
    final pr = _computePrIndices(values);
    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    if (spots.length == 1) spots.add(FlSpot(1.0, values.first));

    final yMin = values.reduce((a, b) => a < b ? a : b);
    final yMax = values.reduce((a, b) => a > b ? a : b);
    final yRange = (yMax - yMin).abs();
    final yPad = yRange == 0 ? (yMax == 0 ? 1.0 : yMax * 0.1) : yRange * 0.15;

    final colors = context.colors;
    return LineChart(
      LineChartData(
        minY: yMin - yPad,
        maxY: yMax + yPad,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yRange == 0 ? null : yRange / 3,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: colors.surfaceHighlight, strokeWidth: 1),
        ),
        titlesData: _buildTitles(context, sessions, unit, valueFormatter),
        borderData: FlBorderData(show: false),
        lineTouchData: _buildTooltip(context, sessions, unit, valueFormatter),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) {
                final i = spot.x.toInt();
                if (i < 0 || i >= values.length) return false;
                return pr.contains(i);
              },
              getDotPainter: (spot, xPercentage, bar, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: context.colors.warning,
                  strokeWidth: 2,
                  strokeColor: context.colors.background,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Índices de sesiones que rompieron récord. Una sesión es PR si su
/// valor `> max(valores anteriores)`. La primera sesión nunca es PR
/// porque no hay con qué compararla.
Set<int> _computePrIndices(List<double> values) {
  final prs = <int>{};
  var runningMax = double.negativeInfinity;
  for (var i = 0; i < values.length; i++) {
    if (i > 0 && values[i] > runningMax) prs.add(i);
    if (values[i] > runningMax) runningMax = values[i];
  }
  return prs;
}

FlTitlesData _buildTitles(
  BuildContext context,
  List<ExerciseHistorySession> sessions,
  String unit,
  String Function(double) formatter,
) {
  final colors = context.colors;
  return FlTitlesData(
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 46,
        getTitlesWidget: (value, meta) {
          // Suprimimos los extremos para no superponer con el padding.
          if (value == meta.min || value == meta.max) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              '${formatter(value)} $unit',
              style: context.text.labelMedium?.copyWith(
                color: colors.textSecondary,
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
        getTitlesWidget: (value, meta) {
          final i = value.toInt();
          if (i < 0 || i >= sessions.length) return const SizedBox();
          return Padding(
            padding: const EdgeInsets.only(top: Spacing.sm),
            child: Text(
              AppDateFormat.dayMonth(sessions[i].sessionDate),
              style: context.text.labelMedium?.copyWith(
                color: colors.textSecondary,
                fontSize: 9,
              ),
            ),
          );
        },
      ),
    ),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );
}

LineTouchData _buildTooltip(
  BuildContext context,
  List<ExerciseHistorySession> sessions,
  String unit,
  String Function(double) formatter,
) {
  final colors = context.colors;
  return LineTouchData(
    handleBuiltInTouches: true,
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (_) => colors.surface,
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      tooltipBorderRadius: const BorderRadius.all(Radius.circular(8)),
      getTooltipItems: (spots) {
        return spots.map((s) {
          final i = s.x.toInt();
          if (i < 0 || i >= sessions.length) return null;
          final date = AppDateFormat.dayMonthShort(sessions[i].sessionDate);
          return LineTooltipItem(
            '${formatter(s.y)} $unit',
            (context.text.bodySmall ?? const TextStyle()).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            children: [
              TextSpan(
                text: '\n$date',
                style: context.text.labelMedium?.copyWith(
                  color: colors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          );
        }).toList();
      },
    ),
  );
}
