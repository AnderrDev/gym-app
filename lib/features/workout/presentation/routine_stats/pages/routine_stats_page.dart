import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/ui/molecules/app_error_state.dart';
import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/adaptive/adaptive_sheet.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';
import 'package:gym_flutter/core/utils/calendar_dates.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_history_session.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_session_detail.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_stats/routine_stats_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_stats/routine_stats_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_stats/routine_stats_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_stats/widgets/routine_session_card.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_history_bottom_sheet.dart';
import 'package:gym_flutter/features/workout/presentation/routine_stats/widgets/routine_stats_volume_chart.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/training_history.dart';
import 'package:gym_flutter/injection_container.dart';

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
        appBar: AppBar(
          elevation: 0,
          title: Text(
            'Historial: $routineName',
            style: context.text.headlineMedium,
          ),
        ),
        // El error se muestra en el cuerpo con Reintentar (antes además
        // salía un snackbar con el mismo texto).
        body: BlocBuilder<RoutineStatsBloc, RoutineStatsState>(
          buildWhen: (previous, current) =>
              current is RoutineStatsLoading ||
              current is RoutineStatsLoaded ||
              current is RoutineStatsError,
          builder: (context, state) {
            if (state is RoutineStatsLoading) {
              return const Center(child: AppSpinner.large());
            }
            if (state is RoutineStatsError) {
              return AppErrorState(
                message: state.message,
                onRetry: () => context.read<RoutineStatsBloc>().add(
                  FetchRoutineStats(userId: userId, routineId: routineId),
                ),
              );
            }
            if (state is RoutineStatsLoaded) {
              if (state.stats.isEmpty) return const _EmptyState();
              return _StatsContent(stats: state.stats, userId: userId);
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 64,
            color: context.colors.surfaceHighlight,
          ),
          const SizedBox(height: 16),
          Text('Sin datos suficientes', style: context.text.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Completa sesiones para ver tu evolución.',
            style: context.text.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Filtro por día de rutina + gráfica + lista de sesiones. Con "Todos" la
/// gráfica va por semanas (comparar una sesión de Torso con una de Pierna
/// no dice nada); con un día, sesión a sesión.
class _StatsContent extends StatefulWidget {
  const _StatsContent({required this.stats, required this.userId});

  /// Más reciente primero.
  final List<RoutineHistorySession> stats;
  final String userId;

  @override
  State<_StatsContent> createState() => _StatsContentState();
}

class _StatsContentState extends State<_StatsContent> {
  String? _dayId;
  String? _openingSessionId;

  Future<void> _openSession(RoutineHistorySession s) async {
    if (s.sessionId.isEmpty || _openingSessionId != null) return;
    setState(() => _openingSessionId = s.sessionId);
    final result = await sl<GetSessionDetail>()(
      sessionId: s.sessionId,
      userId: widget.userId,
      routineDayId: s.routineDayId,
      sessionDate: s.sessionDate,
    );
    if (!mounted) return;
    setState(() => _openingSessionId = null);
    await result.match(
      (_) async => AppSnackBar.error(
        context,
        'No se pudo abrir esa sesión. Intenta de nuevo.',
      ),
      (detail) => AdaptiveSheet.showRaw<void>(
        context,
        builder: (_) => WorkoutHistoryBottomSheet(
          session: detail.session,
          logs: detail.logs,
          exercises: detail.exercises,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Días en el orden en que aparecen (el más reciente primero).
    final days = <String, String>{};
    for (final s in widget.stats) {
      days.putIfAbsent(s.routineDayId, () => s.routineDayName);
    }
    final dayId = days.containsKey(_dayId) ? _dayId : null;
    final sessions = dayId == null
        ? widget.stats
        : widget.stats.where((s) => s.routineDayId == dayId).toList();

    final List<VolumePoint> points;
    if (dayId == null) {
      final first = AppCalendar.startOfWeek(widget.stats.last.sessionDate);
      final last = AppCalendar.startOfWeek(widget.stats.first.sessionDate);
      final weeks = last.difference(first).inDays ~/ 7 + 1;
      points = [
        for (final w in weeklyTotals(
          widget.stats,
          lastWeekStart: last,
          weeks: weeks,
        ))
          if (w.sessions > 0) (date: w.weekStart, volume: w.volume),
      ];
    } else {
      points = [
        for (final s in sessions.reversed)
          (date: s.sessionDate, volume: s.totalVolume),
      ];
    }

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        if (days.length > 1) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final entry in [
                  const MapEntry<String?, String>(null, 'Todos los días'),
                  ...days.entries,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: Spacing.sm),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: dayId == entry.key,
                      onSelected: (_) => setState(() => _dayId = entry.key),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
        ],
        RoutineStatsVolumeChart(
          points: points,
          subtitle: dayId == null
              ? 'Peso × reps sumado de cada semana entrenada'
              : 'Peso × reps sumado de cada sesión de ${days[dayId]}',
          deltaCaption: dayId == null ? 'VS SEMANA ANT.' : 'VS SESIÓN ANT.',
        ),
        const SizedBox(height: 24),
        Text(
          sessions.length == 1 ? '1 SESIÓN' : '${sessions.length} SESIONES',
          style: context.text.labelMedium?.copyWith(letterSpacing: 2),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          'Toca una sesión para ver sus series.',
          style: context.text.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ...sessions.map(
          (s) => RoutineSessionCard(
            session: s,
            loading: _openingSessionId == s.sessionId,
            onTap: s.sessionId.isEmpty ? null : () => _openSession(s),
          ),
        ),
      ],
    );
  }
}
