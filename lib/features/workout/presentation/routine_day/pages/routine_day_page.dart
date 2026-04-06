import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_state.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/workout_performance_analyzer.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_view_scaffold.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_history_bottom_sheet.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_summary_bottom_sheet.dart';

class RoutineDayPage extends StatefulWidget {
  final RoutineDay routineDay;
  final String userId;
  final DateTime sessionDate;

  const RoutineDayPage({
    super.key,
    required this.routineDay,
    required this.userId,
    required this.sessionDate,
  });

  @override
  State<RoutineDayPage> createState() => _RoutineDayPageState();
}

class _RoutineDayPageState extends State<RoutineDayPage> {
  final List<SetLog> _currentSessionLogs = [];

  void _syncCurrentLogs(List<SetLog> logs) {
    _currentSessionLogs
      ..clear()
      ..addAll(logs);
  }

  // ── Timer Global ──────────────────────────────────────────
  Timer? _globalRestTimer;
  int _secondsRemaining = 0;
  int _totalRestSeconds = 60;
  bool _isResting = false;

  @override
  void dispose() {
    _globalRestTimer?.cancel();
    super.dispose();
  }

  void _startRestTimer(int seconds) {
    _globalRestTimer?.cancel();
    setState(() {
      _secondsRemaining = seconds;
      _totalRestSeconds = seconds;
      _isResting = true;
    });

    _globalRestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
        if (_secondsRemaining <= 3 && _secondsRemaining > 0) {
          HapticFeedback.lightImpact();
        }
      } else {
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    _globalRestTimer?.cancel();
    setState(() {
      _isResting = false;
      _secondsRemaining = 0;
    });
    HapticFeedback.heavyImpact();
  }

  String _formatTime(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    context.read<WorkoutBloc>().add(
      LoadDayInfo(
        userId: widget.userId,
        routineDayId: widget.routineDay.id,
        sessionDate: widget.sessionDate,
      ),
    );
  }

  void _onSetAdded(SetLog log) {
    setState(() {
      final idx = _currentSessionLogs.indexWhere(
        (l) => l.exerciseId == log.exerciseId && l.setIndex == log.setIndex,
      );
      if (idx != -1) {
        _currentSessionLogs[idx] = log;
      } else {
        _currentSessionLogs.add(log);
      }
    });

    // Iniciar timer global (90s por defecto si no es edición)
    _startRestTimer(90);
  }

  double get _totalVolume => _currentSessionLogs.fold(
    0.0,
    (s, l) => s + (l.actualWeight * l.actualReps),
  );

  bool get _isReadOnly => false;

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
    return '${widget.sessionDate.day} ${months[widget.sessionDate.month]} ${widget.sessionDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && result == true) {
          context.read<WorkoutBloc>().add(const ResetWorkout());
        }
      },
      child: BlocConsumer<WorkoutBloc, WorkoutState>(
        buildWhen: (previous, current) {
          return current is WorkoutInitial ||
              current is WorkoutLoading ||
              current is WorkoutError ||
              current is DayInfoLoaded ||
              current is DayWorkoutStarted ||
              current is WorkoutFinishedSuccess;
        },
        listenWhen: (previous, current) =>
            current is WorkoutFinishedSuccess || current is DayWorkoutStarted,
        listener: (context, state) {
          if (state is DayWorkoutStarted) {
            _syncCurrentLogs(state.setLogs);
          }

          if (state is WorkoutFinishedSuccess) {
            if (!mounted) {
              return;
            }
            context.pop(true);
          }
        },
        builder: (context, state) {
          final session = state is DayWorkoutStarted ? state.session : null;
          final isCompleted = session?.completedAt != null;
          final effectiveReadOnly = _isReadOnly || isCompleted;

          return RoutineDayViewScaffold(
            state: state,
            routineDay: widget.routineDay,
            dateLabel: _dateLabel,
            effectiveReadOnly: effectiveReadOnly,
            isCompleted: isCompleted,
            currentSessionLogs: _currentSessionLogs,
            totalVolume: _totalVolume,
            isResting: _isResting,
            secondsRemaining: _secondsRemaining,
            totalRestSeconds: _totalRestSeconds,
            formatTime: _formatTime,
            onClose: () => context.pop(),
            onRestTimerTap: () {
              if (_isResting) {
                _stopTimer();
                return;
              }
              _startRestTimer(60);
            },
            onStartWorkout: () {
              if (state is! DayInfoLoaded) {
                return;
              }
              HapticFeedback.heavyImpact();
              context.read<WorkoutBloc>().add(
                ConfirmStartWorkout(
                  userId: state.userId,
                  routineDayId: state.routineDayId,
                  sessionDate: state.sessionDate,
                  routineDayName: widget.routineDay.name,
                ),
              );
            },
            onSetAdded: _onSetAdded,
            onFinishWorkout: (startedState) {
              final analysis = WorkoutPerformanceAnalyzer.analyzePerformance(
                startedState.exercises,
                _currentSessionLogs,
                history: startedState.recentSessions,
                historyLogs: startedState.recentSessionsLogs,
              );
              _showSummaryModal(
                context,
                startedState.exercises,
                _currentSessionLogs,
                startedState.session.id,
                analysis,
              );
            },
            onShowLastSessionDetails: _showLastSessionDetails,
            onRetry: () => context.read<WorkoutBloc>().add(
              LoadDayInfo(
                userId: widget.userId,
                routineDayId: widget.routineDay.id,
                sessionDate: widget.sessionDate,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLastSessionDetails(
    WorkoutSession session,
    List<SetLog> logs,
    List<Exercise> exercises,
  ) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkoutHistoryBottomSheet(
        session: session,
        logs: logs,
        exercises: exercises,
      ),
    );
  }

  void _showSummaryModal(
    BuildContext context,
    List<Exercise> exercises,
    List<SetLog> logs,
    String sessionId,
    List<CoachingAnalysis> analysis,
  ) {
    final totalTarget = widget.routineDay.targetSetsCount;
    final totalCompleted = logs.length;

    // Datos de sesión anterior para la comparación
    final bloc = context.read<WorkoutBloc>();
    final currentState = bloc.state;
    final recentSessions = currentState is DayWorkoutStarted
        ? currentState.recentSessions
        : <WorkoutSession>[];
    final recentLogs = currentState is DayWorkoutStarted
        ? currentState.recentSessionsLogs
        : <String, List<SetLog>>{};
    final lastSession = recentSessions.firstOrNull;
    final lastLogs = lastSession != null
        ? (recentLogs[lastSession.id] ?? <SetLog>[])
        : <SetLog>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WorkoutSummaryBottomSheet(
        totalTargetSets: totalTarget,
        totalCompletedSets: totalCompleted,
        totalVolume: _totalVolume,
        exercises: exercises,
        currentLogs: logs,
        lastLogs: lastLogs,
        analysis: analysis,
        onContinue: () => Navigator.pop(ctx),
        onFinishAndSave: () {
          Navigator.pop(ctx);
          context.read<WorkoutBloc>().add(
            FinishWorkoutSession(sessionId, coachingAnalysis: analysis),
          );
        },
      ),
    );
  }
}

// _StatHeaderDelegate removed as it was merged into SliverAppBar.bottom
