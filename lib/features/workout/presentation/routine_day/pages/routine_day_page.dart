import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:gym_flutter/core/i18n/app_strings.dart';
import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/notifications/active_workout_notifier.dart';
import 'package:gym_flutter/core/notifications/live_activities_bridge.dart';
import 'package:gym_flutter/core/notifications/notification_service.dart';
import 'package:gym_flutter/core/ui/adaptive/adaptive_sheet.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/core/utils/clock.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/domain/workout_completion.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_session_exercises.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_exercises_catalog.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/session_exercise_sheet.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_state.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_day/routine_day_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_day/routine_day_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_day/routine_day_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/utils/rest_timer_controller.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/utils/routine_day_phase_resolver.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_phase.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_view_scaffold.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_history_bottom_sheet.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_summary_bottom_sheet.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/workout_performance_analyzer.dart';
import 'package:gym_flutter/injection_container.dart' as di;
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_finished_coaching.dart';

class RoutineDayPage extends StatefulWidget {
  const RoutineDayPage({
    super.key,
    required this.routineDay,
    required this.userId,
    required this.sessionDate,
  });

  final RoutineDay routineDay;
  final String userId;
  final DateTime sessionDate;

  @override
  State<RoutineDayPage> createState() => _RoutineDayPageState();
}

class _RoutineDayPageState extends State<RoutineDayPage> {
  late final RestTimerController _restController;
  bool _startRequested = false;

  @override
  void initState() {
    super.initState();
    _restController = RestTimerController(
      notifier: di.sl<ActiveWorkoutNotifier>(),
      liveActivities: di.sl<LiveActivitiesBridge>(),
      notifications: di.sl<NotificationService>(),
      onNaturalEnd: _onRestNaturalEnd,
      clock: di.sl<Clock>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RoutineDayBloc>().add(
        LoadRoutineDay(
          userId: widget.userId,
          routineDayId: widget.routineDay.id,
          sessionDate: widget.sessionDate,
        ),
      );
    });
  }

  @override
  void dispose() {
    _restController.dispose();
    _setKeepScreenOn(false);
    super.dispose();
  }

  /// Entre series el móvil queda apoyado sin tocarlo: mientras la sesión
  /// está en marcha la pantalla no se apaga. Si la plataforma no lo
  /// soporta (p. ej. navegador sin Screen Wake Lock) se ignora.
  bool _keepScreenOn = false;

  void _setKeepScreenOn(bool enabled) {
    if (_keepScreenOn == enabled) return;
    _keepScreenOn = enabled;
    unawaited(WakelockPlus.toggle(enable: enabled).catchError((_) {}));
  }

  void _onRestNaturalEnd() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('¡A entrenar! Próxima serie te espera'),
        backgroundColor: context.colors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onStartWorkout() async {
    if (_startRequested) return;
    final routineState = context.read<RoutineDayBloc>().state;
    final activeState = context.read<ActiveWorkoutBloc>().state;
    if (routineState.status != RoutineDayStatus.ready ||
        routineState.hasAnotherActiveSession ||
        activeState.isStarting ||
        activeState.isRunning) {
      return;
    }
    setState(() => _startRequested = true);
    unawaited(HapticFeedback.heavyImpact());
    // El permiso del cronómetro no debe retrasar el inicio ni bloquear la web.
    unawaited(
      di.sl<NotificationService>().requestPermission().catchError((_) => false),
    );
    context.read<ActiveWorkoutBloc>().add(
      StartActiveWorkout(
        userId: routineState.userId ?? widget.userId,
        routineDayId: routineState.routineDayId ?? widget.routineDay.id,
        routineDayName: widget.routineDay.name,
      ),
    );
  }

  void _onSetAdded(SetLog log) {
    final state = context.read<ActiveWorkoutBloc>().state;
    // Editar una serie ya registrada no es terminar otra: el descanso en
    // curso no se reinicia.
    final isEdit = state.setLogs.any(
      (l) => l.exerciseId == log.exerciseId && l.setIndex == log.setIndex,
    );
    context.read<ActiveWorkoutBloc>().add(SaveActiveSetLog(log));
    if (isEdit) return;
    final exercise = state.exercises.firstWhereOrNull(
      (e) => e.id == log.exerciseId,
    );
    _restController.start(exercise?.restTimerSeconds ?? 90);
  }

  void _onSetRemoved(String exerciseId, int setIndex) {
    final session = context.read<ActiveWorkoutBloc>().state.session;
    if (session == null) return;
    context.read<ActiveWorkoutBloc>().add(
      UnsaveActiveSetLog(
        sessionId: session.id,
        exerciseId: exerciseId,
        setIndex: setIndex,
      ),
    );
    // No iniciamos descanso al desmarcar — el usuario está corrigiendo.
  }

  Future<void> _onShowLastSessionDetails(
    WorkoutSession session,
    List<SetLog> logs,
    List<Exercise> exercises,
  ) async {
    unawaited(HapticFeedback.mediumImpact());
    final result = await di.sl<GetSessionExercises>()(session.id);
    if (!mounted) return;
    if (result.isLeft()) {
      AppSnackBar.error(
        context,
        'No se pudieron cargar los ejercicios de esa sesión. Intenta de nuevo.',
      );
      return;
    }
    final sessionExercises = result.getOrElse((_) => const <Exercise>[]);
    await AdaptiveSheet.showRaw<void>(
      context,
      builder: (_) => WorkoutHistoryBottomSheet(
        session: session,
        logs: logs,
        exercises: sessionExercises,
      ),
    );
  }

  Future<void> _onAdaptExercise([Exercise? replacing]) async {
    final bloc = context.read<ActiveWorkoutBloc>();
    final before = bloc.state;
    if (!before.isRunning ||
        before.isAdapting ||
        before.session?.completedAt != null) {
      return;
    }
    final completed = before.setLogs
        .where((log) => log.exerciseId == replacing?.id)
        .length;
    final selection = await SessionExerciseSheet.show(
      context,
      getCatalog: di.sl<GetExercisesCatalog>(),
      excludedExerciseIds: before.exercises.map((ex) => ex.id).toSet(),
      replacing: replacing,
      remainingSets: replacing == null
          ? null
          : replacing.targetSets - completed,
    );
    if (!mounted ||
        selection == null ||
        bloc.state.session?.id != before.session?.id ||
        !bloc.state.isRunning ||
        bloc.state.isAdapting) {
      return;
    }
    bloc.add(
      AdaptActiveWorkoutExercise(
        exerciseId: selection.exerciseId,
        targetSets: selection.targetSets,
        targetReps: selection.targetReps,
        targetWeight: selection.targetWeight,
        replaceExerciseId: replacing?.id,
      ),
    );
  }

  void _onFinishWorkout(RoutineDayActivePhase active) {
    final analysis = WorkoutPerformanceAnalyzer.analyzePerformance(
      active.exercises,
      active.setLogs,
      history: active.recentSessions,
      historyLogs: active.recentSessionsLogs,
    );
    final lastSession = active.recentSessions.firstOrNull;
    final lastLogs = lastSession != null
        ? (active.recentSessionsLogs[lastSession.id] ?? const <SetLog>[])
        : const <SetLog>[];
    final totalVolume = active.setLogs.fold<double>(
      0,
      (sum, l) => sum + (l.actualWeight * l.actualReps),
    );

    AdaptiveSheet.showRaw<void>(
      context,
      builder: (ctx) => WorkoutSummaryBottomSheet(
        totalTargetSets: totalTargetSets(active.exercises),
        totalCompletedSets: completedTargetSets(
          active.exercises,
          active.setLogs,
        ),
        totalVolume: totalVolume,
        exercises: active.exercises,
        currentLogs: active.setLogs,
        lastLogs: lastLogs,
        analysis: analysis,
        onContinue: () => Navigator.pop(ctx),
        onFinishAndSave: () {
          Navigator.pop(ctx);
          context.read<ActiveWorkoutBloc>().add(
            FinishActiveWorkout(sessionId: active.session.id),
          );
        },
      ),
    );
  }

  Future<void> _onDiscardWorkout(RoutineDayActivePhase active) async {
    final completed = active.setLogs.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Descartar este entrenamiento?'),
        content: Text(
          completed == 0
              ? 'Se borrará la sesión y no quedará en tu historial.'
              : 'Se borrarán la sesión y las $completed '
                    '${completed == 1 ? 'serie registrada' : 'series registradas'}. '
                    'No quedará en tu historial ni en tus estadísticas. '
                    'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: dialogContext.colors.error,
              foregroundColor: dialogContext.colors.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(AppStrings.discard),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<ActiveWorkoutBloc>().add(
      DiscardActiveWorkout(sessionId: active.session.id),
    );
  }

  Future<void> _showCoachingAndClose(List<CoachingAnalysis> coaching) async {
    if (coaching.isNotEmpty) {
      await AdaptiveSheet.show<void>(
        context,
        child: Builder(
          builder: (sheetContext) => WorkoutFinishedCoaching(
            coaching: coaching,
            onDone: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      );
    }
    if (!mounted) return;
    context.pop(true);
  }

  void _retry() {
    // Si falló iniciar o reanudar, el error lo tiene ActiveWorkoutBloc y
    // domina la fase: hay que limpiarlo. Reiniciar también RoutineDayBloc
    // hace que el listener vuelva a ver `existingSession` y reanude.
    context.read<ActiveWorkoutBloc>().add(const ResetActiveWorkout());
    context.read<RoutineDayBloc>()
      ..add(const ResetRoutineDay())
      ..add(
        LoadRoutineDay(
          userId: widget.userId,
          routineDayId: widget.routineDay.id,
          sessionDate: widget.sessionDate,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<RoutineDayBloc>().add(const ResetRoutineDay());
          context.read<ActiveWorkoutBloc>().add(const ResetActiveWorkout());
        }
      },
      child: BlocListener<RoutineDayBloc, RoutineDayState>(
        listenWhen: (p, c) =>
            p.existingSession != c.existingSession && c.existingSession != null,
        listener: (context, state) async {
          final existing = state.existingSession;
          if (existing == null) return;
          if (existing.completedAt == null &&
              !DateUtils.isSameDay(existing.sessionDate, DateTime.now())) {
            final continuePrevious = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Tienes una sesión anterior pendiente'),
                content: Text(
                  'Empezaste esta sesión el ${formatRoutineDayDateLabel(existing.sessionDate)}. '
                  'Al continuarla conserva esa fecha y las series guardadas. '
                  'Finalízala o descártala (menú ⋮) antes de comenzar un entrenamiento nuevo de hoy.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Volver'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Continuar sesión anterior'),
                  ),
                ],
              ),
            );
            if (!context.mounted) return;
            if (continuePrevious != true) {
              context.pop();
              return;
            }
          }
          if (!context.mounted) return;
          context.read<ActiveWorkoutBloc>().add(
            ResumeActiveWorkout(
              session: existing,
              exercises: state.exercises,
              lastPerformances: state.lastPerformances,
              recentSessions: state.recentSessions,
              recentSessionsLogs: state.recentSessionsLogs,
            ),
          );
        },
        child: BlocConsumer<ActiveWorkoutBloc, ActiveWorkoutState>(
          listenWhen: (p, c) =>
              p.status != c.status || p.actionErrorNonce != c.actionErrorNonce,
          listener: (context, state) {
            if (!mounted) return;
            if (_startRequested && state.status != ActiveWorkoutStatus.idle) {
              setState(() => _startRequested = false);
            }
            _setKeepScreenOn(state.status == ActiveWorkoutStatus.running);
            final actionError = state.actionError;
            if (actionError != null) {
              AppSnackBar.error(context, actionError);
            }
            if (state.status == ActiveWorkoutStatus.finished) {
              unawaited(_showCoachingAndClose(state.finalCoaching));
            }
            if (state.status == ActiveWorkoutStatus.discarded) {
              AppSnackBar.success(context, 'Entrenamiento descartado');
              context.pop(true);
            }
          },
          builder: (context, activeState) {
            return BlocBuilder<RoutineDayBloc, RoutineDayState>(
              buildWhen: (previous, current) {
                // Cuando ActiveWorkoutBloc domina la fase (running, starting,
                // finishing, failure), `_composePhase` ignora el routineState.
                // Cualquier cambio remoto durante el workout no debe rebuildear.
                if (activeState.status == ActiveWorkoutStatus.running ||
                    activeState.isStarting ||
                    activeState.isFinishing ||
                    activeState.isDiscarding ||
                    activeState.status == ActiveWorkoutStatus.failure) {
                  return false;
                }
                return previous != current;
              },
              builder: (context, routineState) {
                final phase =
                    _startRequested &&
                        activeState.status == ActiveWorkoutStatus.idle
                    ? const RoutineDayLoadingPhase(
                        message: 'Iniciando entrenamiento…',
                      )
                    : resolveRoutineDayPhase(
                        routine: routineState,
                        active: activeState,
                        fallbackUserId: widget.userId,
                        fallbackRoutineDayId: widget.routineDay.id,
                        fallbackSessionDate: widget.sessionDate,
                      );
                final session = activeState.session;
                final isCompleted = session?.completedAt != null;
                final totalVolume = activeState.setLogs.fold<double>(
                  0,
                  (sum, l) => sum + (l.actualWeight * l.actualReps),
                );

                return RoutineDayViewScaffold(
                  setDrafts: activeState.setDrafts,
                  phase: phase,
                  routineDay: widget.routineDay,
                  // Siempre la fecha real de la sesión o la fecha de inicio.
                  dateLabel: formatRoutineDayDateLabel(
                    session?.sessionDate ?? widget.sessionDate,
                  ),
                  effectiveReadOnly: isCompleted,
                  isCompleted: isCompleted,
                  currentSessionLogs: activeState.setLogs,
                  totalVolume: totalVolume,
                  restTimer: _restController.snapshot,
                  onClose: () => context.pop(),
                  onSkipRest: _restController.stop,
                  onAdjustRest: _restController.adjust,
                  onStartWorkout: _onStartWorkout,
                  onSetAdded: _onSetAdded,
                  onSetRemoved: _onSetRemoved,
                  onFinishWorkout: _onFinishWorkout,
                  onDiscardWorkout: _onDiscardWorkout,
                  onShowLastSessionDetails: _onShowLastSessionDetails,
                  onRetry: _retry,
                  isAdapting: activeState.isAdapting,
                  onAddExercise: () => _onAdaptExercise(),
                  onReplaceExercise: _onAdaptExercise,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
