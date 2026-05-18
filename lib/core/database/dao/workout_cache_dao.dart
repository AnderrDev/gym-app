import 'package:drift/drift.dart';

import 'package:gym_flutter/core/database/local_database.dart';
import 'package:gym_flutter/core/database/tables/cached_exercises_table.dart';
import 'package:gym_flutter/core/database/tables/cached_last_performances_table.dart';
import 'package:gym_flutter/core/database/tables/cached_routine_days_table.dart';
import 'package:gym_flutter/core/database/tables/cached_routine_exercises_table.dart';

part 'workout_cache_dao.g.dart';

/// DAO de las 4 tablas-espejo introducidas en Phase 1. Reads idempotentes y
/// writes envueltos en transacciones para que un fallo a mitad no deje el
/// cache parcialmente actualizado.
@DriftAccessor(
  tables: [
    CachedRoutineDays,
    CachedRoutineExercises,
    CachedExercises,
    CachedLastPerformances,
  ],
)
class WorkoutCacheDao extends DatabaseAccessor<LocalDatabase>
    with _$WorkoutCacheDaoMixin {
  WorkoutCacheDao(super.db);

  // ─── Reads ──────────────────────────────────────────────────────────────

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
    final rows = await (select(cachedRoutineExercises).join([
      innerJoin(
        cachedExercises,
        cachedExercises.id.equalsExp(cachedRoutineExercises.exerciseId),
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
      ..where(
        (t) =>
            t.userId.equals(userId) & t.exerciseId.isIn(exerciseIds),
      );
    final rows = await query.get();
    return {for (final r in rows) r.exerciseId: r};
  }

  // ─── Writes ─────────────────────────────────────────────────────────────

  /// Reemplaza atómicamente todas las filas de `cached_routine_days` para una
  /// rutina dada por las que llegan del remote. Si la lista entrante es vacía
  /// se borran las cacheadas (rutina sin días).
  Future<void> upsertRoutineDays(
    String routineId,
    List<CachedRoutineDaysCompanion> rows,
  ) {
    return transaction(() async {
      await (delete(cachedRoutineDays)
            ..where((t) => t.routineId.equals(routineId)))
          .go();
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
      await (delete(cachedRoutineExercises)
            ..where((t) => t.routineDayId.equals(routineDayId)))
          .go();

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
}
