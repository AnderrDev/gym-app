import 'package:equatable/equatable.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/routine_day.dart';
import '../../domain/entities/set_log.dart';
import '../../domain/entities/workout_session.dart';

sealed class WorkoutState extends Equatable {
  const WorkoutState();
  @override List<Object?> get props => [];
}

final class WorkoutInitial extends WorkoutState {}

final class WorkoutLoading extends WorkoutState {}

final class WorkoutError extends WorkoutState {
  final String message;
  const WorkoutError(this.message);
  @override List<Object?> get props => [message];
}

// Dashboard: lista de rutinas asignadas
final class RoutinesLoaded extends WorkoutState {
  final List<Routine> routines;
  const RoutinesLoaded(this.routines);
  @override List<Object?> get props => [routines];
}

// Dashboard: plan semanal con estado de completado por día
final class WeeklyPlanLoaded extends WorkoutState {
  final List<RoutineDay> days;       // Los 7 días con sus ejercicios y estado
  final DateTime weekStart;
  const WeeklyPlanLoaded(this.days, this.weekStart);
  @override List<Object?> get props => [days, weekStart];
}

// Info del día cargada: ejercicios + sesión existente (puede ser null)
// Usado para mostrar el día antes de iniciar / ver historial
final class DayInfoLoaded extends WorkoutState {
  final List<Exercise> exercises;
  final WorkoutSession? existingSession; // hoy
  final List<WorkoutSession> recentSessions; // sesiones anteriores completadas
  final Map<String, List<SetLog>> recentSessionsLogs; // sessionId -> logs
  final String userId;
  final String routineDayId;
  final DateTime sessionDate;
  final Map<String, SetLog?> lastPerformances;
  
  const DayInfoLoaded({
    required this.exercises,
    required this.userId,
    required this.routineDayId,
    required this.sessionDate,
    this.existingSession,
    this.recentSessions = const [],
    this.recentSessionsLogs = const {},
    this.lastPerformances = const {},
  });
  
  @override List<Object?> get props => [
    exercises, existingSession, recentSessions, recentSessionsLogs, 
    userId, routineDayId, sessionDate, lastPerformances
  ];
}

// Sesión activa iniciada para un día
final class DayWorkoutStarted extends WorkoutState {
  final WorkoutSession session;
  final List<Exercise> exercises;
  final List<SetLog> setLogs;
  final Map<String, SetLog?> lastPerformances;
  final List<WorkoutSession> recentSessions; // Historial para tendencias
  final Map<String, List<SetLog>> recentSessionsLogs; // Logs agrupados
  
  const DayWorkoutStarted(this.session, this.exercises, {
    this.setLogs = const [], 
    this.lastPerformances = const {}, 
    this.recentSessions = const [], 
    this.recentSessionsLogs = const {},
  });
  
  @override List<Object?> get props => [
    session, exercises, setLogs, lastPerformances, recentSessions, recentSessionsLogs
  ];
}

// Historial de una sesión completada (solo lectura)
final class SessionHistoryLoaded extends WorkoutState {
  final WorkoutSession session;
  final List<SetLog> setLogs;
  final List<Exercise> exercises;
  final Map<String, SetLog?> lastPerformances; // RÉCORD DE REFERENCIA
  const SessionHistoryLoaded({
    required this.session,
    required this.setLogs,
    required this.exercises,
    this.lastPerformances = const {},
  });
  @override List<Object?> get props => [session, setLogs, exercises, lastPerformances];
}

// Guardando serie
final class SavingSetLog extends WorkoutState {}

// Serie guardada exitosamente
final class SetLogSuccess extends WorkoutState {}

// Sesión finalizada
final class WorkoutFinishedSuccess extends WorkoutState {}

// Rendimiento anterior cargado
final class ExercisePerformanceLoaded extends WorkoutState {
  final SetLog? lastSetLog;
  const ExercisePerformanceLoaded(this.lastSetLog);
  @override List<Object?> get props => [lastSetLog];
}

final class ManagementSuccess extends WorkoutState {
  final String message;
  const ManagementSuccess(this.message);
  @override List<Object?> get props => [message];
}
