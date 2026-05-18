import 'package:drift/drift.dart';

import 'package:gym_flutter/core/database/local_database.dart';

/// Construye la estrategia de migración para [`LocalDatabase`].
///
/// - `onCreate`: crea todas las tablas y siembra `app_meta` con la marca de
///   inicialización (`schema_initialized_at`) y la versión actual del esquema
///   (`schema_version`). Ambos timestamps usan epoch ms UTC. También crea los
///   índices auxiliares de las tablas de caché (Phase 1).
/// - `onUpgrade`: para v1 → v2 crea las tablas de caché del día activo
///   (`cached_routine_days`, `cached_routine_exercises`, `cached_exercises`,
///   `cached_last_performances`) + índices auxiliares y bumpea
///   `schema_version` a `'2'`.
/// - `beforeOpen`: habilita foreign keys (PRAGMA `foreign_keys = ON`) en cada
///   apertura. SQLite las desactiva por defecto y queremos integridad
///   referencial efectiva cuando lleguen tablas relacionales en Phase 1+.
MigrationStrategy buildMigrationStrategy(LocalDatabase db) {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();

      // Índices auxiliares para los reads del día activo. `IF NOT EXISTS` es
      // tolerante con `createAll` (que ya define las tablas) y con la lógica
      // de upgrade que crea los mismos índices.
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
              value: '2',
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
    },
    beforeOpen: (OpeningDetails details) async {
      await db.customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
