import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_flutter/core/utils/date_format.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/routes/args/routing_args.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';
import 'package:gym_flutter/core/ui/molecules/app_card.dart';
import 'package:gym_flutter/core/utils/calendar_dates.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_state.dart';
import 'package:gym_flutter/features/workout/presentation/progress/widgets/progress_routine_tile.dart';
import 'package:gym_flutter/features/workout/presentation/progress/widgets/weekly_history_chart.dart';
import 'package:gym_flutter/features/workout/presentation/progress/widgets/weekly_insights_card.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/training_history.dart';
import 'package:gym_flutter/core/services/shell_tab_notifier.dart';
import 'package:gym_flutter/injection_container.dart' show sl;

/// Hub `/progress` (pestaña PROGRESO del shell).
///
/// (1) Resumen de una semana con selector ‹ › (por defecto la actual),
/// (2) histórico de las últimas 8 semanas (tocar una barra abre esa semana),
/// (3) historial por rutina → `/routine-stats` y (4) progreso por
/// ejercicio → `/exercise-progress`.
class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  ShellTabNotifier? _tabs;

  /// Semana pedida y aún no cargada: el selector la muestra al instante y
  /// una barra de progreso indica que el resumen se está actualizando.
  DateTime? _pendingWeek;

  @override
  void initState() {
    super.initState();
    // La pestaña sigue montada en el IndexedStack: sin esto, tras terminar un
    // entreno PROGRESO seguía con los datos de cuando se abrió por 1ª vez.
    _tabs = sl.isRegistered<ShellTabNotifier>() ? sl<ShellTabNotifier>() : null;
    _tabs?.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return;
      context.read<ProgressBloc>().add(LoadProgress(authState.user.id));
    });
  }

  @override
  void dispose() {
    _tabs?.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabs?.value != ShellTabNotifier.progressTab) return;
    final userId = _currentUserId();
    if (userId == null) return;
    final bloc = context.read<ProgressBloc>();
    // Refresh silencioso (sin Loading) sobre la semana que se está viendo.
    final current = bloc.state;
    bloc.add(
      RefreshProgress(
        userId,
        weekStart: current is ProgressReady ? current.weekStart : null,
      ),
    );
  }

  String? _currentUserId() {
    final authState = context.read<AuthBloc>().state;
    return authState is Authenticated ? authState.user.id : null;
  }

  void _retry() {
    final userId = _currentUserId();
    if (userId == null) return;
    context.read<ProgressBloc>().add(LoadProgress(userId));
  }

  Future<void> _onRefresh() async {
    final userId = _currentUserId();
    if (userId == null) return;
    final bloc = context.read<ProgressBloc>();
    final completer = Completer<void>();
    // Escuchamos hasta el próximo estado terminal (Ready o Failure) y ahí
    // resolvemos el future del RefreshIndicator. Limitado a 10s por las
    // dudas — el indicador se queda colgado eternamente si el bloc nunca
    // emite (no debería pasar pero defensive).
    late final StreamSubscription<ProgressState> sub;
    sub = bloc.stream.listen((state) {
      if (state is ProgressReady || state is ProgressFailure) {
        if (!completer.isCompleted) completer.complete();
        sub.cancel();
      }
    });
    // Refresca la semana que se está viendo, no vuelve a la actual.
    final current = bloc.state;
    bloc.add(
      RefreshProgress(
        userId,
        weekStart: current is ProgressReady ? current.weekStart : null,
      ),
    );
    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => sub.cancel(),
    );
  }

  void _selectWeek(DateTime weekStart) {
    final userId = _currentUserId();
    if (userId == null) return;
    final current = context.read<ProgressBloc>().state;
    if (current is ProgressReady && current.weekStart == weekStart) return;
    setState(() => _pendingWeek = weekStart);
    context.read<ProgressBloc>().add(
      RefreshProgress(userId, weekStart: weekStart),
    );
  }

  void _openRoutineStats(Routine routine) {
    final userId = _currentUserId();
    if (userId == null) return;
    pushRoutineStats(
      context,
      RoutineStatsArgs(
        userId: userId,
        routineId: routine.id,
        routineName: routine.name,
      ),
    );
  }

  void _openExerciseProgress(Exercise exercise) {
    final userId = _currentUserId();
    if (userId == null) return;
    pushExerciseProgress(
      context,
      ExerciseProgressArgs(
        userId: userId,
        exerciseId: exercise.id,
        exerciseName: exercise.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'PROGRESO',
          style: context.text.headlineMedium?.copyWith(letterSpacing: 2),
        ),
      ),
      body: BlocConsumer<ProgressBloc, ProgressState>(
        listener: (context, state) {
          if (state is ProgressReady || state is ProgressFailure) {
            setState(() => _pendingWeek = null);
          }
        },
        builder: (context, state) {
          return switch (state) {
            ProgressInitial() ||
            ProgressLoading() => const Center(child: AppSpinner.medium()),
            ProgressFailure(:final message) => _ProgressErrorView(
              message: message,
              onRetry: _retry,
            ),
            ProgressReady() => RefreshIndicator(
              onRefresh: _onRefresh,
              color: context.colors.primary,
              child: _ProgressReadyView(
                state: state,
                pendingWeek: _pendingWeek,
                onSelectWeek: _selectWeek,
                onOpenRoutine: _openRoutineStats,
                onGoToRoutines: () => goToRoutines(context),
                onOpenExercise: _openExerciseProgress,
              ),
            ),
          };
        },
      ),
    );
  }
}

// ── Failure view ───────────────────────────────────────────────────────────

class _ProgressErrorView extends StatelessWidget {
  const _ProgressErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: context.colors.error,
              size: 48,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.error,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'REINTENTAR',
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.onPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ready view ─────────────────────────────────────────────────────────────

class _ProgressReadyView extends StatelessWidget {
  const _ProgressReadyView({
    required this.state,
    required this.pendingWeek,
    required this.onSelectWeek,
    required this.onOpenRoutine,
    required this.onGoToRoutines,
    required this.onOpenExercise,
  });

  final ProgressReady state;
  final DateTime? pendingWeek;
  final ValueChanged<DateTime> onSelectWeek;
  final ValueChanged<Routine> onOpenRoutine;
  final VoidCallback onGoToRoutines;
  final ValueChanged<Exercise> onOpenExercise;

  @override
  Widget build(BuildContext context) {
    final currentWeek = AppCalendar.startOfWeek(DateTime.now());
    final shownWeek = pendingWeek ?? state.weekStart;
    // `AlwaysScrollableScrollPhysics` es necesario para que el
    // `RefreshIndicator` funcione cuando el contenido no llena la pantalla
    // (empty state, error de insights, etc).
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.md,
        Spacing.xl,
        Spacing.xxl + 80,
      ),
      children: [
        _WeekSelector(
          weekStart: shownWeek,
          currentWeek: currentWeek,
          onSelectWeek: onSelectWeek,
        ),
        SizedBox(
          height: 2,
          child: pendingWeek == null
              ? null
              : LinearProgressIndicator(color: context.colors.primary),
        ),
        const SizedBox(height: Spacing.sm),
        WeeklyInsightsCard(
          insights: state.insights,
          error: state.insightsError,
        ),
        if (state.routines.isNotEmpty) ...[
          const SizedBox(height: Spacing.xxl),
          const _SectionTitle(text: 'ÚLTIMAS 8 SEMANAS'),
          const SizedBox(height: Spacing.sm),
          WeeklyHistoryChart(
            weeks: weeklyTotals(state.history, lastWeekStart: currentWeek),
            selectedWeekStart: shownWeek,
            onSelectWeek: onSelectWeek,
          ),
        ],
        const SizedBox(height: Spacing.xxl),
        const _SectionTitle(text: 'HISTORIAL POR RUTINA'),
        const SizedBox(height: Spacing.sm),
        if (state.routines.isEmpty)
          ProgressEmptyRoutines(onGoToRoutines: onGoToRoutines)
        else
          ...state.routines.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: ProgressRoutineTile(
                routine: r,
                onTap: () => onOpenRoutine(r),
              ),
            ),
          ),
        if (state.exercises.isNotEmpty) ...[
          const SizedBox(height: Spacing.xxl),
          const _SectionTitle(text: 'PROGRESO POR EJERCICIO'),
          const SizedBox(height: Spacing.xs),
          Text(
            'Peso, 1RM estimado y volumen de cada ejercicio a lo largo del tiempo.',
            style: context.text.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          // Antes el progreso de un ejercicio sólo se abría desde la tarjeta
          // durante un entreno.
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, ex) in state.exercises.indexed) ...[
                  if (i > 0) Divider(height: 1, color: context.colors.divider),
                  ListTile(
                    title: Text(ex.name),
                    subtitle: Text(ex.targetMuscle),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: context.colors.textSecondary,
                    ),
                    onTap: () => onOpenExercise(ex),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Pieces ────────────────────────────────────────────────────────────────

/// "‹ Esta semana · 19 – 25 oct ›". No deja avanzar más allá de la semana
/// en curso.
class _WeekSelector extends StatelessWidget {
  const _WeekSelector({
    required this.weekStart,
    required this.currentWeek,
    required this.onSelectWeek,
  });

  final DateTime weekStart;
  final DateTime currentWeek;
  final ValueChanged<DateTime> onSelectWeek;

  String get _title {
    final weeksAgo = currentWeek.difference(weekStart).inDays ~/ 7;
    return switch (weeksAgo) {
      0 => 'Esta semana',
      1 => 'Semana pasada',
      _ => 'Hace $weeksAgo semanas',
    };
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = AppCalendar.addDays(weekStart, 6);
    final isCurrent = !weekStart.isBefore(currentWeek);
    return Row(
      children: [
        IconButton(
          tooltip: 'Semana anterior',
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => onSelectWeek(AppCalendar.addDays(weekStart, -7)),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                _title,
                style: context.text.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${AppDateFormat.dayMonthShort(weekStart)} – '
                '${AppDateFormat.dayMonthShort(weekEnd)}',
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Semana siguiente',
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: isCurrent
              ? null
              : () => onSelectWeek(AppCalendar.addDays(weekStart, 7)),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.text.labelMedium?.copyWith(
        color: context.colors.textSecondary,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
