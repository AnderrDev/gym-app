import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../../../injection_container.dart';
import '../bloc/exercise_stats/exercise_stats_bloc.dart';
import '../bloc/exercise_stats/exercise_stats_event.dart';
import '../bloc/exercise_stats/exercise_stats_state.dart';
import '../../domain/entities/exercise_history_session.dart';

class ExerciseStatsBottomSheet extends StatelessWidget {
  final String userId;
  final String exerciseId;
  final String exerciseName;

  const ExerciseStatsBottomSheet({
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
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (_) => ExerciseStatsBottomSheet(
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
      child: GlassContainer(
        blur: 40,
        opacity: 0.05,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        padding: EdgeInsets.zero,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          color: Colors.black.withOpacity(0.4),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exerciseName.toUpperCase(),
                            style: AppTextStyles.heading1.copyWith(fontSize: 24),
                          ),
                          Text(
                            'ANÁLISIS DE PROGRESIÓN',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primary,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceHighlight,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<ExerciseStatsBloc, ExerciseStatsState>(
                  builder: (context, state) {
                    if (state is ExerciseStatsLoading) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    } else if (state is ExerciseStatsError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                            ),
                          ],
                        ),
                      );
                    } else if (state is ExerciseStatsLoaded) {
                      if (state.history.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.query_stats_rounded, color: AppColors.textDisabled, size: 64),
                              const SizedBox(height: 16),
                              Text(
                                'Aún no hay datos para este ejercicio',
                                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textDisabled),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        children: [
                          _buildChartSection(
                            title: 'PESO MÁXIMO',
                            subtitle: 'Evolución de fuerza pura',
                            icon: Icons.fitness_center_rounded,
                            chart: _MaxWeightChart(history: state.history),
                          ),
                          const SizedBox(height: 32),
                          _buildChartSection(
                            title: '1RM ESTIMADO',
                            subtitle: 'Repetición máxima proyectada',
                            icon: Icons.trending_up_rounded,
                            chart: _1RMChart(history: state.history),
                          ),
                          const SizedBox(height: 32),
                          _buildChartSection(
                            title: 'VOLUMEN TOTAL',
                            subtitle: 'Carga de trabajo por sesión',
                            icon: Icons.stacked_line_chart_rounded,
                            chart: _VolumeChart(history: state.history),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            'HISTORIAL DETALLADO',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...state.history.map((session) => _buildHistorySessionItem(session)),
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
      ),
    );
  }

  Widget _buildChartSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget chart,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1)),
                Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled, fontSize: 10)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(10, 16, 20, 10),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.surfaceHighlight),
          ),
          child: chart,
        ),
      ],
    );
  }

  Widget _buildHistorySessionItem(ExerciseHistorySession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'es').format(session.sessionDate).toUpperCase(),
                style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
              Text(
                '${session.totalVolume.toStringAsFixed(0)} kg Vol.',
                style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textDisabled),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: session.logs.map((log) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${log.actualWeight.toStringAsFixed(0)}kg x ${log.actualReps}',
                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _MaxWeightChart extends StatelessWidget {
  final List<dynamic> history;
  const _MaxWeightChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final reversed = history.reversed.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < reversed.length; i++) {
      spots.add(FlSpot(i.toDouble(), reversed[i].maxWeight));
    }
    if (spots.length == 1) spots.add(FlSpot(1.0, reversed.first.maxWeight));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: AppColors.surfaceHighlight, strokeWidth: 1),
        ),
        titlesData: _buildTitlesData(reversed),
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
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _1RMChart extends StatelessWidget {
  final List<dynamic> history;
  const _1RMChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final reversed = history.reversed.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < reversed.length; i++) {
      spots.add(FlSpot(i.toDouble(), reversed[i].estimated1RM));
    }
    if (spots.length == 1) spots.add(FlSpot(1.0, reversed.first.estimated1RM));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: AppColors.surfaceHighlight, strokeWidth: 1),
        ),
        titlesData: _buildTitlesData(reversed),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF00E5FF), // Cyan para 1RM
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF00E5FF).withOpacity(0.15),
                  const Color(0xFF00E5FF).withOpacity(0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeChart extends StatelessWidget {
  final List<dynamic> history;
  const _VolumeChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final reversed = history.reversed.toList();
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < reversed.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: reversed[i].totalVolume,
              color: AppColors.primary.withOpacity(0.8),
              width: 12,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        titlesData: _buildTitlesData(reversed),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }
}

FlTitlesData _buildTitlesData(List<dynamic> history) {
  return FlTitlesData(
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 40,
        getTitlesWidget: (value, meta) => Text(
          value.toStringAsFixed(0),
          style: AppTextStyles.label.copyWith(color: AppColors.textDisabled, fontSize: 9),
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
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                DateFormat('d/M').format(history[i].sessionDate),
                style: AppTextStyles.label.copyWith(color: AppColors.textDisabled, fontSize: 8),
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
