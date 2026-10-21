import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/utils/date_format.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/chart_axis.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/training_history.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/weight_format.dart';

/// Histórico de las últimas semanas: una barra de volumen por semana con el
/// número de entrenamientos debajo. Tocar una barra abre esa semana en el
/// resumen de arriba ([onSelectWeek]); la seleccionada va en color pleno.
class WeeklyHistoryChart extends StatelessWidget {
  const WeeklyHistoryChart({
    super.key,
    required this.weeks,
    required this.selectedWeekStart,
    required this.onSelectWeek,
  });

  /// De la más antigua a la más reciente (ver `weeklyTotals`).
  final List<WeekTotals> weeks;
  final DateTime selectedWeekStart;
  final ValueChanged<DateTime> onSelectWeek;

  @override
  Widget build(BuildContext context) {
    final trained = weeks.where((w) => w.sessions > 0).toList();
    final maxVolume = weeks.fold<double>(
      0,
      (m, w) => w.volume > m ? w.volume : m,
    );
    final totalSessions = weeks.fold<int>(0, (s, w) => s + w.sessions);
    final avgVolume = trained.isEmpty
        ? 0.0
        : trained.fold<double>(0, (s, w) => s + w.volume) / trained.length;

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Volumen de cada semana; encima, cuántos entrenamientos. '
            'Toca una barra para ver esa semana.',
            style: context.text.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.md),
          if (trained.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
              child: Text(
                'Aún no hay entrenamientos terminados en estas semanas.',
                style: context.text.bodySmall,
              ),
            )
          else
            Semantics(
              label: _semanticSummary(),
              excludeSemantics: true,
              child: SizedBox(height: 168, child: _chart(context, maxVolume)),
            ),
          const SizedBox(height: Spacing.md),
          Text(
            '$totalSessions '
            '${totalSessions == 1 ? 'entrenamiento' : 'entrenamientos'} '
            'en ${weeks.length} semanas'
            '${trained.isEmpty ? '' : ' · ${formatVolume(avgVolume)} kg de media por semana entrenada'}',
            style: context.text.bodySmall?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chart(BuildContext context, double maxVolume) {
    final selected = context.colors.primary;
    final other = context.colors.primary.withValues(alpha: 0.35);
    return BarChart(
      BarChartData(
        maxY: maxVolume * 1.15,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (!isExactIndex(value) || i < 0 || i >= weeks.length) {
                  return const SizedBox.shrink();
                }
                final n = weeks[i].sessions;
                return Text(
                  n == 0 ? '' : '$n',
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                // BarChart pinta un título por barra (ignora `interval`):
                // una fecha de cada dos, contando desde la última, o se
                // pisaban.
                if (i < 0 ||
                    i >= weeks.length ||
                    (weeks.length - 1 - i).isOdd) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    AppDateFormat.dayMonthShort(weeks[i].weekStart),
                    style: context.text.labelSmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchCallback: (event, response) {
            final spot = response?.spot;
            if (event is! FlTapUpEvent || spot == null) return;
            onSelectWeek(weeks[spot.touchedBarGroupIndex].weekStart);
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => context.colors.surfaceHighlight,
            tooltipBorderRadius: const BorderRadius.all(Radius.circular(8)),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final w = weeks[groupIndex];
              return BarTooltipItem(
                '${formatVolume(w.volume)} kg',
                (context.text.bodySmall ?? const TextStyle()).copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(
                    text:
                        '\n${w.sessions} ${w.sessions == 1 ? 'entrenamiento' : 'entrenamientos'}',
                    style: context.text.labelSmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < weeks.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: weeks[i].volume,
                  width: 18,
                  color: weeks[i].weekStart == selectedWeekStart
                      ? selected
                      : other,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(Radii.xs),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _semanticSummary() {
    final parts = [
      for (final w in weeks)
        'semana del ${AppDateFormat.dayMonthShort(w.weekStart)}: '
            '${w.sessions} entrenamientos, ${formatVolume(w.volume)} kg',
    ];
    return 'Últimas ${weeks.length} semanas. ${parts.join('; ')}.';
  }
}
