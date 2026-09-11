import 'package:equatable/equatable.dart';

import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';

abstract class ActiveWorkoutEvent extends Equatable {
  const ActiveWorkoutEvent();

  @override
  List<Object?> get props => const [];
}

/// El usuario confirma iniciar la sesión. Crea la sesión en backend.
///
/// No lleva fecha: una sesión nueva siempre se registra con la fecha de hoy
/// (la decide el bloc vía `Clock`), aunque se haya abierto desde un día
/// anterior del calendario.
class StartActiveWorkout extends ActiveWorkoutEvent {
  const StartActiveWorkout({
    required this.userId,
    required this.routineDayId,
    required this.routineDayName,
  });

  final String userId;
  final String routineDayId;
  final String routineDayName;

  @override
  List<Object?> get props => [userId, routineDayId, routineDayName];
}

/// Se detectó una sesión preexistente al cargar `RoutineDayBloc` y queremos
/// reanudarla sin crear una nueva.
class ResumeActiveWorkout extends ActiveWorkoutEvent {
  const ResumeActiveWorkout({
    required this.session,
    required this.exercises,
    required this.lastPerformances,
    this.recentSessions = const [],
    this.recentSessionsLogs = const {},
  });

  final WorkoutSession session;
  final List<Exercise> exercises;
  final Map<String, SetLog?> lastPerformances;
  final List<WorkoutSession> recentSessions;
  final Map<String, List<SetLog>> recentSessionsLogs;

  @override
  List<Object?> get props => [
    session,
    exercises,
    lastPerformances,
    recentSessions,
    recentSessionsLogs,
  ];
}

/// Guarda (o actualiza) un set durante la sesión activa.
class SaveActiveSetLog extends ActiveWorkoutEvent {
  const SaveActiveSetLog(this.setLog);

  final SetLog setLog;

  @override
  List<Object?> get props => [setLog];
}

/// Desmarca un set guardado: lo borra del backend y del state.
class UnsaveActiveSetLog extends ActiveWorkoutEvent {
  const UnsaveActiveSetLog({
    required this.sessionId,
    required this.exerciseId,
    required this.setIndex,
  });

  final String sessionId;
  final String exerciseId;
  final int setIndex;

  @override
  List<Object?> get props => [sessionId, exerciseId, setIndex];
}

/// Actualiza el objetivo (peso/reps) de un ejercicio durante la sesión.
class UpdateActiveExerciseTarget extends ActiveWorkoutEvent {
  const UpdateActiveExerciseTarget({
    required this.exerciseId,
    required this.targetWeight,
    required this.targetReps,
  });

  final String exerciseId;
  final double targetWeight;
  final int targetReps;

  @override
  List<Object?> get props => [exerciseId, targetWeight, targetReps];
}

/// Finaliza la sesión, opcionalmente con coaching analysis.
class FinishActiveWorkout extends ActiveWorkoutEvent {
  const FinishActiveWorkout({required this.sessionId, this.coachingAnalysis});

  final String sessionId;
  final List<CoachingAnalysis>? coachingAnalysis;

  @override
  List<Object?> get props => [sessionId, coachingAnalysis];
}

/// Resetea el bloc al estado inicial (al salir de la pantalla).
class ResetActiveWorkout extends ActiveWorkoutEvent {
  const ResetActiveWorkout();
}
