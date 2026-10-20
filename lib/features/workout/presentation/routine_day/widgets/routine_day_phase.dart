import 'package:equatable/equatable.dart';

import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';

/// View model que el `RoutineDayViewScaffold` consume. Independiza al UI de
/// los blocs concretos (RoutineDayBloc / ActiveWorkoutBloc), permitiendo
/// testear y rediseñar sin acoplar.
sealed class RoutineDayPhase extends Equatable {
  const RoutineDayPhase();

  @override
  List<Object?> get props => const [];
}

class RoutineDayLoadingPhase extends RoutineDayPhase {
  const RoutineDayLoadingPhase({this.message = 'Cargando entrenamiento…'});

  final String message;

  @override
  List<Object?> get props => [message];
}

class RoutineDayErrorPhase extends RoutineDayPhase {
  const RoutineDayErrorPhase(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class RoutineDayPrestartPhase extends RoutineDayPhase {
  const RoutineDayPrestartPhase({
    required this.exercises,
    required this.recentSessions,
    required this.recentSessionsLogs,
    required this.lastPerformances,
    required this.hasAnotherActiveSession,
    required this.anotherActiveSessionDayName,
    required this.userId,
    required this.routineDayId,
    required this.sessionDate,
    this.isStarting = false,
  });

  final List<Exercise> exercises;
  final List<WorkoutSession> recentSessions;
  final Map<String, List<SetLog>> recentSessionsLogs;
  final Map<String, SetLog?> lastPerformances;
  final bool hasAnotherActiveSession;
  final String? anotherActiveSessionDayName;
  final String userId;
  final String routineDayId;
  final DateTime sessionDate;

  /// El usuario pulsó "Iniciar" y se está creando la sesión: la previa se
  /// mantiene en pantalla con el botón cargando en vez de saltar a una
  /// pantalla de carga en blanco.
  final bool isStarting;

  @override
  List<Object?> get props => [
    exercises,
    recentSessions,
    recentSessionsLogs,
    lastPerformances,
    hasAnotherActiveSession,
    anotherActiveSessionDayName,
    userId,
    routineDayId,
    sessionDate,
    isStarting,
  ];
}

class RoutineDayActivePhase extends RoutineDayPhase {
  const RoutineDayActivePhase({
    required this.session,
    required this.exercises,
    required this.setLogs,
    required this.lastPerformances,
    required this.recentSessions,
    required this.recentSessionsLogs,
    this.isFinishing = false,
  });

  final WorkoutSession session;
  final List<Exercise> exercises;
  final List<SetLog> setLogs;
  final Map<String, SetLog?> lastPerformances;
  final List<WorkoutSession> recentSessions;
  final Map<String, List<SetLog>> recentSessionsLogs;
  final bool isFinishing;

  @override
  List<Object?> get props => [
    session,
    exercises,
    setLogs,
    lastPerformances,
    recentSessions,
    recentSessionsLogs,
    isFinishing,
  ];
}
