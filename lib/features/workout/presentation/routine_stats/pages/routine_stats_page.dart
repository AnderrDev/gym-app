import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/presentation/widgets/glass_container.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/core/ui/feedback/barbell_loader.dart';
import 'package:gym_flutter/injection_container.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_stats/routine_stats_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_stats/routine_stats_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_stats/routine_stats_state.dart';
import 'package:gym_flutter/features/workout/presentation/shared/widgets/stat_stripe.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_history_session.dart';

class RoutineStatsPage extends StatelessWidget {
  final String userId;
  final String routineId;
  final String routineName;

  const RoutineStatsPage({
    super.key,
    required this.userId,
    required this.routineId,
    required this.routineName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RoutineStatsBloc(repository: sl())
            ..add(FetchRoutineStats(userId: userId, routineId: routineId)),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text('Historial: $routineName', style: AppTextStyles.heading2),
        ),
        body: BlocConsumer<RoutineStatsBloc, RoutineStatsState>(
          listenWhen: (previous, current) => current is RoutineStatsError,
          listener: (context, state) {
            if (state is RoutineStatsError) {
              AppSnackBar.error(context, state.message);
            }
          },
          buildWhen: (previous, current) =>
              current is RoutineStatsLoading ||
              current is RoutineStatsLoaded ||
              current is RoutineStatsError,
          builder: (context, state) {
            if (state is RoutineStatsLoading) {
              return const Center(child: BarbellLoader.large());
            }
            if (state is RoutineStatsError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: AppColors.error),
                ),
              );
            }
            if (state is RoutineStatsLoaded) {
              if (state.stats.isEmpty) {
                return _buildEmptyState();
              }
              return _buildStatsContent(state.stats);
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bar_chart,
            size: 64,
            color: AppColors.surfaceHighlight,
          ),
          const SizedBox(height: 16),
          Text('Sin datos suficientes', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          Text(
            'Completa sesiones para ver tu evolución.',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(List<RoutineHistorySession> stats) {
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        _buildVolumeChart(stats),
        const SizedBox(height: 24),
        Text(
          'EVOLUCIÓN DE VOLUMEN',
          style: AppTextStyles.label.copyWith(letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        ...stats.reversed.map((s) => _buildSessionCard(s)),
      ],
    );
  }

  Widget _buildVolumeChart(List<RoutineHistorySession> stats) {
    // stats viene en orden descendente; trabajamos cronológico para el chart.
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
              const Icon(Icons.show_chart, color: AppColors.primary, size: 20),
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
                            DateFormat(
                              'd/M',
                            ).format(chronological[i].sessionDate),
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
                        final date = DateFormat(
                          'd MMM',
                          'es',
                        ).format(chronological[i].sessionDate);
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

  Set<int> _computePrIndices(List<double> values) {
    final prs = <int>{};
    var runningMax = double.negativeInfinity;
    for (var i = 0; i < values.length; i++) {
      if (i > 0 && values[i] > runningMax) prs.add(i);
      if (values[i] > runningMax) runningMax = values[i];
    }
    return prs;
  }

  Widget _buildSessionCard(RoutineHistorySession session) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: BorderRadius.circular(16),
      opacity: 0.05,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.routineDayName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat(
                    'EEEE, d MMM',
                    'es',
                  ).format(session.sessionDate).toUpperCase(),
                  style: AppTextStyles.label.copyWith(
                    fontSize: 10,
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${session.totalVolume.toStringAsFixed(0)} kg',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'VOL. TOTAL',
                style: AppTextStyles.label.copyWith(fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
