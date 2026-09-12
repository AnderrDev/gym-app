import 'package:equatable/equatable.dart';

import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';

enum ActiveWorkoutStatus {
  /// No hay sesión activa todavía (la pantalla está en prestart).
  idle,

  /// Disparamos `StartActiveWorkout` y esperamos respuesta del backend.
  starting,

  /// Sesión iniciada (o reanudada). El usuario puede registrar sets.
  running,

  /// Disparamos `FinishActiveWorkout` y esperamos cierre.
  finishing,

  /// Sesión cerrada con éxito. La página debería pop-ear.
  finished,

  /// Falla en cualquiera de los pasos anteriores.
  failure,
}

class ActiveWorkoutState extends Equatable {
  const ActiveWorkoutState({
    this.status = ActiveWorkoutStatus.idle,
    this.session,
    this.exercises = const [],
    this.setLogs = const [],
    this.lastPerformances = const {},
    this.recentSessions = const [],
    this.recentSessionsLogs = const {},
    this.errorMessage,
    this.actionError,
    this.actionErrorNonce = 0,
  });

  final ActiveWorkoutStatus status;
  final WorkoutSession? session;
  final List<Exercise> exercises;
  final List<SetLog> setLogs;
  final Map<String, SetLog?> lastPerformances;
  final List<WorkoutSession> recentSessions;
  final Map<String, List<SetLog>> recentSessionsLogs;
  final String? errorMessage;

  /// Error de una acción puntual (guardar/desmarcar serie, cambiar objetivo)
  /// que NO tumba la sesión: la página lo muestra como snack y sigue.
  final String? actionError;

  /// Incrementa con cada `actionError` para que dos fallos iguales seguidos
  /// sigan disparando el listener de la página.
  final int actionErrorNonce;

  bool get isRunning => status == ActiveWorkoutStatus.running;
  bool get isStarting => status == ActiveWorkoutStatus.starting;
  bool get isFinishing => status == ActiveWorkoutStatus.finishing;

  ActiveWorkoutState copyWith({
    ActiveWorkoutStatus? status,
    WorkoutSession? session,
    bool clearSession = false,
    List<Exercise>? exercises,
    List<SetLog>? setLogs,
    Map<String, SetLog?>? lastPerformances,
    List<WorkoutSession>? recentSessions,
    Map<String, List<SetLog>>? recentSessionsLogs,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionError,
  }) {
    return ActiveWorkoutState(
      actionError: actionError,
      actionErrorNonce: actionError == null
          ? actionErrorNonce
          : actionErrorNonce + 1,
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      exercises: exercises ?? this.exercises,
      setLogs: setLogs ?? this.setLogs,
      lastPerformances: lastPerformances ?? this.lastPerformances,
      recentSessions: recentSessions ?? this.recentSessions,
      recentSessionsLogs: recentSessionsLogs ?? this.recentSessionsLogs,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    session,
    exercises,
    setLogs,
    lastPerformances,
    recentSessions,
    recentSessionsLogs,
    errorMessage,
    actionError,
    actionErrorNonce,
  ];
}
