import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/notifications/active_workout_notifier.dart';
import 'package:gym_flutter/core/notifications/live_activities_bridge.dart';
import 'package:gym_flutter/core/notifications/notification_service.dart';
import 'package:gym_flutter/core/ui/adaptive/adaptive_sheet.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
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

  @override
  void initState() {
    super.initState();
    _restController = RestTimerController(
      notifier: di.sl<ActiveWorkoutNotifier>(),
      liveActivities: di.sl<LiveActivitiesBridge>(),
      notifications: di.sl<NotificationService>(),
      onNaturalEnd: _onRestNaturalEnd,
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
    super.dispose();
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
    final routineState = context.read<RoutineDayBloc>().state;
    if (routineState.status != RoutineDayStatus.ready) return;
    unawaited(HapticFeedback.heavyImpact());
    // Pedimos permiso de notis al primer arranque — contexto claro (cronómetro
    // en lock screen). Si se deniega seguimos, sólo nos perdemos la noti.
    await di.sl<NotificationService>().requestPermission();
    if (!mounted) return;
    context.read<ActiveWorkoutBloc>().add(
      StartActiveWorkout(
        userId: routineState.userId ?? widget.userId,
        routineDayId: routineState.routineDayId ?? widget.routineDay.id,
        routineDayName: widget.routineDay.name,
      ),
    );
  }

  void _onSetAdded(SetLog log) {
    context.read<ActiveWorkoutBloc>().add(SaveActiveSetLog(log));
    _restController.start(90);
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

  void _onShowLastSessionDetails(
    WorkoutSession session,
    List<SetLog> logs,
    List<Exercise> exercises,
  ) {
    HapticFeedback.mediumImpact();
    AdaptiveSheet.showRaw<void>(
      context,
      builder: (_) => WorkoutHistoryBottomSheet(
        session: session,
        logs: logs,
        exercises: exercises,
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
        totalTargetSets: widget.routineDay.targetSetsCount,
        totalCompletedSets: active.setLogs.length,
        totalVolume: totalVolume,
        exercises: active.exercises,
        currentLogs: active.setLogs,
        lastLogs: lastLogs,
        analysis: analysis,
        onContinue: () => Navigator.pop(ctx),
        onFinishAndSave: () {
          Navigator.pop(ctx);
          context.read<ActiveWorkoutBloc>().add(
            FinishActiveWorkout(
              sessionId: active.session.id,
              coachingAnalysis: analysis,
            ),
          );
        },
      ),
    );
  }

  void _retry() {
    context.read<RoutineDayBloc>().add(
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
        listener: (context, state) {
          // Si al cargar detectamos una sesión existente, transferimos al
          // ActiveWorkoutBloc directamente.
          final existing = state.existingSession;
          if (existing == null) return;
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
            final actionError = state.actionError;
            if (actionError != null) {
              AppSnackBar.error(context, actionError);
            }
            if (state.status == ActiveWorkoutStatus.finished) {
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
                    activeState.status == ActiveWorkoutStatus.failure) {
                  return false;
                }
                return previous != current;
              },
              builder: (context, routineState) {
                final phase = resolveRoutineDayPhase(
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
                  phase: phase,
                  routineDay: widget.routineDay,
                  // Con sesión, la fecha real (hoy si se inició desde un día
                  // pasado); sin sesión, el día elegido en el calendario.
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
                  onShowLastSessionDetails: _onShowLastSessionDetails,
                  onRetry: _retry,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
