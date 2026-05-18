import 'package:drift/drift.dart';

import 'package:gym_flutter/core/database/connection/open_connection.dart';
import 'package:gym_flutter/core/database/migrations/migration_strategy.dart';
import 'package:gym_flutter/core/database/tables/app_meta_table.dart';

part 'local_database.g.dart';

/// Base de datos local de la app (SQLite, vía drift).
///
/// Phase 0 sólo expone la tabla [`AppMeta`] como bookkeeping del esquema. Las
/// fases siguientes añadirán tablas espejo de Supabase (rutinas, ejercicios,
/// sesiones, set logs, sync queue, etc.). Cada fase actualiza
/// [`schemaVersion`] y registra la migración en
/// [`buildMigrationStrategy`].
@DriftDatabase(tables: [AppMeta])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase._(super.e);

  /// Abre la BD de producción usando el executor de la plataforma actual.
  factory LocalDatabase.open() => LocalDatabase._(openConnection());

  /// Punto de entrada para tests: inyecta el executor (típicamente
  /// `NativeDatabase.memory()`).
  factory LocalDatabase.forTesting(QueryExecutor e) => LocalDatabase._(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => buildMigrationStrategy(this);

  /// Healthcheck. Lee la fila `schema_initialized_at` del bookkeeping y la
  /// devuelve como [`DateTime`] (UTC). Lanza [`StateError`] si la fila no
  /// existe — eso indicaría que `onCreate` no corrió o que la BD está corrupta.
  Future<DateTime> ping() async {
    final row =
        await (select(appMeta)..where((t) => t.key.equals('schema_initialized_at')))
            .getSingleOrNull();

    if (row == null) {
      throw StateError(
        'LocalDatabase.ping: falta la fila app_meta[schema_initialized_at]. '
        'La inicialización del esquema (onCreate) no se ejecutó correctamente.',
      );
    }

    final epochMs = int.parse(row.value);
    return DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true);
  }
}
