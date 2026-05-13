import 'package:fpdart/fpdart.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../datasources/workout_remote_data_source.dart';
import '../models/set_log_model.dart';
import '../models/routine_model.dart';
import '../models/routine_day_model.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/routine_day.dart';
import '../../domain/entities/set_log.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/coaching_analysis.dart';
import '../../domain/entities/exercise_catalog_item.dart';
import '../../domain/entities/exercise_history_session.dart';
import '../../domain/entities/routine_history_session.dart';
import '../../domain/entities/weekly_insights.dart';
import '../../domain/repositories/workout_repository.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutRemoteDataSource remoteDataSource;

  WorkoutRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Routine>>> getAssignedRoutines(String userId) =>
      guard(() => remoteDataSource.getAssignedRoutines(userId));

  @override
  Future<Either<Failure, List<RoutineDay>>> getRoutineDays(String routineId) =>
      guard(() => remoteDataSource.getRoutineDays(routineId));

  @override
  Future<Either<Failure, List<Exercise>>> getExercisesForDay(
    String routineDayId,
  ) => guard(() => remoteDataSource.getExercisesForDay(routineDayId));

  @override
  Future<Either<Failure, List<WorkoutSession>>> getWeekSessions(
    String userId,
    DateTime weekStart,
    DateTime weekEnd,
  ) => guard(
    () => remoteDataSource.getWeekSessions(userId, weekStart, weekEnd),
  );

  @override
  Future<Either<Failure, WorkoutSession?>> getExistingSession(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  ) => guard(
    () => remoteDataSource.getExistingSession(userId, routineDayId, sessionDate),
  );

  @override
  Future<Either<Failure, WorkoutSession>> startWorkoutForDay(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  ) => guard(
    () =>
        remoteDataSource.startWorkoutForDay(userId, routineDayId, sessionDate),
  );

  @override
  Future<Either<Failure, void>> saveSetLog(SetLog setLog) => guard(() async {
    final model = SetLogModel.fromEntity(setLog);
    await remoteDataSource.saveSetLog(model);
  });

  @override
  Future<Either<Failure, void>> deleteSetLog({
    required String sessionId,
    required String exerciseId,
    required int setIndex,
  }) => guard(
    () => remoteDataSource.deleteSetLog(
      sessionId: sessionId,
      exerciseId: exerciseId,
      setIndex: setIndex,
    ),
  );

  @override
  Future<Either<Failure, SetLog?>> getLastExercisePerformance(
    String exerciseId,
  ) => guard(() => remoteDataSource.getLastExercisePerformance(exerciseId));

  @override
  Future<Either<Failure, Map<String, SetLog?>>> getLastExercisePerformances(
    List<String> exerciseIds,
  ) => guard(() async {
    final result = await remoteDataSource.getLastExercisePerformances(
      exerciseIds,
    );
    return result.map((key, value) => MapEntry(key, value as SetLog?));
  });

  @override
  Future<Either<Failure, List<SetLog>>> getSessionSetLogs(String sessionId) =>
      guard(() => remoteDataSource.getSessionSetLogs(sessionId));

  @override
  Future<Either<Failure, Map<String, List<SetLog>>>> getSetLogsForSessions(
    List<String> sessionIds,
  ) => guard(() => remoteDataSource.getSetLogsForSessions(sessionIds));

  @override
  Future<Either<Failure, void>> assignRoutineToUser(
    String userId,
    String routineId,
  ) => guard(() => remoteDataSource.assignRoutineToUser(userId, routineId));

  @override
  Future<Either<Failure, List<WorkoutSession>>> getRecentSessionsForDay(
    String userId,
    String routineDayId,
    DateTime beforeDate, {
    int limit = 3,
  }) => guard(
    () => remoteDataSource.getRecentSessionsForDay(
      userId,
      routineDayId,
      beforeDate,
      limit: limit,
    ),
  );

  @override
  Future<Either<Failure, void>> finishWorkoutSession(
    String sessionId, {
    List<CoachingAnalysis>? coachingAnalysis,
  }) => guard(
    () => remoteDataSource.finishWorkoutSession(
      sessionId,
      coachingAnalysis: coachingAnalysis,
    ),
  );

  @override
  Future<Either<Failure, WeeklyInsights>> getWeeklyInsights({
    required String routineId,
    required DateTime weekStart,
  }) => guard(
    () => remoteDataSource.getWeeklyInsights(
      routineId: routineId,
      weekStart: weekStart,
    ),
  );

  @override
  Future<Either<Failure, List<ExerciseHistorySession>>> getExerciseLogsHistory(
    String userId,
    String exerciseId,
  ) => guard(() async {
    final rawData = await remoteDataSource.getExerciseLogsHistory(
      userId,
      exerciseId,
    );

    final Map<String, List<SetLogModel>> grouped = {};

    for (var row in rawData) {
      final sessionData = row['workout_sessions'] as Map<String, dynamic>?;
      final sessionDateStr = sessionData?['session_date'] as String?;
      if (sessionDateStr == null) continue;
      final parsedDate = DateTime.tryParse(sessionDateStr);
      if (parsedDate == null) continue;

      final String dateKey =
          "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";

      grouped.putIfAbsent(dateKey, () => []).add(SetLogModel.fromJson(row));
    }

    final sessions = grouped.entries
        .map(
          (entry) => ExerciseHistorySession(
            sessionDate: DateTime.parse(entry.key),
            logs: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

    return sessions;
  });

  @override
  Future<Either<Failure, Routine>> saveRoutine(Routine routine) =>
      guard(() async {
        final model = RoutineModel(
          id: routine.id,
          name: routine.name,
          exerciseCount: routine.exerciseCount,
          isPublic: routine.isPublic,
          creatorId: routine.creatorId,
          creatorName: routine.creatorName,
        );
        final saved = await remoteDataSource.saveRoutine(model);
        return Routine(
          id: saved.id,
          name: saved.name,
          exerciseCount: saved.exerciseCount,
          isPublic: saved.isPublic,
          creatorId: saved.creatorId,
          creatorName: saved.creatorName,
        );
      });

  @override
  Future<Either<Failure, void>> deleteRoutine(String routineId) =>
      guard(() => remoteDataSource.deleteRoutine(routineId));

  @override
  Future<Either<Failure, RoutineDay>> saveRoutineDay(RoutineDay day) =>
      guard(() async {
        final model = RoutineDayModel(
          id: day.id,
          routineId: day.routineId,
          name: day.name,
          dayOfWeek: day.dayOfWeek,
          exercises: day.exercises,
          targetSetsCount: day.targetSetsCount,
          status: day.status,
        );
        final saved = await remoteDataSource.saveRoutineDay(model);
        return RoutineDay(
          id: saved.id,
          routineId: saved.routineId,
          dayOfWeek: saved.dayOfWeek,
          name: saved.name,
          exercises: saved.exercises,
          targetSetsCount: saved.targetSetsCount,
          status: saved.status,
        );
      });

  @override
  Future<Either<Failure, void>> deleteRoutineDay(String dayId) =>
      guard(() => remoteDataSource.deleteRoutineDay(dayId));

  @override
  Future<Either<Failure, void>> addExerciseToDay(
    String dayId,
    String exerciseId, {
    required int targetSets,
    required int targetReps,
    required double targetWeight,
    int restSeconds = 90,
  }) => guard(
    () => remoteDataSource.addExerciseToDay(
      dayId,
      exerciseId,
      targetSets: targetSets,
      targetReps: targetReps,
      targetWeight: targetWeight,
      restSeconds: restSeconds,
    ),
  );

  @override
  Future<Either<Failure, void>> addExercisesToDay(
    String dayId,
    List<AddExerciseToDayPayload> items,
  ) => guard(
    () => remoteDataSource.addExercisesToDay(
      dayId,
      items
          .map(
            (p) => AddExerciseToDayItem(
              exerciseId: p.exerciseId,
              targetSets: p.targetSets,
              targetReps: p.targetReps,
              targetWeight: p.targetWeight,
              restSeconds: p.restSeconds,
            ),
          )
          .toList(),
    ),
  );

  @override
  Future<Either<Failure, void>> removeExerciseFromDay(
    String dayId,
    String exerciseId,
  ) =>
      guard(() => remoteDataSource.removeExerciseFromDay(dayId, exerciseId));

  @override
  Future<Either<Failure, void>> reorderExercisesInDay(
    String dayId,
    List<String> exerciseIds,
  ) =>
      guard(() => remoteDataSource.reorderExercisesInDay(dayId, exerciseIds));

  @override
  Future<Either<Failure, void>> updateExerciseTarget(
    String routineDayId,
    String exerciseId,
    double targetWeight,
    int targetReps, {
    int? targetSets,
    int? restSeconds,
  }) => guard(
    () => remoteDataSource.updateExerciseTarget(
      routineDayId,
      exerciseId,
      targetWeight,
      targetReps,
      targetSets: targetSets,
      restSeconds: restSeconds,
    ),
  );

  @override
  Future<Either<Failure, List<ExerciseCatalogItem>>> getExercisesCatalog({
    String? muscleGroup,
    String? search,
    int limit = 200,
  }) => guard(
    () => remoteDataSource.getExercisesCatalog(
      muscleGroup: muscleGroup,
      search: search,
      limit: limit,
    ),
  );

  @override
  Future<Either<Failure, List<RoutineHistorySession>>> getRoutineStats(
    String userId,
    String routineId,
  ) => guard(() async {
    final rawData = await remoteDataSource.getRoutineStats(userId, routineId);

    return rawData
        .map((row) {
          final sessionDateStr = row['session_date'] as String?;
          if (sessionDateStr == null) return null;
          final date = DateTime.tryParse(sessionDateStr);
          if (date == null) return null;
          final routineDayData =
              row['routine_days'] as Map<String, dynamic>?;
          final logs =
              (row['set_logs'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          double totalVolume = 0;
          int totalReps = 0;
          for (var log in logs) {
            final w = (log['actual_weight'] as num?)?.toDouble() ?? 0.0;
            final r = (log['actual_reps'] as num?)?.toInt() ?? 0;
            totalVolume += w * r;
            totalReps += r;
          }

          return RoutineHistorySession(
            sessionDate: date,
            routineDayId: row['routine_day_id']?.toString() ?? '',
            routineDayName:
                routineDayData?['name']?.toString() ?? 'Día eliminado',
            totalVolume: totalVolume,
            totalReps: totalReps,
            exerciseCount: logs.length,
          );
        })
        .whereType<RoutineHistorySession>()
        .toList();
  });

  @override
  Future<Either<Failure, WorkoutSession?>> getActiveSessionForUser(
    String userId,
  ) => guard(() => remoteDataSource.getActiveSessionForUser(userId));

  @override
  Future<Either<Failure, String?>> getRoutineDayNameById(
    String routineDayId,
  ) => guard(() => remoteDataSource.getRoutineDayNameById(routineDayId));

  @override
  Future<Either<Failure, List<Routine>>> getAllRoutines() =>
      guard(() => remoteDataSource.getAllRoutines());

  @override
  Future<Either<Failure, Routine>> getRoutineById(String routineId) =>
      guard(() => remoteDataSource.getRoutineById(routineId));
}
