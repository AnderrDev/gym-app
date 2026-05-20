import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';

/// Args fuertemente tipados para `state.extra` de las rutas. Sustituyen los
/// `Map<String, dynamic>` que se castaban en el router (frágil y sin
/// autocompletado). Cualquier ruta que reciba parámetros debe declarar su
/// clase `*Args` aquí y consumirla en `app_router.dart` + `router_helpers`.

/// Argumentos para abrir un día de rutina (prestart / sesión activa).
class RoutineDayArgs {
  const RoutineDayArgs({
    required this.routineDay,
    required this.userId,
    required this.sessionDate,
  });

  final RoutineDay routineDay;
  final String userId;
  final DateTime sessionDate;
}

/// Argumentos para abrir el editor de un día específico.
class DayEditorArgs {
  const DayEditorArgs({required this.day, required this.routineId});

  final RoutineDay day;
  final String routineId;
}

/// Argumentos para la pantalla de estadísticas de una rutina.
///
/// Deep-linkable: serializa a query params para que un refresh del browser
/// reconstruya el estado sin pasar por `_invalidArgs`. Esto es valioso
/// porque el usuario podría compartir el link al historial de una rutina
/// o quedarse con la pestaña abierta y refrescar.
class RoutineStatsArgs {
  const RoutineStatsArgs({
    required this.userId,
    required this.routineId,
    required this.routineName,
  });

  final String userId;
  final String routineId;
  final String routineName;

  Map<String, String> toQueryParams() => {
        'userId': userId,
        'routineId': routineId,
        'routineName': routineName,
      };

  /// Reconstruye args desde `state.uri.queryParameters`. Devuelve null si
  /// falta alguno de los 3 campos requeridos.
  static RoutineStatsArgs? tryFromQuery(Map<String, String> q) {
    final userId = q['userId'];
    final routineId = q['routineId'];
    final routineName = q['routineName'];
    if (userId == null || routineId == null || routineName == null) {
      return null;
    }
    return RoutineStatsArgs(
      userId: userId,
      routineId: routineId,
      routineName: routineName,
    );
  }
}

/// Argumentos para la pantalla de progreso de un ejercicio. Deep-linkable
/// — ver doc de [RoutineStatsArgs] para la razón.
class ExerciseProgressArgs {
  const ExerciseProgressArgs({
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
  });

  final String userId;
  final String exerciseId;
  final String exerciseName;

  Map<String, String> toQueryParams() => {
        'userId': userId,
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
      };

  static ExerciseProgressArgs? tryFromQuery(Map<String, String> q) {
    final userId = q['userId'];
    final exerciseId = q['exerciseId'];
    final exerciseName = q['exerciseName'];
    if (userId == null || exerciseId == null || exerciseName == null) {
      return null;
    }
    return ExerciseProgressArgs(
      userId: userId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
    );
  }
}
