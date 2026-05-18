import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';

/// Contrato de la caché local read-only que sirve el patrón SWR del
/// repositorio. Devuelve entidades de dominio (no models) para que el
/// repositorio no tenga que mapear de nuevo en el camino feliz offline.
abstract class WorkoutLocalDataSource {
  /// Días de una rutina (sin `exercises` populated — cargan a través de
  /// [`getExercisesForDay`]).
  Future<List<RoutineDay>> getRoutineDays(String routineId);

  /// Ejercicios del día con su metadata canónica (nombre, grupo muscular).
  Future<List<Exercise>> getExercisesForDay(String routineDayId);

  /// Último `SetLog` cacheado por ejercicio. La key del map es el
  /// `exerciseId`; el valor es `null` si no hay cache para ese ejercicio.
  Future<Map<String, SetLog?>> getLastPerformancesForExercises(
    String userId,
    List<String> exerciseIds,
  );

  Future<void> cacheRoutineDays(String routineId, List<RoutineDay> days);

  Future<void> cacheExercisesForDay(
    String routineDayId,
    List<Exercise> exercises,
  );

  /// Persiste sólo las entradas con valor non-null. Las claves con `null` se
  /// ignoran (no hay nada que cachear).
  Future<void> cacheLastPerformances(
    String userId,
    Map<String, SetLog?> performances,
  );
}
