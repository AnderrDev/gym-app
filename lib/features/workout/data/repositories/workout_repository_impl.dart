import 'package:fpdart/fpdart.dart';

import 'package:gym_flutter/core/error/error_mapper.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_remote_data_source.dart';
import 'package:gym_flutter/features/workout/data/models/set_log_model.dart';
import 'package:gym_flutter/features/workout/data/repositories/workout_repository_mappers.dart';
import 'package:gym_flutter/features/workout/data/repositories/workout_repository_routine_mgmt.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_history_session.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_history_session.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class WorkoutRepositoryImpl extends WorkoutRepository
    with WorkoutRepositoryRoutineMgmtMixin {
  @override
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
  ) =>
      guard(() => remoteDataSource.getExercisesForDay(routineDayId));

  @override
  Future<Either<Failure, List<WorkoutSession>>> getWeekSessions(
    String userId,
    DateTime weekStart,
    DateTime weekEnd,
  ) =>
      guard(
        () => remoteDataSource.getWeekSessions(userId, weekStart, weekEnd),
      );

  @override
  Future<Either<Failure, WorkoutSession?>> getExistingSession(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  ) =>
      guard(
        () => remoteDataSource.getExistingSession(
          userId,
          routineDayId,
          sessionDate,
        ),
      );

  @override
  Future<Either<Failure, WorkoutSession>> startWorkoutForDay(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  ) =>
      guard(
        () => remoteDataSource.startWorkoutForDay(
          userId,
          routineDayId,
          sessionDate,
        ),
      );

  @override
  Future<Either<Failure, void>> saveSetLog(SetLog setLog) => guard(() async {
        await remoteDataSource.saveSetLog(SetLogModel.fromEntity(setLog));
      });

  @override
  Future<Either<Failure, void>> deleteSetLog({
    required String sessionId,
    required String exerciseId,
    required int setIndex,
  }) =>
      guard(
        () => remoteDataSource.deleteSetLog(
          sessionId: sessionId,
          exerciseId: exerciseId,
          setIndex: setIndex,
        ),
      );

  @override
  Future<Either<Failure, SetLog?>> getLastExercisePerformance(
    String exerciseId,
  ) =>
      guard(() => remoteDataSource.getLastExercisePerformance(exerciseId));

  @override
  Future<Either<Failure, Map<String, SetLog?>>> getLastExercisePerformances(
    List<String> exerciseIds,
  ) =>
      guard(() async {
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
  ) =>
      guard(() => remoteDataSource.getSetLogsForSessions(sessionIds));

  @override
  Future<Either<Failure, List<WorkoutSession>>> getRecentSessionsForDay(
    String userId,
    String routineDayId,
    DateTime beforeDate, {
    int limit = 3,
  }) =>
      guard(
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
  }) =>
      guard(
        () => remoteDataSource.finishWorkoutSession(
          sessionId,
          coachingAnalysis: coachingAnalysis,
        ),
      );

  @override
  Future<Either<Failure, WeeklyInsights>> getWeeklyInsights({
    required String routineId,
    required DateTime weekStart,
  }) =>
      guard(
        () => remoteDataSource.getWeeklyInsights(
          routineId: routineId,
          weekStart: weekStart,
        ),
      );

  @override
  Future<Either<Failure, List<ExerciseHistorySession>>> getExerciseLogsHistory(
    String userId,
    String exerciseId,
  ) =>
      guard(() async {
        final rawData = await remoteDataSource.getExerciseLogsHistory(
          userId,
          exerciseId,
        );
        return mapExerciseLogsToHistory(rawData);
      });

  @override
  Future<Either<Failure, List<RoutineHistorySession>>> getRoutineStats(
    String userId,
    String routineId,
  ) =>
      guard(() async {
        final rawData = await remoteDataSource.getRoutineStats(
          userId,
          routineId,
        );
        return mapRoutineSessionRows(rawData);
      });

  @override
  Future<Either<Failure, WorkoutSession?>> getActiveSessionForUser(
    String userId,
  ) =>
      guard(() => remoteDataSource.getActiveSessionForUser(userId));
}
