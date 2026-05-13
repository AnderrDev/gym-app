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
class RoutineStatsArgs {
  const RoutineStatsArgs({
    required this.userId,
    required this.routineId,
    required this.routineName,
  });

  final String userId;
  final String routineId;
  final String routineName;
}

/// Argumentos para la pantalla de progreso de un ejercicio.
class ExerciseProgressArgs {
  const ExerciseProgressArgs({
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
  });

  final String userId;
  final String exerciseId;
  final String exerciseName;
}
