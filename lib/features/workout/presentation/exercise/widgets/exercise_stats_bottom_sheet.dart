import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/ui/adaptive/adaptive_scroll_physics.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/adaptive/adaptive_sheet.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';
import 'package:gym_flutter/core/ui/molecules/bottom_sheet_handle.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_history_session.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_state.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_history_session_item.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_stats_chart_section.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_stats_charts.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_stats_series.dart';
import 'package:gym_flutter/injection_container.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/weight_format.dart';

class ExerciseStatsBottomSheet extends StatelessWidget {
  final String userId;
  final String exerciseId;
  final String exerciseName;

  /// `true` cuando el widget se monta como página fullscreen
  /// (`ExerciseProgressPage`) en vez de modal. En ese caso el contenido va
  /// directo sobre el `Scaffold`, sin el panel con esquinas del modal.
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
          // Mismo margen lateral que la lista de abajo (`lgPlus`).
          padding: const EdgeInsets.fromLTRB(
            Spacing.lgPlus,
            Spacing.lg,
            Spacing.lgPlus,
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
                      exerciseName,
                      style: context.text.headlineSmall?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Progreso del ejercicio',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
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
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => context.read<ExerciseStatsBloc>().add(
                          LoadExerciseStats(
                            userId: userId,
                            exerciseId: exerciseId,
                          ),
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reintentar'),
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
                          color: context.colors.textSecondary,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aún no hay datos para este ejercicio',
                          style: context.text.bodyLarge?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _LoadedView(history: state.history);
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );

    // En modal: panel sólido `background` (las cards internas son
    // `surface` y así se separan). El dimming de lo que queda detrás lo pone
    // la barrera del modal, no el panel.
    final Widget content = fullscreen
        ? inner
        : Container(
            height: MediaQuery.of(context).size.height * 0.85,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.colors.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Radii.xxl),
              ),
            ),
            child: inner,
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

enum _Range {
  month('1 mes', 30),
  quarter('3 meses', 91),
  half('6 meses', 182),
  all('Todo', null);

  const _Range(this.label, this.days);
  final String label;
  final int? days;
}

enum _Metric { maxWeight, oneRm, volume }

/// Periodo + métrica elegidos, una gráfica y el historial del periodo. Antes
/// eran tres gráficas seguidas que sólo se comparaban con la sesión anterior.
class _LoadedView extends StatefulWidget {
  const _LoadedView({required this.history});

  /// Más reciente primero.
  final List<ExerciseHistorySession> history;

  @override
  State<_LoadedView> createState() => _LoadedViewState();
}

class _LoadedViewState extends State<_LoadedView> {
  var _range = _Range.all;
  var _metric = _Metric.maxWeight;

  /// Periodos que recortan algo: si todo el historial cabe en un mes, los
  /// chips no harían nada.
  List<_Range> get _ranges {
    final span = widget.history.first.sessionDate
        .difference(widget.history.last.sessionDate)
        .inDays;
    return [
      for (final r in _Range.values)
        if (r.days == null || r.days! < span) r,
    ];
  }

  List<ExerciseHistorySession> get _inRange {
    final days = _range.days;
    if (days == null) return widget.history;
    final from = widget.history.first.sessionDate.subtract(
      Duration(days: days),
    );
    return widget.history.where((s) => !s.sessionDate.isBefore(from)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ranges = _ranges;
    final history = _inRange;
    final section = switch (_metric) {
      _Metric.maxWeight => ExerciseStatsChartSection(
        title: 'PESO MÁXIMO',
        subtitle: 'El peso más alto que cargaste en una serie',
        icon: Icons.local_fire_department_rounded,
        unit: 'kg',
        series: ExerciseStatsSeries.from(history, (s) => s.maxWeight),
        formatter: formatWeight,
        chart: ExerciseMaxWeightChart(history: history),
      ),
      _Metric.oneRm => ExerciseStatsChartSection(
        title: '1RM ESTIMADO',
        subtitle: 'Lo que podrías levantar a 1 repetición, según tus series',
        icon: Icons.trending_up_rounded,
        unit: 'kg',
        series: ExerciseStatsSeries.from(history, (s) => s.estimated1RM),
        formatter: formatDecimal,
        chart: ExerciseEstimated1RMChart(history: history),
      ),
      _Metric.volume => ExerciseStatsChartSection(
        title: 'VOLUMEN',
        subtitle: 'Peso × reps sumado en la sesión',
        icon: Icons.stacked_line_chart_rounded,
        unit: 'kg',
        series: ExerciseStatsSeries.from(history, (s) => s.totalVolume),
        formatter: formatVolume,
        chart: ExerciseVolumeChart(history: history),
      ),
    };

    return ListView(
      physics: AdaptiveScrollPhysics.preferred,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lgPlus,
        0,
        Spacing.lgPlus,
        Spacing.xxxl,
      ),
      children: [
        SegmentedButton<_Metric>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: _Metric.maxWeight, label: Text('Peso máx.')),
            ButtonSegment(value: _Metric.oneRm, label: Text('1RM')),
            ButtonSegment(value: _Metric.volume, label: Text('Volumen')),
          ],
          selected: {_metric},
          onSelectionChanged: (v) => setState(() => _metric = v.first),
        ),
        if (ranges.length > 1) ...[
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            children: [
              for (final r in ranges)
                ChoiceChip(
                  label: Text(r.label),
                  selected: _range == r,
                  onSelected: (_) => setState(() => _range = r),
                ),
            ],
          ),
        ],
        const SizedBox(height: Spacing.lg),
        section,
        const SizedBox(height: 40),
        Text(
          history.length == 1 ? '1 SESIÓN' : '${history.length} SESIONES',
          style: context.text.labelMedium?.copyWith(
            color: context.colors.textSecondary,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        ...history.map(
          (session) => ExerciseHistorySessionItem(session: session),
        ),
      ],
    );
  }
}
