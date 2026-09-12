import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:gym_flutter/core/database/local_database.dart';
import 'package:gym_flutter/core/error/error_mapper.dart';
import 'package:gym_flutter/core/error/exceptions.dart' as core_ex;
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:gym_flutter/core/sync/connectivity_service.dart';
import 'package:gym_flutter/core/utils/clock.dart';
import 'package:gym_flutter/core/sync/outbox_repository.dart';
import 'package:gym_flutter/core/sync/sync_worker.dart';
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

  /// Outbox para Phase 2 write-path. Si llega `null` el repositorio cae
  /// al comportamiento legacy (escritura directa al remote).
  final OutboxRepository? outbox;

  /// Worker que drena la outbox. El repositorio le dice `kick()` tras
  /// encolar para acelerar el sync sin esperar al próximo evento.
  final SyncWorker? syncWorker;

  /// Generador de UUIDs. Solo se usa en el camino offline-capable; en
  /// tests legacy queda `null` para no romper constructores existentes.
  final Uuid? uuid;

  /// Local DB. Se usa para envolver `local.write + outbox.enqueue` en una
  /// única transacción atómica. `null` desactiva esa garantía y los dos
  /// writes salen secuencialmente (suficiente para los tests que mockean).
  final LocalDatabase? localDatabase;

  /// Reloj inyectable. Producción: [SystemClock] vía DI. Tests: [FakeClock].
  /// Fallback a [SystemClock] para los tests legacy que no lo inyectan.
  final Clock _clock;

  /// Resolver del usuario actual. Por defecto `Supabase.instance.client.auth`,
  /// inyectable para tests sin singleton.
  final String? Function() _currentUserId;

  WorkoutRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
    this.connectivity,
    this.outbox,
    this.syncWorker,
    this.uuid,
    this.localDatabase,
    Clock? clock,
    String? Function()? currentUserIdResolver,
  }) : _clock = clock ?? const SystemClock(),
       _currentUserId =
           currentUserIdResolver ??
           (() => Supabase.instance.client.auth.currentUser?.id);

  bool get _isOnline => connectivity?.isOnline ?? true;

  /// Indica si la capa local-first está completa (cache + outbox + uuid).
  /// Si falta cualquiera, los métodos write caen al comportamiento legacy
  /// (escritura directa al remote sin offline) — preserva la compat con
  /// tests Phase 0/1 que solo inyectan `remoteDataSource`.
  bool get _offlineCapable =>
      outbox != null && localDataSource != null && uuid != null;

  /// Ejecuta `op` dentro de una transacción si hay [`localDatabase`], si no
  /// la corre tal cual. Permite que `local.write + outbox.enqueue` sean
  /// atómicos en producción sin obligar a los tests a montar la DB real.
  Future<T> _txn<T>(Future<T> Function() op) {
    final db = localDatabase;
    if (db == null) return op();
    return db.transaction(op);
  }

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
            AppLogger.instance.warning(
              'workout_cache.write_failed[$label]: $e',
            );
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

  /// Variante de SWR pensada para superficies de la dashboard que prefieren
  /// pintar un estado vacío (`offlineFallback`) antes que romper el render
  /// cuando no hay red. La diferencia con [`_swrList`]:
  ///
  /// - En **modo online**, los fallos de negocio (PGRST116, auth, validation,
  ///   conflict, etc.) siguen propagándose — el caller mapea con
  ///   `mapToFailure` y se traducen al `Failure` correcto. Sólo los fallos
  ///   **network-like** caen al cache; si tampoco hay cache, *re-throw* el
  ///   error original.
  /// - En **modo offline**, devuelve cache si existe, sino `offlineFallback`
  ///   silenciosamente — la app no debería romperse por estar desconectada.
  ///
  /// Si [`localDataSource`] es null y estamos offline, devolvemos
  /// `offlineFallback` directamente.
  Future<T> _swrNullable<T>({
    required Future<T> Function() fetchRemote,
    required Future<void> Function(T value) writeCache,
    required Future<T?> Function() readCache,
    required T offlineFallback,
    required String label,
  }) async {
    if (_isOnline) {
      try {
        final fresh = await fetchRemote();
        if (localDataSource != null) {
          try {
            await writeCache(fresh);
          } catch (e) {
            AppLogger.instance.warning(
              'workout_cache.write_failed[$label]: $e',
            );
          }
        }
        return fresh;
      } catch (e) {
        final isNetwork =
            e is core_ex.NetworkException ||
            (e is Exception && _isNetworkLike(e));
        if (!isNetwork) {
          // Negocio (NotFound/Auth/...). Propagamos para preservar
          // semántica del Failure mapping.
          rethrow;
        }
        AppLogger.instance.warning(
          'workout_cache.remote_failed[$label] → fallback cache/offline: $e',
        );
        if (localDataSource == null) return offlineFallback;
        final cached = await readCache();
        return cached ?? offlineFallback;
      }
    }

    if (localDataSource == null) return offlineFallback;
    final cached = await readCache();
    return cached ?? offlineFallback;
  }

  @override
  Future<Either<Failure, List<Routine>>> getAssignedRoutines(String userId) =>
      guard(
        () => _swrNullable<List<Routine>>(
          label: 'assignedRoutines',
          fetchRemote: () async {
            final fresh = await remoteDataSource.getAssignedRoutines(userId);
            return fresh.map((m) => m.toEntity()).toList();
          },
          writeCache: (routines) async {
            if (localDataSource == null) return;
            await localDataSource!.cacheAssignedRoutines(userId, routines);
          },
          readCache: () async {
            if (localDataSource == null) return null;
            return localDataSource!.getAssignedRoutines(userId);
          },
          offlineFallback: const <Routine>[],
        ),
      );

  @override
  Future<Either<Failure, List<RoutineDay>>> getRoutineDays(String routineId) =>
      guard(
        () => _swrList<List<RoutineDay>>(
          label: 'routineDays',
          fetchRemote: () async {
            final fresh = await remoteDataSource.getRoutineDays(routineId);
            return fresh.map((m) => m.toEntity()).toList();
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
  ) => guard(
    () => _swrList<List<Exercise>>(
      label: 'exercisesForDay',
      fetchRemote: () async {
        final fresh = await remoteDataSource.getExercisesForDay(routineDayId);
        return fresh.map((m) => m.toEntity()).toList();
      },
      writeCache: (exercises) =>
          localDataSource!.cacheExercisesForDay(routineDayId, exercises),
      readCache: () => localDataSource!.getExercisesForDay(routineDayId),
      isEmpty: (l) => l.isEmpty,
    ),
  );

  @override
  Future<Either<Failure, List<WorkoutSession>>> getWeekSessions(
    String userId,
    DateTime weekStart,
    DateTime weekEnd,
  ) => guard(
    () => _swrNullable<List<WorkoutSession>>(
      label: 'weekSessions',
      fetchRemote: () async {
        final fresh = await remoteDataSource.getWeekSessions(
          userId,
          weekStart,
          weekEnd,
        );
        return fresh.map((m) => m.toEntity()).toList();
      },
      writeCache: (sessions) async {
        if (localDataSource == null) return;
        await localDataSource!.cacheWeekSessions(userId, sessions);
      },
      readCache: () async {
        if (localDataSource == null) return null;
        return localDataSource!.getWeekSessions(userId, weekStart, weekEnd);
      },
      offlineFallback: const <WorkoutSession>[],
    ),
  );

  @override
  Future<Either<Failure, WorkoutSession?>> getExistingSession(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  ) => guard(
    () async => (await remoteDataSource.getExistingSession(
      userId,
      routineDayId,
      sessionDate,
    ))?.toEntity(),
  );

  @override
  Future<Either<Failure, WorkoutSession>> startWorkoutForDay(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  ) => guard(() async {
    // Online-first: si hay red, escribimos directo al remoto y devolvemos
    // la sesión real (con el id que asignó Postgres). Sólo si genuinamente
    // estamos offline caemos al outbox local. Antes el path local-first
    // siempre encolaba aunque el cliente estuviera online, y el drain del
    // SyncWorker quedaba atascado con backoffs / RLS auth-pause, dejando
    // los POST sin enviarse "ahí mismo".
    if (!_offlineCapable || _isOnline) {
      final session = (await remoteDataSource.startWorkoutForDay(
        userId,
        routineDayId,
        sessionDate,
      )).toEntity();
      if (localDataSource != null) {
        try {
          await localDataSource!.saveCachedSession(session);
        } catch (e) {
          AppLogger.instance.warning(
            'startWorkoutForDay: cache write failed: $e',
          );
        }
      }
      return session;
    }
    // Offline real: id provisional uuid v4 + outbox. SyncWorker empuja
    // cuando recupera red.
    final newId = uuid!.v4();
    final session = WorkoutSession(
      id: newId,
      userId: userId,
      routineDayId: routineDayId,
      sessionDate: sessionDate,
    );
    await _txn(() async {
      await localDataSource!.saveCachedSession(session);
      await outbox!.enqueue(MutationKind.insertSession, {
        'id': newId,
        'user_id': userId,
        'routine_day_id': routineDayId,
        'session_date': _isoDate(sessionDate),
      });
    });
    unawaited(syncWorker?.kick());
    return session;
  });

  @override
  Future<Either<Failure, void>> saveSetLog(SetLog setLog) => guard(() async {
    // Online-first (ver nota en `startWorkoutForDay`). El POST sale ya
    // mismo cuando hay red; el outbox sólo entra si estamos offline.
    if (!_offlineCapable || _isOnline) {
      try {
        await remoteDataSource.saveSetLog(SetLogModel.fromEntity(setLog));
      } catch (e) {
        // Si el POST falla por red (el gym tiene wifi "conectado" pero sin
        // salida, timeout, DNS…), la serie NO se puede perder: cae al
        // outbox y el SyncWorker la reintenta. Los errores semánticos
        // (RLS, validación) sí se propagan para que la UI avise.
        if (!_offlineCapable || mapToFailure(e) is! NetworkFailure) rethrow;
        AppLogger.instance.warning('saveSetLog: remote failed, outbox: $e');
        await _enqueueSetLog(setLog);
        return;
      }
      if (localDataSource != null) {
        try {
          await localDataSource!.upsertCachedSetLog(setLog);
        } catch (e) {
          AppLogger.instance.warning('saveSetLog: cache write failed: $e');
        }
      }
      return;
    }
    await _enqueueSetLog(setLog);
  });

  Future<void> _enqueueSetLog(SetLog setLog) async {
    await _txn(() async {
      await localDataSource!.upsertCachedSetLog(setLog);
      await outbox!.enqueue(MutationKind.upsertSetLog, {
        'id': setLog.id,
        'session_id': setLog.sessionId,
        'exercise_id': setLog.exerciseId,
        'actual_weight': setLog.actualWeight,
        'actual_reps': setLog.actualReps,
        'set_index': setLog.setIndex,
        'created_at': setLog.createdAt?.toUtc().toIso8601String(),
      });
    });
    unawaited(syncWorker?.kick());
  }

  @override
  Future<Either<Failure, void>> deleteSetLog({
    required String sessionId,
    required String exerciseId,
    required int setIndex,
  }) => guard(() async {
    Future<void> dropFromCache() async {
      if (localDataSource == null) return;
      try {
        await localDataSource!.deleteCachedSetLog(
          sessionId: sessionId,
          exerciseId: exerciseId,
          setIndex: setIndex,
        );
      } catch (e) {
        AppLogger.instance.warning('deleteSetLog: cache delete failed: $e');
      }
    }

    if (!_offlineCapable || _isOnline) {
      try {
        await remoteDataSource.deleteSetLog(
          sessionId: sessionId,
          exerciseId: exerciseId,
          setIndex: setIndex,
        );
      } catch (e) {
        if (!_offlineCapable || mapToFailure(e) is! NetworkFailure) rethrow;
        AppLogger.instance.warning('deleteSetLog: remote failed, outbox: $e');
        await _enqueueSetLogDelete(sessionId, exerciseId, setIndex);
        return;
      }
      await dropFromCache();
      return;
    }
    await _enqueueSetLogDelete(sessionId, exerciseId, setIndex);
  });

  /// El borrado viaja por outbox para respetar el orden FIFO respecto del
  /// `upsertSetLog` del mismo set (si no, el upsert encolado lo resucitaría).
  Future<void> _enqueueSetLogDelete(
    String sessionId,
    String exerciseId,
    int setIndex,
  ) async {
    await _txn(() async {
      await localDataSource!.deleteCachedSetLog(
        sessionId: sessionId,
        exerciseId: exerciseId,
        setIndex: setIndex,
      );
      await outbox!.enqueue(MutationKind.deleteSetLog, {
        'session_id': sessionId,
        'exercise_id': exerciseId,
        'set_index': setIndex,
      });
    });
    unawaited(syncWorker?.kick());
  }

  @override
  Future<Either<Failure, SetLog?>> getLastExercisePerformance(
    String exerciseId,
  ) => guard(
    () async => (await remoteDataSource.getLastExercisePerformance(
      exerciseId,
    ))?.toEntity(),
  );

  @override
  Future<Either<Failure, Map<String, SetLog?>>> getLastExercisePerformances(
    List<String> exerciseIds,
  ) => guard(() async {
    if (exerciseIds.isEmpty) return <String, SetLog?>{};
    final userId = _currentUserId();
    final canCache = userId != null && localDataSource != null;

    return _swrList<Map<String, SetLog?>>(
      label: 'lastPerformances',
      fetchRemote: () async {
        final result = await remoteDataSource.getLastExercisePerformances(
          exerciseIds,
        );
        return result.map((k, v) => MapEntry(k, v?.toEntity()));
      },
      writeCache: (map) async {
        if (!canCache) return;
        await localDataSource!.cacheLastPerformances(userId, map);
      },
      readCache: () async {
        if (!canCache) return null;
        return localDataSource!.getLastPerformancesForExercises(
          userId,
          exerciseIds,
        );
      },
      // El map siempre llega con keys = exerciseIds (incluso si los
      // values son `null`). Lo consideramos vacío sólo cuando todos
      // los values son null Y veníamos del cache (no del remote).
      isEmpty: (m) => m.values.every((v) => v == null),
    );
  });

  @override
  Future<Either<Failure, List<SetLog>>> getSessionSetLogs(String sessionId) =>
      guard(
        () async => (await remoteDataSource.getSessionSetLogs(
          sessionId,
        )).map((m) => m.toEntity()).toList(),
      );

  @override
  Future<Either<Failure, Map<String, List<SetLog>>>> getSetLogsForSessions(
    List<String> sessionIds,
  ) => guard(() async {
    final raw = await remoteDataSource.getSetLogsForSessions(sessionIds);
    return raw.map((k, v) => MapEntry(k, v.map((m) => m.toEntity()).toList()));
  });

  @override
  Future<Either<Failure, List<WorkoutSession>>> getRecentSessionsForDay(
    String userId,
    String routineDayId,
    DateTime beforeDate, {
    int limit = 3,
  }) => guard(
    () async => (await remoteDataSource.getRecentSessionsForDay(
      userId,
      routineDayId,
      beforeDate,
      limit: limit,
    )).map((m) => m.toEntity()).toList(),
  );

  @override
  Future<Either<Failure, void>> finishWorkoutSession(
    String sessionId, {
    List<CoachingAnalysis>? coachingAnalysis,
  }) => guard(() async {
    // Online-first (ver nota en `startWorkoutForDay`).
    if (!_offlineCapable || _isOnline) {
      await remoteDataSource.finishWorkoutSession(
        sessionId,
        coachingAnalysis: coachingAnalysis,
      );
      if (localDataSource != null) {
        try {
          await localDataSource!.markSessionCompleted(
            sessionId,
            _clock.now().toUtc(),
          );
        } catch (e) {
          AppLogger.instance.warning(
            'finishWorkoutSession: cache write failed: $e',
          );
        }
      }
      return;
    }
    final completedAt = _clock.now().toUtc();
    await _txn(() async {
      await localDataSource!.markSessionCompleted(sessionId, completedAt);
      await outbox!.enqueue(MutationKind.finalizeSession, {
        'session_id': sessionId,
        'coaching_analysis': coachingAnalysis?.map((c) => c.toJson()).toList(),
      });
    });
    unawaited(syncWorker?.kick());
  });

  @override
  Future<Either<Failure, WeeklyInsights>> getWeeklyInsights({
    required String routineId,
    required DateTime weekStart,
  }) => guard(() async {
    final userId = _currentUserId();
    // El cache va por (userId, routineId, weekStart). Si no hay user
    // resoluble (tests sin Supabase singleton) saltamos cache —
    // remote-only con offlineFallback como red de seguridad.
    final canCache = userId != null && localDataSource != null;
    final fallback = WeeklyInsights(
      weekStart: weekStart,
      weekEnd: weekStart.add(const Duration(days: 6)),
      plannedDays: 0,
      completedDays: 0,
      completedSessions: 0,
      adherenceRate: 0,
      totalVolume: 0,
      previousWeekVolume: 0,
      volumeTrendPercent: 0,
      personalRecords: 0,
    );
    return _swrNullable<WeeklyInsights>(
      label: 'weeklyInsights',
      fetchRemote: () => remoteDataSource.getWeeklyInsights(
        routineId: routineId,
        weekStart: weekStart,
      ),
      writeCache: (insights) async {
        if (!canCache) return;
        await localDataSource!.cacheWeeklyInsights(
          userId: userId,
          routineId: routineId,
          insights: insights,
        );
      },
      readCache: () async {
        if (!canCache) return null;
        return localDataSource!.getWeeklyInsights(userId, routineId, weekStart);
      },
      offlineFallback: fallback,
    );
  });

  @override
  Future<Either<Failure, List<ExerciseHistorySession>>> getExerciseLogsHistory(
    String userId,
    String exerciseId,
  ) => guard(() async {
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
  ) => guard(() async {
    final rawData = await remoteDataSource.getRoutineStats(userId, routineId);
    return mapRoutineSessionRows(rawData);
  });

  @override
  Future<Either<Failure, WorkoutSession?>> getActiveSessionForUser(
    String userId,
  ) => guard(() async {
    try {
      return (await remoteDataSource.getActiveSessionForUser(
        userId,
      ))?.toEntity();
    } catch (e) {
      // Fallback offline-capable: ante errores de red caemos al cache
      // local. Mantenemos el throw para todos los demás errores —
      // `mapToFailure` los traducirá al failure correcto.
      if (!_offlineCapable) rethrow;
      if (e is core_ex.NetworkException ||
          e is Exception && _isNetworkLike(e)) {
        AppLogger.instance.warning(
          'workout_repo.active_session.remote_failed → fallback cache: $e',
        );
        return localDataSource!.getOpenSessionForUser(userId);
      }
      rethrow;
    }
  });

  /// Stream observable de una sesión local. UI puede suscribirse para ver
  /// cambios tras drain (e.g. coaching aplicado).
  @override
  Stream<WorkoutSession?> watchSession(String id) {
    final local = localDataSource;
    if (local == null) return const Stream<WorkoutSession?>.empty();
    return local.watchSession(id);
  }

  bool _isNetworkLike(Object e) {
    // SocketException está en dart:io; no la importamos directamente para
    // mantener este file plataforma-agnóstico. Comparamos por nombre del
    // runtime type, igual que hace el error_mapper en otros casos.
    final name = e.runtimeType.toString();
    return name == 'SocketException' || name == 'TimeoutException';
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
