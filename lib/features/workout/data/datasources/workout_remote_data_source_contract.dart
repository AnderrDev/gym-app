import 'package:gym_flutter/features/workout/data/datasources/add_exercise_to_day_item.dart';
import 'package:gym_flutter/features/workout/data/models/exercise_model.dart';
import 'package:gym_flutter/features/workout/data/models/routine_day_model.dart';
import 'package:gym_flutter/features/workout/data/models/routine_model.dart';
import 'package:gym_flutter/features/workout/data/models/set_log_model.dart';
import 'package:gym_flutter/features/workout/data/models/workout_session_model.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_catalog_item.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_detail.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';

abstract class WorkoutRemoteDataSource {
  Future<List<RoutineModel>> getAssignedRoutines(String userId);
  Future<List<RoutineDayModel>> getRoutineDays(String routineId);
  Future<List<ExerciseModel>> getExercisesForDay(String routineDayId);
  Future<List<WorkoutSessionModel>> getWeekSessions(
    String userId,
    DateTime weekStart,
    DateTime weekEnd,
  );
  Future<WorkoutSessionModel> startWorkoutForDay(
    String userId,
    String routineDayId,
    DateTime sessionDate, {
    String? id,
  });
  Future<WorkoutSessionModel?> getExistingSession(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  );
  Future<void> saveSetLog(SetLogModel setLog);
  Future<void> deleteSetLog({
    required String sessionId,
    required String exerciseId,
    required int setIndex,
  });
  Future<SetLogModel?> getLastExercisePerformance(String exerciseId);
  Future<Map<String, SetLogModel?>> getLastExercisePerformances(
    List<String> exerciseIds,
  );
  Future<void> assignRoutineToUser(String userId, String routineId);
  Future<List<SetLogModel>> getSessionSetLogs(String sessionId);
  Future<Map<String, List<SetLogModel>>> getSetLogsForSessions(
    List<String> sessionIds,
  );
  Future<List<WorkoutSessionModel>> getRecentSessionsForDay(
    String userId,
    String routineDayId,
    DateTime beforeDate, {
    int limit = 3,
  });
  Future<void> finishWorkoutSession(
    String sessionId, {
    List<CoachingAnalysis>? coachingAnalysis,
  });
  Future<WeeklyInsights> getWeeklyInsights({
    required String routineId,
    required DateTime weekStart,
  });
  Future<List<Map<String, dynamic>>> getExerciseLogsHistory(
    String userId,
    String exerciseId,
  );
  Future<List<Map<String, dynamic>>> getRoutineStats(
    String userId,
    String routineId,
  );

  /// Busca cualquier sesión sin completar para el usuario (reanudación).
  Future<WorkoutSessionModel?> getActiveSessionForUser(String userId);
  Future<String?> getRoutineDayNameById(String routineDayId);

  Future<RoutineModel> saveRoutine(RoutineModel routine);
  Future<void> deleteRoutine(String routineId);
  Future<String> forkRoutine(String sourceRoutineId, {String? newName});
  Future<RoutineDayModel> saveRoutineDay(RoutineDayModel day);
  Future<void> deleteRoutineDay(String dayId);
  Future<void> addExerciseToDay(
    String dayId,
    String exerciseId, {
    required int targetSets,
    required int targetReps,
    required double targetWeight,
    int restSeconds = 90,
  });
  Future<void> addExercisesToDay(
    String dayId,
    List<AddExerciseToDayItem> items,
  );
  Future<void> removeExerciseFromDay(String dayId, String exerciseId);
  Future<void> reorderExercisesInDay(String dayId, List<String> exerciseIds);
  Future<void> updateExerciseTarget(
    String routineDayId,
    String exerciseId,
    double targetWeight,
    int targetReps, {
    int? targetSets,
    int? restSeconds,
  });
  Future<List<RoutineModel>> getAllRoutines({int limit, int offset});
  Future<RoutineModel> getRoutineById(String routineId);
  Future<List<ExerciseCatalogItem>> getExercisesCatalog({
    String? muscleGroup,
    String? search,
    int limit = 200,
  });
  Future<ExerciseDetail> getExerciseDetail(String exerciseId);
}
