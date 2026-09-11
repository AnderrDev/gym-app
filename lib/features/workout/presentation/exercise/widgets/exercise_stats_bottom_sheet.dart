import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/ui/adaptive/adaptive_scroll_physics.dart';
import 'package:gym_flutter/core/presentation/widgets/glass_container.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/adaptive/adaptive_sheet.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';
import 'package:gym_flutter/core/ui/molecules/bottom_sheet_handle.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_state.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_history_session_item.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_stats_chart_section.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_stats_charts.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_stats_series.dart';
import 'package:gym_flutter/injection_container.dart';

class ExerciseStatsBottomSheet extends StatelessWidget {
  final String userId;
  final String exerciseId;
  final String exerciseName;

  /// `true` cuando el widget se monta como página fullscreen
  /// (`ExerciseProgressPage`) en vez de modal. En ese caso saltamos el
  /// wrapper glass + el overlay 40% negro — el overlay tiene sentido como
  /// dimming sobre la pantalla detrás, pero sobre el `Scaffold` blanco
  /// produce un gris oscuro que se lee como "modo oscuro".
  final bool fullscreen;

  const ExerciseStatsBottomSheet({
    super.key,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    this.fullscreen = false,
  });

  static void show(
    BuildContext context, {
    required String userId,
    required String exerciseId,
    required String exerciseName,
  }) {
    AdaptiveSheet.showRaw<void>(
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
    final inner = Column(
      children: [
        if (!fullscreen) const BottomSheetHandle(),
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
                      style: context.text.displayLarge?.copyWith(fontSize: 24),
                    ),
                    Text(
                      'ANÁLISIS DE PROGRESIÓN',
                      style: context.text.labelMedium?.copyWith(
                        color: context.colors.primary,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (!fullscreen)
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: context.colors.textPrimary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: context.colors.surfaceHighlight,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<ExerciseStatsBloc, ExerciseStatsState>(
            builder: (context, state) {
              if (state is ExerciseStatsLoading) {
                return const Center(child: AppSpinner.large());
              } else if (state is ExerciseStatsError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: context.colors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.error,
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
                        Icon(
                          Icons.query_stats_rounded,
                          color: context.colors.textDisabled,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aún no hay datos para este ejercicio',
                          style: context.text.bodyLarge?.copyWith(
                            color: context.colors.textDisabled,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  physics: AdaptiveScrollPhysics.preferred,
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lgPlus,
                    0,
                    Spacing.lgPlus,
                    Spacing.xxxl,
                  ),
                  children: [
                    ExerciseStatsChartSection(
                      title: 'PESO MÁXIMO',
                      subtitle: 'El peso más alto que cargaste en una serie',
                      icon: Icons.local_fire_department_rounded,
                      unit: 'kg',
                      series: ExerciseStatsSeries.from(
                        state.history,
                        (s) => s.maxWeight,
                      ),
                      formatter: (v) => v.toStringAsFixed(0),
                      chart: ExerciseMaxWeightChart(history: state.history),
                    ),
                    const SizedBox(height: 32),
                    ExerciseStatsChartSection(
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
                    ExerciseStatsChartSection(
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
                      style: context.text.labelMedium?.copyWith(
                        color: context.colors.textSecondary,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...state.history.map(
                      (session) =>
                          ExerciseHistorySessionItem(session: session),
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );

    // En modal: glass blur + dimming oscuro sobre la pantalla detrás.
    // En fullscreen: sin wrapper — el contenido va directo sobre el
    // `Scaffold` blanco de `ExerciseProgressPage`.
    final Widget content = fullscreen
        ? inner
        : GlassContainer(
            blur: 40,
            opacity: 0.05,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
            padding: EdgeInsets.zero,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              color: context.colors.overlay.withValues(alpha: 0.4),
              child: inner,
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
}
