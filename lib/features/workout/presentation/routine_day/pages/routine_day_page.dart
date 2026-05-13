import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_flutter/core/notifications/notification_service.dart';
import 'package:gym_flutter/injection_container.dart' as di;
import 'package:gym_flutter/core/ui/feedback/app_bottom_sheet.dart';
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
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/rest_timer_button.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_phase.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_view_scaffold.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_history_bottom_sheet.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_summary_bottom_sheet.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/workout_performance_analyzer.dart';

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
  Timer? _globalRestTimer;
  final ValueNotifier<RestTimerSnapshot> _restTimer = ValueNotifier(
    const RestTimerSnapshot.idle(),
  );

  @override
  void initState() {
    super.initState();
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
    _globalRestTimer?.cancel();
    _restTimer.dispose();
    super.dispose();
  }

  void _startRestTimer(int seconds) {
    _globalRestTimer?.cancel();
    _restTimer.value = RestTimerSnapshot(
      isResting: true,
      secondsRemaining: seconds,
      totalRestSeconds: seconds,
    );
    _globalRestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = _restTimer.value;
      if (current.secondsRemaining > 0) {
        final next = current.secondsRemaining - 1;
        _restTimer.value = RestTimerSnapshot(
          isResting: true,
          secondsRemaining: next,
          totalRestSeconds: current.totalRestSeconds,
        );
        if (next > 0 && next <= 3) HapticFeedback.lightImpact();
      } else {
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    _globalRestTimer?.cancel();
    _restTimer.value = const RestTimerSnapshot.idle();
    HapticFeedback.heavyImpact();
  }

  /// Ajusta el descanso en curso. Si quedaría <= 0, lo detiene.
  void _adjustRestSeconds(int delta) {
    final current = _restTimer.value;
    if (!current.isResting) return;
    final newRemaining = current.secondsRemaining + delta;
    if (newRemaining <= 0) {
      _stopTimer();
      return;
    }
    // El total también se mueve para que la barra de progreso siga
    // representando "lo que falta" de manera coherente.
    final newTotal = (current.totalRestSeconds + delta).clamp(
      newRemaining,
      9999,
    );
    _restTimer.value = RestTimerSnapshot(
      isResting: true,
      secondsRemaining: newRemaining,
      totalRestSeconds: newTotal,
    );
  }

  String get _dateLabel {
    const months = [
      '',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${widget.sessionDate.day} '
        '${months[widget.sessionDate.month]} ${widget.sessionDate.year}';
  }

  RoutineDayPhase _composePhase(
    RoutineDayState routine,
    ActiveWorkoutState active,
  ) {
    if (active.status == ActiveWorkoutStatus.failure) {
      return RoutineDayErrorPhase(
        active.errorMessage ?? 'Error al iniciar la sesión',
      );
    }
    if (active.isStarting || active.isFinishing) {
      return const RoutineDayLoadingPhase();
    }
    if (active.isRunning && active.session != null) {
      return RoutineDayActivePhase(
        session: active.session!,
        exercises: active.exercises,
        setLogs: active.setLogs,
        lastPerformances: active.lastPerformances,
        recentSessions: active.recentSessions,
        recentSessionsLogs: active.recentSessionsLogs,
      );
    }

    switch (routine.status) {
      case RoutineDayStatus.initial:
      case RoutineDayStatus.loading:
        return const RoutineDayLoadingPhase();
      case RoutineDayStatus.failure:
        return RoutineDayErrorPhase(
          routine.errorMessage ?? 'Error desconocido',
        );
      case RoutineDayStatus.ready:
        return RoutineDayPrestartPhase(
          exercises: routine.exercises,
          recentSessions: routine.recentSessions,
          recentSessionsLogs: routine.recentSessionsLogs,
          lastPerformances: routine.lastPerformances,
          hasAnotherActiveSession: routine.hasAnotherActiveSession,
          anotherActiveSessionDayName: routine.anotherActiveSessionDayName,
          userId: routine.userId ?? widget.userId,
          routineDayId: routine.routineDayId ?? widget.routineDay.id,
          sessionDate: routine.sessionDate ?? widget.sessionDate,
        );
    }
  }

  Future<void> _onStartWorkout() async {
    final routineState = context.read<RoutineDayBloc>().state;
    if (routineState.status != RoutineDayStatus.ready) return;
    unawaited(HapticFeedback.heavyImpact());
    // Pedimos permiso de notis al primer arranque de un workout — contexto
    // claro de por qué lo necesitamos (cronómetro en lock screen). Si el
    // usuario lo deniega seguimos igual, sólo nos perdemos la noti.
    await di.sl<NotificationService>().requestPermission();
    if (!mounted) return;
    context.read<ActiveWorkoutBloc>().add(
      StartActiveWorkout(
        userId: routineState.userId ?? widget.userId,
        routineDayId: routineState.routineDayId ?? widget.routineDay.id,
        sessionDate: routineState.sessionDate ?? widget.sessionDate,
        routineDayName: widget.routineDay.name,
      ),
    );
  }

  void _onSetAdded(SetLog log) {
    context.read<ActiveWorkoutBloc>().add(SaveActiveSetLog(log));
    _startRestTimer(90);
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
    // No iniciamos descanso al desmarcar — el usuario está corrigiendo, no
    // terminando una serie.
  }

  void _onShowLastSessionDetails(
    WorkoutSession session,
    List<SetLog> logs,
    List<Exercise> exercises,
  ) {
    HapticFeedback.mediumImpact();
    AppBottomSheet.showRaw<void>(
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

    AppBottomSheet.showRaw<void>(
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
          listenWhen: (p, c) => p.status != c.status,
          listener: (context, state) {
            if (state.status == ActiveWorkoutStatus.finished) {
              if (!mounted) return;
              context.pop(true);
            }
          },
          builder: (context, activeState) {
            return BlocBuilder<RoutineDayBloc, RoutineDayState>(
              buildWhen: (previous, current) {
                // Cuando el ActiveWorkoutBloc domina la fase (running,
                // starting, finishing, failure), `_composePhase` ignora el
                // routineState. Cualquier cambio remoto del RoutineDayBloc
                // durante el workout no debe rebuildear el scaffold.
                if (activeState.status == ActiveWorkoutStatus.running ||
                    activeState.isStarting ||
                    activeState.isFinishing ||
                    activeState.status == ActiveWorkoutStatus.failure) {
                  return false;
                }
                return previous != current;
              },
              builder: (context, routineState) {
                final phase = _composePhase(routineState, activeState);
                final session = activeState.session;
                final isCompleted = session?.completedAt != null;
                final effectiveReadOnly = isCompleted;
                final totalVolume = activeState.setLogs.fold<double>(
                  0,
                  (sum, l) => sum + (l.actualWeight * l.actualReps),
                );

                return RoutineDayViewScaffold(
                  phase: phase,
                  routineDay: widget.routineDay,
                  dateLabel: _dateLabel,
                  effectiveReadOnly: effectiveReadOnly,
                  isCompleted: isCompleted,
                  currentSessionLogs: activeState.setLogs,
                  totalVolume: totalVolume,
                  restTimer: _restTimer,
                  onClose: () => context.pop(),
                  onSkipRest: _stopTimer,
                  onAdjustRest: _adjustRestSeconds,
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
