import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../bloc/exercise_stats/exercise_stats_bloc.dart';
import '../bloc/exercise_stats/exercise_stats_event.dart';
import '../bloc/exercise_stats/exercise_stats_state.dart';

class ExerciseStatsSheet extends StatelessWidget {
  final String userId;
  final String exerciseId;
  final String exerciseName;

  const ExerciseStatsSheet({
    super.key,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
  });

  static void show(BuildContext context, {
    required String userId,
    required String exerciseId,
    required String exerciseName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExerciseStatsSheet(
        userId: userId,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExerciseStatsBloc>()
        ..add(LoadExerciseStats(userId: userId, exerciseId: exerciseId)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              exerciseName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Historial de Rendimiento',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: BlocBuilder<ExerciseStatsBloc, ExerciseStatsState>(
                builder: (context, state) {
                  if (state is ExerciseStatsLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  } else if (state is ExerciseStatsError) {
                    return Center(
                      child: Text(
                        'Error: \${state.message}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  } else if (state is ExerciseStatsLoaded) {
                    if (state.history.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay historial para este ejercicio',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildMaxWeightChart(state),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                        SliverToBoxAdapter(
                          child: _buildEstimated1RMChart(state),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                        SliverToBoxAdapter(
                          child: _buildVolumeChart(state),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 40)),
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaxWeightChart(ExerciseStatsLoaded state) {
    // Reverse so the oldest is on the left
    final history = state.history.reversed.toList();
    
    // Si solo hay un dato, repetimos para que la gráfica de línea tenga algo que dibujar
    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
        spots.add(FlSpot(i.toDouble(), history[i].maxWeight));
    }
    if (spots.length == 1) {
      spots.add(FlSpot(1.0, history.first.maxWeight));
    }

    return _buildChartContainer(
      title: 'Peso Máximo (kg)',
      chart: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white10,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < history.length) {
                    final date = history[index].sessionDate;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('d/M').format(date),
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.primary,
                    strokeWidth: 2,
                    strokeColor: AppColors.background,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimated1RMChart(ExerciseStatsLoaded state) {
    final history = state.history.reversed.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
        spots.add(FlSpot(i.toDouble(), history[i].estimated1RM));
    }
     if (spots.length == 1) {
      spots.add(FlSpot(1.0, history.first.estimated1RM));
    }

    return _buildChartContainer(
      title: '1RM Estimado (kg)',
      chart: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white10,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < history.length) {
                    final date = history[index].sessionDate;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('d/M').format(date),
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.greenAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.greenAccent.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeChart(ExerciseStatsLoaded state) {
    final history = state.history.reversed.toList();
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < history.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: history[i].totalVolume,
              color: Colors.purpleAccent,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return _buildChartContainer(
      title: 'Volumen Total (kg)',
      chart: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white10,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < history.length) {
                     final date = history[index].sessionDate;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('d/M').format(date),
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }

  Widget _buildChartContainer({required String title, required Widget chart}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 220,
            padding: const EdgeInsets.only(right: 20, top: 20, bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: chart,
          ),
        ],
      ),
    );
  }
}
