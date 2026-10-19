import 'package:equatable/equatable.dart';

import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';

enum RoutineDayStatus { initial, loading, ready, failure }

/// Estado de la **pantalla previa** al inicio de un día de rutina.
///
/// Si `existingSession` es no-nulo el flujo debe transferirse al
/// `ActiveWorkoutBloc` (la sesión ya está abierta).
class RoutineDayState extends Equatable {
  const RoutineDayState({
    this.status = RoutineDayStatus.initial,
    this.userId,
    this.routineDayId,
    this.sessionDate,
    this.exercises = const [],
    this.existingSession,
    this.recentSessions = const [],
    this.recentSessionsLogs = const {},
    this.lastPerformances = const {},
    this.hasAnotherActiveSession = false,
    this.anotherActiveSessionDayName,
    this.errorMessage,
  });

  final RoutineDayStatus status;
  final String? userId;
  final String? routineDayId;
  final DateTime? sessionDate;
  final List<Exercise> exercises;
  final WorkoutSession? existingSession;
  final List<WorkoutSession> recentSessions;
  final Map<String, List<SetLog>> recentSessionsLogs;
  final Map<String, SetLog?> lastPerformances;
  final bool hasAnotherActiveSession;
  final String? anotherActiveSessionDayName;
  final String? errorMessage;

  RoutineDayState copyWith({
    RoutineDayStatus? status,
    String? userId,
    String? routineDayId,
    DateTime? sessionDate,
    List<Exercise>? exercises,
    WorkoutSession? existingSession,
    bool clearExistingSession = false,
    List<WorkoutSession>? recentSessions,
    Map<String, List<SetLog>>? recentSessionsLogs,
    Map<String, SetLog?>? lastPerformances,
    bool? hasAnotherActiveSession,
    String? anotherActiveSessionDayName,
    bool clearAnotherActiveSessionDayName = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return RoutineDayState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      routineDayId: routineDayId ?? this.routineDayId,
      sessionDate: sessionDate ?? this.sessionDate,
      exercises: exercises ?? this.exercises,
      existingSession: clearExistingSession
          ? null
          : (existingSession ?? this.existingSession),
      recentSessions: recentSessions ?? this.recentSessions,
      recentSessionsLogs: recentSessionsLogs ?? this.recentSessionsLogs,
      lastPerformances: lastPerformances ?? this.lastPerformances,
      hasAnotherActiveSession:
          hasAnotherActiveSession ?? this.hasAnotherActiveSession,
      anotherActiveSessionDayName: clearAnotherActiveSessionDayName
          ? null
          : (anotherActiveSessionDayName ?? this.anotherActiveSessionDayName),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    userId,
    routineDayId,
    sessionDate,
    exercises,
    existingSession,
    recentSessions,
    recentSessionsLogs,
    lastPerformances,
    hasAnotherActiveSession,
    anotherActiveSessionDayName,
    errorMessage,
  ];
}
