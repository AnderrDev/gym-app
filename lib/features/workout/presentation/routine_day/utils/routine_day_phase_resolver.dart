import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_state.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_day/routine_day_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_phase.dart';

/// Compone la fase visual de `RoutineDayPage` a partir de los dos estados
/// que la dominan: `RoutineDayState` (prestart) y `ActiveWorkoutState`
/// (sesión activa). La sesión activa tiene prioridad sobre el prestart.
RoutineDayPhase resolveRoutineDayPhase({
  required RoutineDayState routine,
  required ActiveWorkoutState active,
  required String fallbackUserId,
  required String fallbackRoutineDayId,
  required DateTime fallbackSessionDate,
}) {
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
        userId: routine.userId ?? fallbackUserId,
        routineDayId: routine.routineDayId ?? fallbackRoutineDayId,
        sessionDate: routine.sessionDate ?? fallbackSessionDate,
      );
  }
}

const _monthsEs = [
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

String formatRoutineDayDateLabel(DateTime date) =>
    '${date.day} ${_monthsEs[date.month]} ${date.year}';
