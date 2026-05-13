import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/atoms/app_button.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/rest_banner.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/rest_timer_button.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_active_focus_view.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_app_bar.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_error_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_phase.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_prestart_view.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_status_strip.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/workout_performance_analyzer.dart';

/// Render del día de rutina. Consume un `RoutineDayPhase` (view model) para
/// mantenerse desacoplado de los blocs concretos.
class RoutineDayViewScaffold extends StatelessWidget {
  const RoutineDayViewScaffold({
    super.key,
    required this.phase,
    required this.routineDay,
    required this.dateLabel,
    required this.effectiveReadOnly,
    required this.isCompleted,
    required this.currentSessionLogs,
    required this.totalVolume,
    required this.restTimer,
    required this.onClose,
    required this.onSkipRest,
    required this.onAdjustRest,
    required this.onStartWorkout,
    required this.onSetAdded,
    required this.onSetRemoved,
    required this.onFinishWorkout,
    required this.onShowLastSessionDetails,
    required this.onRetry,
  });

  final RoutineDayPhase phase;
  final RoutineDay routineDay;
  final String dateLabel;
  final bool effectiveReadOnly;
  final bool isCompleted;
  final List<SetLog> currentSessionLogs;
  final double totalVolume;
  final ValueListenable<RestTimerSnapshot> restTimer;
  final VoidCallback onClose;
  final VoidCallback onSkipRest;
  final void Function(int deltaSeconds) onAdjustRest;
  final VoidCallback onStartWorkout;
  final void Function(SetLog log) onSetAdded;
  final void Function(String exerciseId, int setIndex) onSetRemoved;
  final void Function(RoutineDayActivePhase active) onFinishWorkout;
  final void Function(
    WorkoutSession session,
    List<SetLog> logs,
    List<Exercise> exercises,
  )
  onShowLastSessionDetails;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final exercises = _exercisesOf(phase);
    final recentSessions = _recentSessionsOf(phase);
    final recentSessionsLogs = _recentSessionsLogsOf(phase);
    final lastSession = recentSessions.firstOrNull;
    final lastLogs = lastSession != null
        ? (recentSessionsLogs[lastSession.id] ?? <SetLog>[])
        : <SetLog>[];
    final isActive = phase is RoutineDayActivePhase;

    final scroll = CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        RoutineDayAppBar(
          routineDay: routineDay,
          dateLabel: dateLabel,
          lastSession: lastSession,
          lastLogs: lastLogs,
          exercises: exercises,
          isActive: isActive,
          totalVolume: totalVolume,
          completedSets: currentSessionLogs.length,
          // `routineDay.targetSetsCount` viene en 0 cuando el day se cargó por
          // un endpoint que no embebe los ejercicios (lista, navegación
          // directa). Lo derivamos en vivo de la lista de ejercicios cargada.
          totalSets: exercises.fold<int>(0, (sum, ex) => sum + ex.targetSets),
          onClose: onClose,
          onShowLastSessionDetails: onShowLastSessionDetails,
          onFinish: isActive && !effectiveReadOnly
              ? () {
                  HapticFeedback.heavyImpact();
                  onFinishWorkout(phase as RoutineDayActivePhase);
                }
              : null,
        ),
        // Strip solo visible para mostrar el badge de lectura/completado.
        // El volumen activo se movió al chip del app bar.
        if (effectiveReadOnly)
          RoutineDayStatusStrip(
            isWorkoutStarted: false,
            totalVolume: totalVolume,
            effectiveReadOnly: effectiveReadOnly,
            isCompleted: isCompleted,
          ),
        ..._buildContentSlivers(context),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isActive
          ? SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Banner top sticky de descanso (animado in/out).
                  RestBanner(
                    snapshot: restTimer,
                    onSkip: onSkipRest,
                    onAdjust: onAdjustRest,
                  ),
                  Expanded(child: scroll),
                ],
              ),
            )
          : scroll,
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget? _buildBottomNavigation(BuildContext context) {
    if (phase is RoutineDayPrestartPhase) {
      final prestart = phase as RoutineDayPrestartPhase;
      return _PrestartBottomBar(
        locked: prestart.hasAnotherActiveSession,
        onStartWorkout: onStartWorkout,
      );
    }
    // En fase activa ya no hay bottom bar: la acción "Finalizar" vive en el
    // app bar y el descanso se anuncia con el banner sticky.
    return null;
  }

  List<Widget> _buildContentSlivers(BuildContext context) {
    final current = phase;
    if (current is RoutineDayLoadingPhase) {
      return const [
        SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ];
    }
    if (current is RoutineDayErrorPhase) {
      return [
        SliverFillRemaining(
          child: RoutineDayErrorState(
            message: current.message,
            onRetry: onRetry,
          ),
        ),
      ];
    }
    if (current is RoutineDayPrestartPhase) {
      return [
        SliverToBoxAdapter(
          child: RoutineDayPreStartView(
            exercises: current.exercises,
            recentSessions: current.recentSessions,
            recentSessionsLogs: current.recentSessionsLogs,
            hasAnotherActiveSession: current.hasAnotherActiveSession,
            anotherActiveSessionDayName: current.anotherActiveSessionDayName,
            onOpenLastSession: onShowLastSessionDetails,
          ),
        ),
      ];
    }
    if (current is RoutineDayActivePhase) {
      final liveAnalysis = WorkoutPerformanceAnalyzer.analyzePerformance(
        current.exercises,
        currentSessionLogs,
        history: current.recentSessions,
        historyLogs: current.recentSessionsLogs,
      );
      final coachingByExercise = <String, CoachingAnalysis?>{
        for (final ex in current.exercises)
          ex.id: liveAnalysis.firstWhereOrNull(
            (a) => a.exerciseId == ex.id || a.exerciseName == ex.name,
          ),
      };
      return [
        SliverFillRemaining(
          hasScrollBody: true,
          child: RoutineDayActiveFocusView(
            sessionId: current.session.id,
            exercises: current.exercises,
            completedLogs: currentSessionLogs,
            lastPerformances: current.lastPerformances,
            coachingAnalyses: coachingByExercise,
            effectiveReadOnly: effectiveReadOnly,
            onSetAdded: (log) {
              onSetAdded(log);
              HapticFeedback.selectionClick();
            },
            onSetRemoved: effectiveReadOnly ? null : onSetRemoved,
            onFinishWorkout: effectiveReadOnly
                ? null
                : () {
                    HapticFeedback.heavyImpact();
                    onFinishWorkout(current);
                  },
          ),
        ),
      ];
    }
    return const [SliverFillRemaining(child: SizedBox())];
  }

  List<Exercise> _exercisesOf(RoutineDayPhase p) {
    if (p is RoutineDayPrestartPhase) return p.exercises;
    if (p is RoutineDayActivePhase) return p.exercises;
    return const [];
  }

  List<WorkoutSession> _recentSessionsOf(RoutineDayPhase p) {
    if (p is RoutineDayPrestartPhase) return p.recentSessions;
    if (p is RoutineDayActivePhase) return p.recentSessions;
    return const [];
  }

  Map<String, List<SetLog>> _recentSessionsLogsOf(RoutineDayPhase p) {
    if (p is RoutineDayPrestartPhase) return p.recentSessionsLogs;
    if (p is RoutineDayActivePhase) return p.recentSessionsLogs;
    return const {};
  }
}

class _PrestartBottomBar extends StatelessWidget {
  const _PrestartBottomBar({required this.locked, required this.onStartWorkout});

  final bool locked;
  final VoidCallback onStartWorkout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.sm,
        Spacing.lg,
        Spacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: AppButton(
          label: locked
              ? 'Tienes una sesión en curso'
              : 'Empezar entrenamiento',
          icon: locked ? Icons.lock_outline_rounded : Icons.play_arrow_rounded,
          onPressed: locked ? null : onStartWorkout,
        ),
      ),
    );
  }
}
