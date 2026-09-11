import 'package:drift/drift.dart';

import 'package:gym_flutter/core/database/local_database.dart';
import 'package:gym_flutter/core/database/tables/cached_assigned_routines_table.dart';
import 'package:gym_flutter/core/database/tables/cached_exercises_table.dart';
import 'package:gym_flutter/core/database/tables/cached_last_performances_table.dart';
import 'package:gym_flutter/core/database/tables/cached_routine_days_table.dart';
import 'package:gym_flutter/core/database/tables/cached_routine_exercises_table.dart';
import 'package:gym_flutter/core/database/tables/cached_set_logs_table.dart';
import 'package:gym_flutter/core/database/tables/cached_weekly_insights_table.dart';
import 'package:gym_flutter/core/database/tables/cached_workout_sessions_table.dart';
import 'package:gym_flutter/core/database/tables/pending_mutations_table.dart';

part 'workout_cache_dao.g.dart';

/// DAO de las tablas de caché del workout. Phase 1 sólo expone reads/writes
/// de tablas read-only (días, ejercicios, last performances). Phase 2 añade
/// el espejo write-side (`cached_workout_sessions`, `cached_set_logs`) que
/// recibe escrituras locales primero y deja la sincronización al SyncWorker.
///
/// Las operaciones write multi-row se envuelven en transacciones para que
/// un fallo a mitad no deje el cache parcialmente actualizado.
@DriftAccessor(
  tables: [
    CachedRoutineDays,
    CachedRoutineExercises,
    CachedExercises,
    CachedLastPerformances,
    CachedWorkoutSessions,
    CachedSetLogs,
    PendingMutations,
    CachedAssignedRoutines,
    CachedWeeklyInsights,
  ],
)
class WorkoutCacheDao extends DatabaseAccessor<LocalDatabase>
    with _$WorkoutCacheDaoMixin {
  WorkoutCacheDao(super.db);

  // ─── Reads (Phase 1) ────────────────────────────────────────────────────

  Future<List<CachedRoutineDayRow>> readRoutineDays(String routineId) {
    final query = select(cachedRoutineDays)
      ..where((t) => t.routineId.equals(routineId))
      ..orderBy([(t) => OrderingTerm.asc(t.dayOfWeek)]);
    return query.get();
  }

  /// Devuelve los ejercicios de un día en orden de `position`, junto con el
  /// catálogo del ejercicio (nombre / muscle_group / imagen). Se materializa
  /// como records `(re, ex)` para que el datasource construya la entidad de
  /// dominio sin recurrir a otro DAO.
  Future<List<({CachedRoutineExerciseRow re, CachedExerciseRow ex})>>
  readExercisesForDay(String routineDayId) async {
    final rows =
        await (select(cachedRoutineExercises).join([
                innerJoin(
                  cachedExercises,
                  cachedExercises.id.equalsExp(
                    cachedRoutineExercises.exerciseId,
                  ),
                ),
              ])
              ..where(cachedRoutineExercises.routineDayId.equals(routineDayId))
              ..orderBy([OrderingTerm.asc(cachedRoutineExercises.position)]))
            .get();

    return rows
        .map(
          (row) => (
            re: row.readTable(cachedRoutineExercises),
            ex: row.readTable(cachedExercises),
          ),
        )
        .toList();
  }

  /// Map `exerciseId → CachedLastPerformanceRow`. Sólo incluye claves para
  /// las que hay cache; entradas missing las decide el caller (en el
  /// datasource quedan como `null` en el map de dominio).
  Future<Map<String, CachedLastPerformanceRow>> readLastPerformances(
    String userId,
    List<String> exerciseIds,
  ) async {
    if (exerciseIds.isEmpty) return const {};
    final query = select(cachedLastPerformances)
      ..where((t) => t.userId.equals(userId) & t.exerciseId.isIn(exerciseIds));
    final rows = await query.get();
    return {for (final r in rows) r.exerciseId: r};
  }

  // ─── Writes (Phase 1) ───────────────────────────────────────────────────

  /// Reemplaza atómicamente todas las filas de `cached_routine_days` para una
  /// rutina dada por las que llegan del remote. Si la lista entrante es vacía
  /// se borran las cacheadas (rutina sin días).
  Future<void> upsertRoutineDays(
    String routineId,
    List<CachedRoutineDaysCompanion> rows,
  ) {
    return transaction(() async {
      await (delete(
        cachedRoutineDays,
      )..where((t) => t.routineId.equals(routineId))).go();
      if (rows.isEmpty) return;
      await batch((b) {
        b.insertAll(cachedRoutineDays, rows);
      });
    });
  }

  /// Reemplaza atómicamente los ejercicios cacheados para un día. `catalog`
  /// son las filas de `cached_exercises` referenciadas, que se upsertean por
  /// id (el catálogo es global, no se borra al rotar un día).
  Future<void> replaceExercisesForDay(
    String routineDayId,
    List<CachedRoutineExercisesCompanion> exercises,
    List<CachedExercisesCompanion> catalog,
  ) {
    return transaction(() async {
      await (delete(
        cachedRoutineExercises,
      )..where((t) => t.routineDayId.equals(routineDayId))).go();

      if (catalog.isNotEmpty) {
        await batch((b) {
          b.insertAllOnConflictUpdate(cachedExercises, catalog);
        });
      }

      if (exercises.isNotEmpty) {
        await batch((b) {
          b.insertAll(cachedRoutineExercises, exercises);
        });
      }
    });
  }

  /// Upserta last-performances por `(userId, exerciseId)`. Cada entrada se
  /// inserta o reemplaza según conflicto en la PK compuesta.
  Future<void> upsertLastPerformances(
    String userId,
    Map<String, CachedLastPerformancesCompanion> performances,
  ) {
    if (performances.isEmpty) return Future.value();
    return transaction(() async {
      await batch((b) {
        for (final entry in performances.values) {
          b.insert(
            cachedLastPerformances,
            entry,
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    });
  }

  // ─── Phase 2: cached_workout_sessions ───────────────────────────────────

  /// Inserta o reemplaza una sesión cacheada. El caller (datasource local)
  /// se encarga de construir el companion completo — aquí solo persistimos.
  Future<void> saveCachedSession(CachedWorkoutSessionsCompanion row) {
    return into(
      cachedWorkoutSessions,
    ).insert(row, mode: InsertMode.insertOrReplace);
  }

  /// Marca una sesión como completada en local. No toca el resto de la
  /// fila — quien aplique coaching debe usar [`applyCoachingForSession`]
  /// por separado.
  Future<void> markSessionCompleted(String id, int completedAtMs) {
    return (update(cachedWorkoutSessions)..where((t) => t.id.equals(id))).write(
      CachedWorkoutSessionsCompanion(
        completedAt: Value(completedAtMs),
        fetchedAt: Value(completedAtMs),
        syncStatus: const Value('pending'),
      ),
    );
  }

  /// Persiste el JSON serializado del coaching tras finalizar la sesión.
  Future<void> applyCoachingForSession(String id, String coachingJson) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return (update(cachedWorkoutSessions)..where((t) => t.id.equals(id))).write(
      CachedWorkoutSessionsCompanion(
        coachingAnalysisJson: Value(coachingJson),
        fetchedAt: Value(now),
      ),
    );
  }

  /// Última sesión "abierta" (completed_at IS NULL) del usuario, ordenada
  /// por `started_at` descendente. Soporta el fallback offline de
  /// `getActiveSessionForUser`.
  Future<CachedWorkoutSessionRow?> readOpenSessionForUser(String userId) {
    final query = select(cachedWorkoutSessions)
      ..where((t) => t.userId.equals(userId) & t.completedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  /// Observa una sesión por id. Útil para que la UI reaccione en tiempo
  /// real a la actualización de `completedAt` o del coaching tras un
  /// drain exitoso.
  Stream<CachedWorkoutSessionRow?> watchSession(String id) {
    final query = select(cachedWorkoutSessions)
      ..where((t) => t.id.equals(id))
      ..limit(1);
    return query.watchSingleOrNull();
  }

  // ─── Phase 2: cached_set_logs ───────────────────────────────────────────

  /// Upsert por PK compuesta `(sessionId, exerciseId, setIndex)`. Mismo
  /// criterio que la unique constraint del backend, así el SyncWorker
  /// puede empujar varias veces sin duplicar.
  Future<void> upsertCachedSetLog(CachedSetLogsCompanion row) {
    return into(cachedSetLogs).insert(row, mode: InsertMode.insertOrReplace);
  }

  // ─── Phase 4: cached_assigned_routines ─────────────────────────────────

  /// Devuelve la caché de rutinas asignadas del usuario, más recientes
  /// primero (ordenadas por `fetchedAt` descendente — empata el
  /// orden esperado por la UI tras un refresco remoto).
  Future<List<CachedAssignedRoutineRow>> readAssignedRoutines(String userId) {
    final query = select(cachedAssignedRoutines)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)]);
    return query.get();
  }

  /// Reemplaza atómicamente las rutinas cacheadas del usuario por las que
  /// llegan del remote. Si la lista entrante es vacía se vacía la caché de
  /// ese usuario (no se borra la de otros usuarios).
  Future<void> replaceAssignedRoutines(
    String userId,
    List<CachedAssignedRoutinesCompanion> rows,
  ) {
    return transaction(() async {
      await (delete(
        cachedAssignedRoutines,
      )..where((t) => t.userId.equals(userId))).go();
      if (rows.isEmpty) return;
      await batch((b) {
        b.insertAll(cachedAssignedRoutines, rows);
      });
    });
  }

  // ─── Phase 4: cached_weekly_insights ───────────────────────────────────

  /// Lee un snapshot cacheado por la PK compuesta. `null` si nunca se
  /// hidrató para ese (usuario, rutina, semana).
  Future<CachedWeeklyInsightRow?> readWeeklyInsight(
    String userId,
    String routineId,
    String weekStart,
  ) {
    final query = select(cachedWeeklyInsights)
      ..where(
        (t) =>
            t.userId.equals(userId) &
            t.routineId.equals(routineId) &
            t.weekStart.equals(weekStart),
      )
      ..limit(1);
    return query.getSingleOrNull();
  }

  /// Upsert por PK compuesta `(userId, routineId, weekStart)`. El caller
  /// construye el companion completo (payloadJson serializado fuera).
  Future<void> upsertWeeklyInsight(CachedWeeklyInsightsCompanion row) {
    return into(
      cachedWeeklyInsights,
    ).insert(row, mode: InsertMode.insertOrReplace);
  }

  // ─── Phase 4: cached_workout_sessions (read-side de la semana) ─────────

  /// Devuelve las sesiones cacheadas del usuario dentro del rango
  /// `[weekStartIso, weekEndIso]` (ambos inclusivos, ISO `yyyy-MM-dd`).
  /// Comparación string-based — segura porque el formato lo decidimos
  /// nosotros y es lex-orderable.
  Future<List<CachedWorkoutSessionRow>> readWeekSessions(
    String userId,
    String weekStartIso,
    String weekEndIso,
  ) {
    final query = select(cachedWorkoutSessions)
      ..where(
        (t) =>
            t.userId.equals(userId) &
            t.sessionDate.isBiggerOrEqualValue(weekStartIso) &
            t.sessionDate.isSmallerOrEqualValue(weekEndIso),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.sessionDate)]);
    return query.get();
  }

  /// Upserta filas que vienen del remote (estado `synced`). Para evitar
  /// colisiones write-side respeta cualquier fila local cuyo `sync_status`
  /// esté en `pending | syncing | error` (esas las gestiona el SyncWorker).
  /// El resto se reemplaza con la fila remota.
  Future<void> upsertSyncedSessions(List<CachedWorkoutSessionsCompanion> rows) {
    if (rows.isEmpty) return Future.value();
    return transaction(() async {
      for (final row in rows) {
        if (!row.id.present) continue;
        final id = row.id.value;
        final existing =
            await (select(cachedWorkoutSessions)
                  ..where((t) => t.id.equals(id))
                  ..limit(1))
                .getSingleOrNull();
        if (existing != null) {
          const protected = {'pending', 'syncing', 'error'};
          if (protected.contains(existing.syncStatus)) {
            // No tocar — el writer local manda.
            continue;
          }
        }
        await into(cachedWorkoutSessions).insert(
          row.copyWith(syncStatus: const Value('synced')),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }
}
