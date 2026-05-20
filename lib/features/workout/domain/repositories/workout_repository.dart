import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/routine.dart';
import '../entities/routine_day.dart';
import '../entities/set_log.dart';
import '../entities/exercise.dart';
import '../entities/workout_session.dart';
import '../entities/coaching_analysis.dart';
import '../entities/exercise_catalog_item.dart';
import '../entities/exercise_detail.dart';
import '../entities/exercise_history_session.dart';
import '../entities/routine_history_session.dart';
import '../entities/weekly_insights.dart';

/// Payload simple para inserts masivos de ejercicios en un día.
class AddExerciseToDayPayload {
  const AddExerciseToDayPayload({
    required this.exerciseId,
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetWeight = 0,
    this.restSeconds = 90,
  });

  final String exerciseId;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final int restSeconds;
}

abstract class WorkoutRepository {
  /// Fetches the routines assigned to a specific user
  Future<Either<Failure, List<Routine>>> getAssignedRoutines(String userId);

  /// Gets all days (with exercises) for a routine
  Future<Either<Failure, List<RoutineDay>>> getRoutineDays(String routineId);

  /// Gets exercises configured for a specific routine day
  Future<Either<Failure, List<Exercise>>> getExercisesForDay(
    String routineDayId,
  );

  /// Busca una sesión existente para un usuario/día/fecha (no crea una nueva)
  Future<Either<Failure, WorkoutSession?>> getExistingSession(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  );

  /// Gets all workout sessions for a given week (offline-first)
  Future<Either<Failure, List<WorkoutSession>>> getWeekSessions(
    String userId,
    DateTime weekStart,
    DateTime weekEnd,
  );

  /// Starts (or resumes) a workout session for a specific day and date
  Future<Either<Failure, WorkoutSession>> startWorkoutForDay(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  );

  /// Saves a single set log
  Future<Either<Failure, void>> saveSetLog(SetLog setLog);

  /// Borra una serie ya guardada (toggle desmarcar).
  Future<Either<Failure, void>> deleteSetLog({
    required String sessionId,
    required String exerciseId,
    required int setIndex,
  });

  /// Gets previous performance for an exercise
  Future<Either<Failure, SetLog?>> getLastExercisePerformance(
    String exerciseId,
  );

  /// Gets previous performance for multiple exercises in one request
  Future<Either<Failure, Map<String, SetLog?>>> getLastExercisePerformances(
    List<String> exerciseIds,
  );

  /// Gets all set logs for a session (history view)
  Future<Either<Failure, List<SetLog>>> getSessionSetLogs(String sessionId);

  /// Gets set logs grouped by session id in a single request
  Future<Either<Failure, Map<String, List<SetLog>>>> getSetLogsForSessions(
    List<String> sessionIds,
  );

  /// Saves (creates or updates) a routine. Devuelve la entidad persistida
  /// con id real (útil cuando se inserta una rutina nueva).
  Future<Either<Failure, Routine>> saveRoutine(Routine routine);

  /// Deletes a routine and all its dependencies
  Future<Either<Failure, void>> deleteRoutine(String routineId);

  /// Crea una copia privada de una rutina visible (propia o pública). Devuelve
  /// el id de la nueva rutina, que queda con `creator_id` = usuario actual e
  /// `is_public = false`. Conserva días, ejercicios, targets y orden.
  Future<Either<Failure, String>> forkRoutine(
    String sourceRoutineId, {
    String? newName,
  });

  /// Saves (creates or updates) a routine day. Devuelve la entidad persistida
  /// con id real.
  Future<Either<Failure, RoutineDay>> saveRoutineDay(RoutineDay day);

  /// Deletes a routine day and its exercise mappings
  Future<Either<Failure, void>> deleteRoutineDay(String dayId);

  /// Añade un único ejercicio al día con los targets indicados.
  Future<Either<Failure, void>> addExerciseToDay(
    String dayId,
    String exerciseId, {
    required int targetSets,
    required int targetReps,
    required double targetWeight,
    int restSeconds = 90,
  });

  /// Añade un lote de ejercicios al día (insert bulk con orders consecutivos).
  Future<Either<Failure, void>> addExercisesToDay(
    String dayId,
    List<AddExerciseToDayPayload> items,
  );

  /// Quita un ejercicio del día.
  Future<Either<Failure, void>> removeExerciseFromDay(
    String dayId,
    String exerciseId,
  );

  /// Reorders exercises in a specific day
  Future<Either<Failure, void>> reorderExercisesInDay(
    String dayId,
    List<String> exerciseIds,
  );

  /// Assigns a routine to a user
  Future<Either<Failure, void>> assignRoutineToUser(
    String userId,
    String routineId,
  );

  /// Gets recent completed sessions for a specific routine day
  Future<Either<Failure, List<WorkoutSession>>> getRecentSessionsForDay(
    String userId,
    String routineDayId,
    DateTime beforeDate, {
    int limit = 3,
  });
  Future<Either<Failure, void>> finishWorkoutSession(
    String sessionId, {
    List<CoachingAnalysis>? coachingAnalysis,
  });

  /// Gets the historical logs for an exercise
  Future<Either<Failure, List<ExerciseHistorySession>>> getExerciseLogsHistory(
    String userId,
    String exerciseId,
  );

  /// Gets unified stats for a specific routine (volume per session)
  Future<Either<Failure, List<RoutineHistorySession>>> getRoutineStats(
    String userId,
    String routineId,
  );

  /// Gets weekly insights (adherence, volume trend, PRs) for a routine
  Future<Either<Failure, WeeklyInsights>> getWeeklyInsights({
    required String routineId,
    required DateTime weekStart,
  });

  /// Actualiza el objetivo de un ejercicio (peso/reps + opcional sets/rest)
  /// en una rutina específica.
  Future<Either<Failure, void>> updateExerciseTarget(
    String routineDayId,
    String exerciseId,
    double targetWeight,
    int targetReps, {
    int? targetSets,
    int? restSeconds,
  });

  /// Busca la sesión activa (sin completar) del usuario para reanudar al abrir app
  Future<Either<Failure, WorkoutSession?>> getActiveSessionForUser(
    String userId,
  );

  /// Observa una sesión local en tiempo real. Útil para que la UI reaccione
  /// a actualizaciones tras un drain (coaching aplicado, completedAt
  /// persistido). Devuelve `Stream.empty()` cuando la persistencia local no
  /// está disponible (web sin cache).
  Stream<WorkoutSession?> watchSession(String id);

  /// Obtiene el nombre del día de rutina por id (usado para banner/reanudación)
  Future<Either<Failure, String?>> getRoutineDayNameById(String routineDayId);

  // Gestión de Rutinas
  /// Gets all routines (public + private)
  Future<Either<Failure, List<Routine>>> getAllRoutines();

  /// Gets a specific routine by ID
  Future<Either<Failure, Routine>> getRoutineById(String routineId);

  /// Catálogo global de ejercicios (tabla `exercises`).
  Future<Either<Failure, List<ExerciseCatalogItem>>> getExercisesCatalog({
    String? muscleGroup,
    String? search,
    int limit = 200,
  });

  /// Detalle enriquecido de un ejercicio: media + instrucciones. `NotFoundFailure`
  /// si no existe.
  Future<Either<Failure, ExerciseDetail>> getExerciseDetail(String exerciseId);
}
