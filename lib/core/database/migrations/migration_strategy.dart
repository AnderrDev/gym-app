import 'package:drift/drift.dart';

import 'package:gym_flutter/core/database/local_database.dart';

/// Construye la estrategia de migración para [`LocalDatabase`].
///
/// - `onCreate`: crea todas las tablas y siembra `app_meta` con la marca de
///   inicialización (`schema_initialized_at`) y la versión actual del esquema
///   (`schema_version`). Ambos timestamps usan epoch ms UTC.
/// - `onUpgrade`: stub para Fase 1+. Por ahora sólo valida que el upgrade vaya
///   hacia adelante (`from <= to`).
/// - `beforeOpen`: habilita foreign keys (PRAGMA `foreign_keys = ON`) en cada
///   apertura. SQLite las desactiva por defecto y queremos integridad
///   referencial efectiva cuando lleguen tablas relacionales en Phase 1+.
MigrationStrategy buildMigrationStrategy(LocalDatabase db) {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();

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
              value: '1',
              updatedAt: now,
            ),
          );
    },
    onUpgrade: (Migrator m, int from, int to) async {
      assert(from <= to, 'Downgrade no soportado (from=$from, to=$to).');
      // Phase 1+ migrations go here.
    },
    beforeOpen: (OpeningDetails details) async {
      await db.customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
