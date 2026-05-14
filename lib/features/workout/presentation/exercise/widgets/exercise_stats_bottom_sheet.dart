import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/presentation/widgets/glass_container.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_bottom_sheet.dart';
import 'package:gym_flutter/core/ui/feedback/barbell_loader.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_history_session.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_state.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_stats_charts.dart';
import 'package:gym_flutter/features/workout/presentation/shared/widgets/stat_stripe.dart';
import 'package:gym_flutter/injection_container.dart';

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

  static void show(
    BuildContext context, {
    required String userId,
    required String exerciseId,
    required String exerciseName,
  }) {
    AppBottomSheet.showRaw<void>(
      context,
      builder: (_) => ExerciseStatsBottomSheet(
        userId: userId,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = GlassContainer(
      blur: 40,
      opacity: 0.05,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      padding: EdgeInsets.zero,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        color: Colors.black.withValues(alpha: 0.4),
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
              padding: const EdgeInsets.fromLTRB(
                Spacing.xl,
                Spacing.xl,
                Spacing.xl,
                Spacing.lg,
              ),
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
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textPrimary,
                    ),
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
                    return const Center(child: BarbellLoader.large());
                  } else if (state is ExerciseStatsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                            ),
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
                            const Icon(
                              Icons.query_stats_rounded,
                              color: AppColors.textDisabled,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aún no hay datos para este ejercicio',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textDisabled,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        Spacing.lgPlus,
                        0,
                        Spacing.lgPlus,
                        Spacing.xxxl,
                      ),
                      children: [
                        _buildChartSection(
                          title: 'PESO MÁXIMO',
                          subtitle: 'El peso más alto que cargaste en una serie',
                          icon: Icons.fitness_center_rounded,
                          unit: 'kg',
                          series: ExerciseStatsSeries.from(
                            state.history,
                            (s) => s.maxWeight,
                          ),
                          formatter: (v) => v.toStringAsFixed(0),
                          chart: ExerciseMaxWeightChart(history: state.history),
                        ),
                        const SizedBox(height: 32),
                        _buildChartSection(
                          title: '1RM ESTIMADO',
                          subtitle: 'Tu máxima en 1 rep, proyectada',
                          icon: Icons.trending_up_rounded,
                          unit: 'kg',
                          series: ExerciseStatsSeries.from(
                            state.history,
                            (s) => s.estimated1RM,
                          ),
                          formatter: (v) =>
                              v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1),
                          chart: ExerciseEstimated1RMChart(
                            history: state.history,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildChartSection(
                          title: 'CARGA MOVIDA',
                          subtitle: 'Suma de peso × reps en la sesión',
                          icon: Icons.stacked_line_chart_rounded,
                          unit: 'kg·reps',
                          series: ExerciseStatsSeries.from(
                            state.history,
                            (s) => s.totalVolume,
                          ),
                          formatter: (v) => v.toStringAsFixed(0),
                          chart: ExerciseVolumeChart(history: state.history),
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
                        ...state.history.map(
                          (session) => _buildHistorySessionItem(session),
                        ),
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

    try {
      context.read<ExerciseStatsBloc>();
      return content;
    } catch (_) {
      return BlocProvider(
        create: (_) =>
            sl<ExerciseStatsBloc>()
              ..add(LoadExerciseStats(userId: userId, exerciseId: exerciseId)),
        child: content,
      );
    }
  }

  Widget _buildChartSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required String unit,
    required ExerciseStatsSeries series,
    required String Function(double) formatter,
    required Widget chart,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    subtitle,
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
            color: AppColors.surface.withValues(alpha: 0.3),
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
      margin: const EdgeInsets.only(bottom: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
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
                DateFormat(
                  'EEEE, d MMMM yyyy',
                  'es',
                ).format(session.sessionDate).toUpperCase(),
                style: AppTextStyles.label.copyWith(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${session.totalVolume.toStringAsFixed(0)} kg Vol.',
                style: AppTextStyles.label.copyWith(
                  fontSize: 10,
                  color: AppColors.textDisabled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: session.logs
                .map(
                  (log) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${log.actualWeight.toStringAsFixed(0)}kg x ${log.actualReps}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
