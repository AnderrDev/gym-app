import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gym_flutter/features/workout/data/datasources/exercise_catalog_remote_data_source.dart';
import 'package:gym_flutter/features/workout/data/datasources/routine_management_remote_data_source.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_remote_data_source_contract.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_session_remote_data_source.dart';
import 'package:gym_flutter/features/workout/data/models/exercise_model.dart';
import 'package:gym_flutter/features/workout/data/models/routine_day_model.dart';
import 'package:gym_flutter/features/workout/data/models/routine_model.dart';
import 'package:gym_flutter/features/workout/data/models/set_log_model.dart';
import 'package:gym_flutter/features/workout/data/models/workout_session_model.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_catalog_item.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';

export 'package:gym_flutter/core/error/exceptions.dart'
    show WorkoutFunctionException;
export 'package:gym_flutter/features/workout/data/datasources/add_exercise_to_day_item.dart'
    show AddExerciseToDayItem;
export 'package:gym_flutter/features/workout/data/datasources/workout_remote_data_source_contract.dart'
    show WorkoutRemoteDataSource;

/// Fachada de `WorkoutRemoteDataSource`. Delega en 3 colaboradores
/// especializados (sesiones, gestión de rutinas, catálogo) para mantener cada
/// archivo bajo control de complejidad.
class WorkoutRemoteDataSourceImpl implements WorkoutRemoteDataSource {
  WorkoutRemoteDataSourceImpl({required SupabaseClient client})
      : _sessions = WorkoutSessionRemoteDataSource(client: client),
        _routines = RoutineManagementRemoteDataSource(client: client),
        _catalog = ExerciseCatalogRemoteDataSource(client: client);

  WorkoutRemoteDataSourceImpl.fromParts({
    required WorkoutSessionRemoteDataSource sessions,
    required RoutineManagementRemoteDataSource routines,
    required ExerciseCatalogRemoteDataSource catalog,
  })  : _sessions = sessions,
        _routines = routines,
        _catalog = catalog;

  final WorkoutSessionRemoteDataSource _sessions;
  final RoutineManagementRemoteDataSource _routines;
  final ExerciseCatalogRemoteDataSource _catalog;

  // ─── Routine management ────────────────────────────────────────────────
  @override
  Future<List<RoutineModel>> getAssignedRoutines(String userId) =>
      _routines.getAssignedRoutines(userId);

  @override
  Future<List<RoutineDayModel>> getRoutineDays(String routineId) =>
      _routines.getRoutineDays(routineId);

  @override
  Future<List<ExerciseModel>> getExercisesForDay(String routineDayId) =>
      _routines.getExercisesForDay(routineDayId);

  @override
  Future<String?> getRoutineDayNameById(String routineDayId) =>
      _routines.getRoutineDayNameById(routineDayId);

  @override
  Future<void> assignRoutineToUser(String userId, String routineId) =>
      _routines.assignRoutineToUser(userId, routineId);

  @override
  Future<RoutineModel> saveRoutine(RoutineModel routine) =>
      _routines.saveRoutine(routine);

  @override
  Future<RoutineModel> getRoutineById(String routineId) =>
      _routines.getRoutineById(routineId);

  @override
  Future<void> deleteRoutine(String routineId) =>
      _routines.deleteRoutine(routineId);

  @override
  Future<RoutineDayModel> saveRoutineDay(RoutineDayModel day) =>
      _routines.saveRoutineDay(day);

  @override
  Future<void> deleteRoutineDay(String dayId) =>
      _routines.deleteRoutineDay(dayId);

  @override
  Future<void> addExerciseToDay(
    String dayId,
    String exerciseId, {
    required int targetSets,
    required int targetReps,
    required double targetWeight,
    int restSeconds = 90,
  }) =>
      _routines.addExerciseToDay(
        dayId,
        exerciseId,
        targetSets: targetSets,
        targetReps: targetReps,
        targetWeight: targetWeight,
        restSeconds: restSeconds,
      );

  @override
  Future<void> addExercisesToDay(
    String dayId,
    List<AddExerciseToDayItem> items,
  ) =>
      _routines.addExercisesToDay(dayId, items);

  @override
  Future<void> removeExerciseFromDay(String dayId, String exerciseId) =>
      _routines.removeExerciseFromDay(dayId, exerciseId);

  @override
  Future<void> reorderExercisesInDay(String dayId, List<String> exerciseIds) =>
      _routines.reorderExercisesInDay(dayId, exerciseIds);

  @override
  Future<void> updateExerciseTarget(
    String routineDayId,
    String exerciseId,
    double targetWeight,
    int targetReps, {
    int? targetSets,
    int? restSeconds,
  }) =>
      _routines.updateExerciseTarget(
        routineDayId,
        exerciseId,
        targetWeight,
        targetReps,
        targetSets: targetSets,
        restSeconds: restSeconds,
      );

  @override
  Future<List<RoutineModel>> getAllRoutines({int limit = 100, int offset = 0}) =>
      _routines.getAllRoutines(limit: limit, offset: offset);

  // ─── Sessions / set_logs / edge functions ─────────────────────────────
  @override
  Future<List<WorkoutSessionModel>> getWeekSessions(
    String userId,
    DateTime weekStart,
    DateTime weekEnd,
  ) =>
      _sessions.getWeekSessions(userId, weekStart, weekEnd);

  @override
  Future<WorkoutSessionModel> startWorkoutForDay(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  ) =>
      _sessions.startWorkoutForDay(userId, routineDayId, sessionDate);

  @override
  Future<WorkoutSessionModel?> getExistingSession(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  ) =>
      _sessions.getExistingSession(userId, routineDayId, sessionDate);

  @override
  Future<void> saveSetLog(SetLogModel setLog) => _sessions.saveSetLog(setLog);

  @override
  Future<void> deleteSetLog({
    required String sessionId,
    required String exerciseId,
    required int setIndex,
  }) =>
      _sessions.deleteSetLog(
        sessionId: sessionId,
        exerciseId: exerciseId,
        setIndex: setIndex,
      );

  @override
  Future<WorkoutSessionModel?> getActiveSessionForUser(String userId) =>
      _sessions.getActiveSessionForUser(userId);

  @override
  Future<List<SetLogModel>> getSessionSetLogs(String sessionId) =>
      _sessions.getSessionSetLogs(sessionId);

  @override
  Future<Map<String, List<SetLogModel>>> getSetLogsForSessions(
    List<String> sessionIds,
  ) =>
      _sessions.getSetLogsForSessions(sessionIds);

  @override
  Future<List<WorkoutSessionModel>> getRecentSessionsForDay(
    String userId,
    String routineDayId,
    DateTime beforeDate, {
    int limit = 3,
  }) =>
      _sessions.getRecentSessionsForDay(
        userId,
        routineDayId,
        beforeDate,
        limit: limit,
      );

  @override
  Future<void> finishWorkoutSession(
    String sessionId, {
    List<CoachingAnalysis>? coachingAnalysis,
  }) =>
      _sessions.finishWorkoutSession(
        sessionId,
        coachingAnalysis: coachingAnalysis,
      );

  @override
  Future<WeeklyInsights> getWeeklyInsights({
    required String routineId,
    required DateTime weekStart,
  }) =>
      _sessions.getWeeklyInsights(routineId: routineId, weekStart: weekStart);

  @override
  Future<List<Map<String, dynamic>>> getExerciseLogsHistory(
    String userId,
    String exerciseId,
  ) =>
      _sessions.getExerciseLogsHistory(userId, exerciseId);

  @override
  Future<List<Map<String, dynamic>>> getRoutineStats(
    String userId,
    String routineId,
  ) =>
      _sessions.getRoutineStats(userId, routineId);

  // ─── Exercise catalog + performances ──────────────────────────────────
  @override
  Future<SetLogModel?> getLastExercisePerformance(String exerciseId) =>
      _catalog.getLastExercisePerformance(exerciseId);

  @override
  Future<Map<String, SetLogModel?>> getLastExercisePerformances(
    List<String> exerciseIds,
  ) =>
      _catalog.getLastExercisePerformances(exerciseIds);

  @override
  Future<List<ExerciseCatalogItem>> getExercisesCatalog({
    String? muscleGroup,
    String? search,
    int limit = 200,
  }) =>
      _catalog.getExercisesCatalog(
        muscleGroup: muscleGroup,
        search: search,
        limit: limit,
      );
}
