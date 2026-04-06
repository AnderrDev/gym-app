import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/presentation/widgets/glass_container.dart';
import 'package:gym_flutter/core/presentation/widgets/kinetic_button.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_state.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/workout_performance_analyzer.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_card.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/rest_timer_button.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_app_bar.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_error_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_live_coaching_section.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_prestart_view.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_status_strip.dart';

class RoutineDayViewScaffold extends StatelessWidget {
  final WorkoutState state;
  final RoutineDay routineDay;
  final String dateLabel;
  final bool effectiveReadOnly;
  final bool isCompleted;
  final List<SetLog> currentSessionLogs;
  final double totalVolume;
  final bool isResting;
  final int secondsRemaining;
  final int totalRestSeconds;
  final String Function(int) formatTime;
  final VoidCallback onClose;
  final VoidCallback onRestTimerTap;
  final VoidCallback onStartWorkout;
  final void Function(SetLog log) onSetAdded;
  final void Function(DayWorkoutStarted state) onFinishWorkout;
  final void Function(
    WorkoutSession session,
    List<SetLog> logs,
    List<Exercise> exercises,
  )
  onShowLastSessionDetails;
  final VoidCallback onRetry;

  const RoutineDayViewScaffold({
    super.key,
    required this.state,
    required this.routineDay,
    required this.dateLabel,
    required this.effectiveReadOnly,
    required this.isCompleted,
    required this.currentSessionLogs,
    required this.totalVolume,
    required this.isResting,
    required this.secondsRemaining,
    required this.totalRestSeconds,
    required this.formatTime,
    required this.onClose,
    required this.onRestTimerTap,
    required this.onStartWorkout,
    required this.onSetAdded,
    required this.onFinishWorkout,
    required this.onShowLastSessionDetails,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final snapshot = _stateSnapshot(state);
    final recentSessions = snapshot.recentSessions;
    final recentSessionsLogs = snapshot.recentSessionsLogs;
    final lastSession = recentSessions.firstOrNull;
    final lastLogs = lastSession != null
        ? (recentSessionsLogs[lastSession.id] ?? <SetLog>[])
        : <SetLog>[];
    final exercises = snapshot.exercises;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          RoutineDayAppBar(
            routineDay: routineDay,
            dateLabel: dateLabel,
            lastSession: lastSession,
            lastLogs: lastLogs,
            exercises: exercises,
            onClose: onClose,
            onShowLastSessionDetails: onShowLastSessionDetails,
          ),
          RoutineDayStatusStrip(
            isWorkoutStarted: state is DayWorkoutStarted,
            totalVolume: totalVolume,
            effectiveReadOnly: effectiveReadOnly,
            isCompleted: isCompleted,
          ),
          ..._buildContentSlivers(context),
          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
      bottomNavigationBar: (effectiveReadOnly || state is DayInfoLoaded)
          ? null
          : _buildBottomBar(context, exercises),
    );
  }

  List<Widget> _buildContentSlivers(BuildContext context) {
    if (state is WorkoutInitial || state is WorkoutLoading) {
      return const [
        SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ];
    }
    if (state is WorkoutError) {
      return [
        SliverFillRemaining(
          child: RoutineDayErrorState(
            message: (state as WorkoutError).message,
            onRetry: onRetry,
          ),
        ),
      ];
    }
    if (state is DayInfoLoaded) {
      return [
        SliverToBoxAdapter(
          child: RoutineDayPreStartView(
            state: state as DayInfoLoaded,
            onStartWorkout: onStartWorkout,
            onOpenLastSession: onShowLastSessionDetails,
          ),
        ),
      ];
    }
    if (state is DayWorkoutStarted) {
      final started = state as DayWorkoutStarted;
      final liveAnalysis = WorkoutPerformanceAnalyzer.analyzePerformance(
        started.exercises,
        currentSessionLogs,
        history: started.recentSessions,
        historyLogs: started.recentSessionsLogs,
      );

      return [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final ex = started.exercises[index];
              final exAnalysis = liveAnalysis.firstWhereOrNull(
                (a) => a.exerciseId == ex.id || a.exerciseName == ex.name,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ExerciseCard(
                  exercise: ex,
                  sessionId: started.session.id,
                  initialCompletedSets: currentSessionLogs,
                  lastPerformance: started.lastPerformances[ex.id],
                  readOnly: effectiveReadOnly,
                  coachingAnalysis: exAnalysis,
                  onSetAdded: effectiveReadOnly
                      ? null
                      : (log) {
                          onSetAdded(log);
                          HapticFeedback.selectionClick();
                        },
                ),
              );
            }, childCount: started.exercises.length),
          ),
        ),
        RoutineDayLiveCoachingSection(state: started, logs: currentSessionLogs),
      ];
    }
    return const [SliverFillRemaining(child: SizedBox())];
  }

  Widget _buildBottomBar(BuildContext context, List<Exercise> exercises) {
    return GlassContainer(
      blur: 30,
      opacity: 0.1,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
      child: Row(
        children: [
          RestTimerButton(
            isResting: isResting,
            secondsRemaining: secondsRemaining,
            totalRestSeconds: totalRestSeconds,
            onTap: onRestTimerTap,
            formatTime: formatTime,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EN PROGRESO',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '${exercises.length} ejercicios planificados',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          KineticButton(
            fullWidth: false,
            label: 'FINALIZAR',
            onTap: () {
              HapticFeedback.heavyImpact();
              if (state is DayWorkoutStarted) {
                onFinishWorkout(state as DayWorkoutStarted);
              }
            },
          ),
        ],
      ),
    );
  }

  _WorkoutStateSnapshot _stateSnapshot(WorkoutState currentState) {
    if (currentState is DayInfoLoaded) {
      return _WorkoutStateSnapshot(
        exercises: currentState.exercises,
        recentSessions: currentState.recentSessions,
        recentSessionsLogs: currentState.recentSessionsLogs,
      );
    }
    if (currentState is DayWorkoutStarted) {
      return _WorkoutStateSnapshot(
        exercises: currentState.exercises,
        recentSessions: currentState.recentSessions,
        recentSessionsLogs: currentState.recentSessionsLogs,
      );
    }
    return const _WorkoutStateSnapshot();
  }
}

class _WorkoutStateSnapshot {
  final List<Exercise> exercises;
  final List<WorkoutSession> recentSessions;
  final Map<String, List<SetLog>> recentSessionsLogs;

  const _WorkoutStateSnapshot({
    this.exercises = const [],
    this.recentSessions = const [],
    this.recentSessionsLogs = const {},
  });
}
