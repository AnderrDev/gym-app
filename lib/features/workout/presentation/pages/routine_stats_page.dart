import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../../../injection_container.dart';
import '../bloc/routine_stats/routine_stats_bloc.dart';
import '../bloc/routine_stats/routine_stats_event.dart';
import '../bloc/routine_stats/routine_stats_state.dart';
import '../../domain/entities/routine_history_session.dart';

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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          buildWhen: (previous, current) =>
              current is RoutineStatsLoading ||
              current is RoutineStatsLoaded ||
              current is RoutineStatsError,
          builder: (context, state) {
            if (state is RoutineStatsLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
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
      padding: const EdgeInsets.all(16),
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
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'VOLUMEN TOTAL (kg)',
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: stats.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.totalVolume);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
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

  Widget _buildSessionCard(RoutineHistorySession session) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
