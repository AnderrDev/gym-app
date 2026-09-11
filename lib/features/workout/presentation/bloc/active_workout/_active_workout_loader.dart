import 'package:fpdart/fpdart.dart';

import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

/// Datos cargados al iniciar una sesión activa. Agrupa el resultado de los
/// fetches paralelos (ejercicios, historial, set logs ya guardados) y el
/// best-effort de `lastPerformances`.
class ActiveWorkoutCtx {
  const ActiveWorkoutCtx({
    required this.exercises,
    required this.setLogs,
    required this.recentSessions,
    required this.recentSessionsLogs,
    required this.lastPerformances,
  });

  final List<Exercise> exercises;
  final List<SetLog> setLogs;
  final List<WorkoutSession> recentSessions;
  final Map<String, List<SetLog>> recentSessionsLogs;
  final Map<String, SetLog?> lastPerformances;
}

/// Carga en paralelo el contexto necesario para arrancar/reanudar una sesión.
/// Si alguno de los fetches falla, devuelve valores vacíos en lugar de
/// propagar — la sesión sigue siendo utilizable sin historial.
Future<ActiveWorkoutCtx> loadActiveWorkoutContext(
  WorkoutRepository repository,
  String userId,
  WorkoutSession session,
) async {
  final results = await Future.wait([
    repository.getExercisesForDay(session.routineDayId),
    repository.getRecentSessionsForDay(
      userId,
      session.routineDayId,
      session.sessionDate,
      limit: 3,
    ),
    repository.getSessionSetLogs(session.id),
  ]);

  final exercises = (results[0] as Either<Failure, List<Exercise>>).getOrElse(
    (_) => const [],
  );
  final recentSessions = (results[1] as Either<Failure, List<WorkoutSession>>)
      .getOrElse((_) => const []);
  final setLogs = (results[2] as Either<Failure, List<SetLog>>).getOrElse(
    (_) => const [],
  );

  final recentLogs = (await repository.getSetLogsForSessions(
    recentSessions.map((s) => s.id).toList(),
  )).getOrElse((_) => <String, List<SetLog>>{});

  return ActiveWorkoutCtx(
    exercises: exercises,
    setLogs: setLogs,
    recentSessions: recentSessions,
    recentSessionsLogs: recentLogs,
    lastPerformances: await fetchLastPerformances(repository, exercises),
  );
}

/// Mapa exerciseId → último SetLog (o `null` si nunca se entrenó). Garantiza
/// que todos los ids aparezcan en el mapa para simplificar lookups en UI.
Future<Map<String, SetLog?>> fetchLastPerformances(
  WorkoutRepository repository,
  List<Exercise> exercises,
) async {
  if (exercises.isEmpty) return const {};
  final ids = exercises.map((e) => e.id).toList();
  final result = await repository.getLastExercisePerformances(ids);
  final perf = Map<String, SetLog?>.from(
    result.getOrElse((_) => const <String, SetLog?>{}),
  );
  for (final id in ids) {
    perf.putIfAbsent(id, () => null);
  }
  return perf;
}
