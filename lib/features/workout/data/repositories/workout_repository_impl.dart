import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gym_flutter/core/error/error_mapper.dart';
import 'package:gym_flutter/core/error/exceptions.dart' as core_ex;
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:gym_flutter/core/sync/connectivity_service.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_local_data_source.dart';
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

  /// Caché local. `null` en plataformas sin persistencia (web Phase W).
  final WorkoutLocalDataSource? localDataSource;

  /// Fuente de verdad para online/offline. Si llega `null` (entornos
  /// extremadamente acotados / tests legacy) se asume online; los métodos
  /// SWR delegan en este servicio antes de decidir red vs cache.
  final ConnectivityService? connectivity;

  /// Resolver del usuario actual. Por defecto `Supabase.instance.client.auth`,
  /// inyectable para tests sin singleton.
  final String? Function() _currentUserId;

  WorkoutRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
    this.connectivity,
    String? Function()? currentUserIdResolver,
  }) : _currentUserId = currentUserIdResolver ??
            (() => Supabase.instance.client.auth.currentUser?.id);

  bool get _isOnline => connectivity?.isOnline ?? true;

  /// Patrón Stale-While-Revalidate. Si hay red, intenta remote y refresca el
  /// cache; ante fallo, devuelve cache si lo hay. Sin red, sólo cache. Si
  /// no hay nada usable, lanza [`NetworkException`] (mapeado a
  /// `NetworkFailure` por [`mapToFailure`]).
  Future<T> _swrList<T>({
    required Future<T> Function() fetchRemote,
    required Future<void> Function(T value) writeCache,
    required Future<T?> Function() readCache,
    required bool Function(T value) isEmpty,
    required String label,
  }) async {
    if (_isOnline) {
      try {
        final fresh = await fetchRemote();
        if (localDataSource != null) {
          try {
            await writeCache(fresh);
          } catch (e) {
            AppLogger.instance
                .warning('workout_cache.write_failed[$label]: $e');
          }
        }
        return fresh;
      } catch (e) {
        if (localDataSource == null) rethrow;
        AppLogger.instance.warning(
          'workout_cache.remote_failed[$label] → fallback cache: $e',
        );
        final cached = await readCache();
        if (cached != null && !isEmpty(cached)) return cached;
        rethrow;
      }
    }

    if (localDataSource == null) {
      throw core_ex.NetworkException();
    }
    final cached = await readCache();
    if (cached == null || isEmpty(cached)) {
      throw core_ex.NetworkException();
    }
    return cached;
  }

  @override
  Future<Either<Failure, List<Routine>>> getAssignedRoutines(String userId) =>
      guard(() => remoteDataSource.getAssignedRoutines(userId));

  @override
  Future<Either<Failure, List<RoutineDay>>> getRoutineDays(String routineId) =>
      guard(
        () => _swrList<List<RoutineDay>>(
          label: 'routineDays',
          fetchRemote: () async {
            final fresh = await remoteDataSource.getRoutineDays(routineId);
            return List<RoutineDay>.from(fresh);
          },
          writeCache: (days) =>
              localDataSource!.cacheRoutineDays(routineId, days),
          readCache: () => localDataSource!.getRoutineDays(routineId),
          isEmpty: (l) => l.isEmpty,
        ),
      );

  @override
  Future<Either<Failure, List<Exercise>>> getExercisesForDay(
    String routineDayId,
  ) =>
      guard(
        () => _swrList<List<Exercise>>(
          label: 'exercisesForDay',
          fetchRemote: () async {
            final fresh =
                await remoteDataSource.getExercisesForDay(routineDayId);
            return List<Exercise>.from(fresh);
          },
          writeCache: (exercises) =>
              localDataSource!.cacheExercisesForDay(routineDayId, exercises),
          readCache: () =>
              localDataSource!.getExercisesForDay(routineDayId),
          isEmpty: (l) => l.isEmpty,
        ),
      );

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
        if (exerciseIds.isEmpty) return <String, SetLog?>{};
        final userId = _currentUserId();
        final canCache = userId != null && localDataSource != null;

        return _swrList<Map<String, SetLog?>>(
          label: 'lastPerformances',
          fetchRemote: () async {
            final result =
                await remoteDataSource.getLastExercisePerformances(
              exerciseIds,
            );
            return result.map((k, v) => MapEntry(k, v as SetLog?));
          },
          writeCache: (map) async {
            if (!canCache) return;
            await localDataSource!.cacheLastPerformances(userId, map);
          },
          readCache: () async {
            if (!canCache) return null;
            return localDataSource!
                .getLastPerformancesForExercises(userId, exerciseIds);
          },
          // El map siempre llega con keys = exerciseIds (incluso si los
          // values son `null`). Lo consideramos vacío sólo cuando todos
          // los values son null Y veníamos del cache (no del remote).
          isEmpty: (m) => m.values.every((v) => v == null),
        );
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
