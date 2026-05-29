import 'package:drift/drift.dart';

import 'package:gym_flutter/core/database/local_database.dart';

/// Construye la estrategia de migración para [`LocalDatabase`].
///
/// - `onCreate`: crea todas las tablas y siembra `app_meta` con la marca de
///   inicialización (`schema_initialized_at`) y la versión actual del esquema
///   (`schema_version`). Ambos timestamps usan epoch ms UTC. También crea los
///   índices auxiliares de las tablas de caché (Phase 1+2).
/// - `onUpgrade`:
///   - v1 → v2: tablas read-only del día activo (Phase 1).
///   - v2 → v3: tablas write-side + outbox (Phase 2).
///   - v3 → v4: tablas SWR para rutinas asignadas + weekly insights (Phase 4).
/// - `beforeOpen`: habilita foreign keys (PRAGMA `foreign_keys = ON`) en cada
///   apertura. SQLite las desactiva por defecto y queremos integridad
///   referencial efectiva cuando lleguen tablas relacionales.
MigrationStrategy buildMigrationStrategy(LocalDatabase db) {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();

      // Índices Phase 1.
      await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_cre_day_position '
        'ON cached_routine_exercises(routine_day_id, position)',
      );
      await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_cre_exercise '
        'ON cached_routine_exercises(exercise_id)',
      );
      await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_cached_routine_days_routine '
        'ON cached_routine_days(routine_id, day_of_week)',
      );

      // Índices Phase 2.
      await _createPhase2Indexes(db);

      // Índices Phase 4.
      await _createPhase4Indexes(db);

      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db
          .into(db.appMeta)
          .insert(
            AppMetaCompanion.insert(
              key: 'schema_initialized_at',
              value: now.toString(),
              updatedAt: now,
            ),
          );
      await db
          .into(db.appMeta)
          .insert(
            AppMetaCompanion.insert(
              key: 'schema_version',
              value: '4',
              updatedAt: now,
            ),
          );
    },
    onUpgrade: (Migrator m, int from, int to) async {
      assert(from <= to, 'Downgrade no soportado (from=$from, to=$to).');

      if (from < 2) {
        await m.createTable(db.cachedRoutineDays);
        await m.createTable(db.cachedRoutineExercises);
        await m.createTable(db.cachedExercises);
        await m.createTable(db.cachedLastPerformances);

        await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_cre_day_position '
          'ON cached_routine_exercises(routine_day_id, position)',
        );
        await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_cre_exercise '
          'ON cached_routine_exercises(exercise_id)',
        );
        await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_cached_routine_days_routine '
          'ON cached_routine_days(routine_id, day_of_week)',
        );

        final now = DateTime.now().toUtc().millisecondsSinceEpoch;
        await db.customStatement(
          'INSERT INTO app_meta (key, value, updated_at) '
          "VALUES ('schema_version', '2', ?) "
          "ON CONFLICT(key) DO UPDATE SET value='2', updated_at=?",
          [now, now],
        );
      }

      if (from < 3) {
        await m.createTable(db.cachedWorkoutSessions);
        await m.createTable(db.cachedSetLogs);
        await m.createTable(db.pendingMutations);

        await _createPhase2Indexes(db);

        final now = DateTime.now().toUtc().millisecondsSinceEpoch;
        await db.customStatement(
          'INSERT INTO app_meta (key, value, updated_at) '
          "VALUES ('schema_version', '3', ?) "
          "ON CONFLICT(key) DO UPDATE SET value='3', updated_at=?",
          [now, now],
        );
      }

      if (from < 4) {
        await m.createTable(db.cachedAssignedRoutines);
        await m.createTable(db.cachedWeeklyInsights);

        await _createPhase4Indexes(db);

        final now = DateTime.now().toUtc().millisecondsSinceEpoch;
        await db.customStatement(
          'INSERT INTO app_meta (key, value, updated_at) '
          "VALUES ('schema_version', '4', ?) "
          "ON CONFLICT(key) DO UPDATE SET value='4', updated_at=?",
          [now, now],
        );
      }
    },
    beforeOpen: (OpeningDetails details) async {
      await db.customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// Crea los índices auxiliares introducidos en Phase 2 (write-path + outbox).
/// Se extrajo para que `onCreate` y `onUpgrade` los compartan sin duplicar
/// SQL — `IF NOT EXISTS` los hace idempotentes.
Future<void> _createPhase2Indexes(LocalDatabase db) async {
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_cws_user_open '
    'ON cached_workout_sessions(user_id, completed_at)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_cws_user_date '
    'ON cached_workout_sessions(user_id, session_date)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_csl_session '
    'ON cached_set_logs(session_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_pm_ready '
    'ON pending_mutations(next_attempt_at, id)',
  );
}

/// Crea los índices auxiliares de Phase 4 (SWR para rutinas + insights).
/// `idx_car_user` cubre la consulta "rutinas del usuario más recientes".
Future<void> _createPhase4Indexes(LocalDatabase db) async {
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_car_user '
    'ON cached_assigned_routines(user_id, fetched_at)',
  );
}
