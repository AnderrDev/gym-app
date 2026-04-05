import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/routine.dart';
import '../entities/routine_day.dart';
import '../entities/set_log.dart';
import '../entities/exercise.dart';
import '../entities/workout_session.dart';
import '../entities/coaching_analysis.dart';
import '../entities/exercise_history_session.dart';
import '../entities/routine_history_session.dart';
import '../entities/weekly_insights.dart';

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

  /// Saves (creates or updates) a routine
  Future<Either<Failure, void>> saveRoutine(Routine routine);

  /// Deletes a routine and all its dependencies
  Future<Either<Failure, void>> deleteRoutine(String routineId);

  /// Saves (creates or updates) a routine day
  Future<Either<Failure, void>> saveRoutineDay(RoutineDay day);

  /// Deletes a routine day and its exercise mappings
  Future<Either<Failure, void>> deleteRoutineDay(String dayId);

  /// Toggles an exercise in a specific day
  Future<Either<Failure, void>> toggleExerciseInDay(
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

  /// Actualiza el objetivo de un ejercicio (peso/reps) en una rutina específica
  Future<Either<Failure, void>> updateExerciseTarget(
    String routineDayId,
    String exerciseId,
    double targetWeight,
    int targetReps,
  );

  /// Busca la sesión activa (sin completar) del usuario para reanudar al abrir app
  Future<Either<Failure, WorkoutSession?>> getActiveSessionForUser(
    String userId,
  );

  /// Obtiene el nombre del día de rutina por id (usado para banner/reanudación)
  Future<Either<Failure, String?>> getRoutineDayNameById(String routineDayId);

  // Gestión de Rutinas
  /// Syncs pending offline data to Supabase
  Future<Either<Failure, void>> syncPendingData();

  /// Gets all routines (public + private)
  Future<Either<Failure, List<Routine>>> getAllRoutines();

  /// Gets a specific routine by ID
  Future<Either<Failure, Routine>> getRoutineById(String routineId);
}
