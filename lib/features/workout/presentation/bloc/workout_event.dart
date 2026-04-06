import 'package:equatable/equatable.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';

sealed class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

// Carga las rutinas asignadas al usuario
final class FetchAssignedRoutines extends WorkoutEvent {
  final String userId;
  const FetchAssignedRoutines(this.userId);
  @override List<Object?> get props => [userId];
}

// Carga el plan semanal (días + estado de completado esta semana)
final class FetchWeeklyPlan extends WorkoutEvent {
  final String userId;
  final String routineId;
  final DateTime weekStart;
  const FetchWeeklyPlan({required this.userId, required this.routineId, required this.weekStart});
  @override List<Object?> get props => [userId, routineId, weekStart];
}

// Carga ejercicios del día y verifica si ya hay sesión (SIN crearla)
final class LoadDayInfo extends WorkoutEvent {
  final String userId;
  final String routineDayId;
  final DateTime sessionDate;
  const LoadDayInfo({required this.userId, required this.routineDayId, required this.sessionDate});
  @override List<Object?> get props => [userId, routineDayId, sessionDate];
}

// El usuario confirma que quiere iniciar — ahora sí se crea la sesión
final class ConfirmStartWorkout extends WorkoutEvent {
  final String userId;
  final String routineDayId;
  final DateTime sessionDate;
  final String routineDayName;
  const ConfirmStartWorkout({required this.userId, required this.routineDayId, required this.sessionDate, required this.routineDayName});
  @override List<Object?> get props => [userId, routineDayId, sessionDate, routineDayName];
}

// Carga los set logs históricos de una sesión completada
final class LoadSessionHistory extends WorkoutEvent {
  final String sessionId;
  const LoadSessionHistory(this.sessionId);
  @override List<Object?> get props => [sessionId];
}

// Registra una serie
final class AddSetLogEvent extends WorkoutEvent {
  final SetLog setLog;
  const AddSetLogEvent(this.setLog);
  @override List<Object?> get props => [setLog];
}

// Rendimiento anterior de un ejercicio
final class FetchLastExercisePerformance extends WorkoutEvent {
  final String exerciseId;
  const FetchLastExercisePerformance(this.exerciseId);
  @override List<Object?> get props => [exerciseId];
}

// Verifica si hay una sesión activa al arrancar la app
final class CheckActiveSession extends WorkoutEvent {
  final String userId;
  const CheckActiveSession(this.userId);
  @override List<Object?> get props => [userId];
}

final class ResetWorkout extends WorkoutEvent {
  const ResetWorkout();
}

final class FinishWorkoutSession extends WorkoutEvent {
  final String sessionId;
  final List<CoachingAnalysis>? coachingAnalysis;
  const FinishWorkoutSession(this.sessionId, {this.coachingAnalysis});
  @override List<Object?> get props => [sessionId, coachingAnalysis];
}

// ─── Nuevos Eventos de Gestión ──────────────────────────────────────────

final class CreateOrUpdateRoutine extends WorkoutEvent {
  final String userId;
  final String? id;
  final String name;
  final bool isPublic;
  const CreateOrUpdateRoutine({required this.userId, this.id, required this.name, this.isPublic = false});
  @override List<Object?> get props => [userId, id, name, isPublic];
}

final class DeleteRoutine extends WorkoutEvent {
  final String userId;
  final String routineId;
  const DeleteRoutine({required this.userId, required this.routineId});
  @override List<Object?> get props => [userId, routineId];
}

final class SaveRoutineDay extends WorkoutEvent {
  final String userId;
  final String routineId;
  final RoutineDay day;
  const SaveRoutineDay({required this.userId, required this.routineId, required this.day});
  @override List<Object?> get props => [userId, routineId, day];
}

final class DeleteRoutineDay extends WorkoutEvent {
  final String userId;
  final String dayId;
  final String routineId;
  const DeleteRoutineDay({required this.userId, required this.dayId, required this.routineId});
  @override List<Object?> get props => [userId, dayId, routineId];
}

final class ToggleExerciseInDay extends WorkoutEvent {
  final String userId;
  final String routineId;
  final String dayId;
  final String exerciseId;
  const ToggleExerciseInDay({required this.userId, required this.routineId, required this.dayId, required this.exerciseId});
  @override List<Object?> get props => [userId, routineId, dayId, exerciseId];
}

final class ReorderExercises extends WorkoutEvent {
  final String userId;
  final String routineId;
  final String dayId;
  final List<String> exerciseIds;
  const ReorderExercises({required this.userId, required this.routineId, required this.dayId, required this.exerciseIds});
  @override List<Object?> get props => [userId, routineId, dayId, exerciseIds];
}

final class UpdateExerciseTarget extends WorkoutEvent {
  final String exerciseId;
  final double targetWeight;
  final int targetReps;
  const UpdateExerciseTarget({required this.exerciseId, required this.targetWeight, required this.targetReps});
  @override List<Object?> get props => [exerciseId, targetWeight, targetReps];
}

// Carga todas las rutinas disponibles (Catálogo)
final class FetchAllRoutines extends WorkoutEvent {
  const FetchAllRoutines();
}

// Asigna una rutina como la activa para el usuario
final class AssignRoutineEvent extends WorkoutEvent {
  final String userId;
  final String routineId;
  const AssignRoutineEvent({required this.userId, required this.routineId});
  @override List<Object?> get props => [userId, routineId];
}
