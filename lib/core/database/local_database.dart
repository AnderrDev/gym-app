import 'package:drift/drift.dart';

import 'package:gym_flutter/core/database/connection/open_connection.dart';
import 'package:gym_flutter/core/database/migrations/migration_strategy.dart';
import 'package:gym_flutter/core/database/tables/app_meta_table.dart';
import 'package:gym_flutter/core/database/tables/cached_assigned_routines_table.dart';
import 'package:gym_flutter/core/database/tables/cached_exercises_table.dart';
import 'package:gym_flutter/core/database/tables/cached_last_performances_table.dart';
import 'package:gym_flutter/core/database/tables/cached_routine_days_table.dart';
import 'package:gym_flutter/core/database/tables/cached_routine_exercises_table.dart';
import 'package:gym_flutter/core/database/tables/cached_set_logs_table.dart';
import 'package:gym_flutter/core/database/tables/cached_weekly_insights_table.dart';
import 'package:gym_flutter/core/database/tables/cached_workout_sessions_table.dart';
import 'package:gym_flutter/core/database/tables/pending_mutations_table.dart';

part 'local_database.g.dart';

/// Base de datos local de la app (SQLite, vía drift).
///
/// Phase 0 introdujo [`AppMeta`] como bookkeeping del esquema. Phase 1
/// añadió el espejo read-only del día activo. Phase 2 incorpora el
/// write-path local-first:
/// - [`CachedWorkoutSessions`] / [`CachedSetLogs`]: espejo escribible de
///   las sesiones del usuario (con `sync_status`).
/// - [`PendingMutations`]: outbox FIFO que el SyncWorker drena con backoff.
///
/// Phase 4 (SWR polish) añade:
/// - [`CachedAssignedRoutines`]: lista de rutinas asignadas al usuario.
/// - [`CachedWeeklyInsights`]: snapshots de la dashboard por (rutina, semana).
///
/// Cada fase actualiza [`schemaVersion`] y registra la migración en
/// [`buildMigrationStrategy`].
@DriftDatabase(
  tables: [
    AppMeta,
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
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase._(super.e);

  /// Abre la BD de producción usando el executor de la plataforma actual.
  factory LocalDatabase.open() => LocalDatabase._(openConnection());

  /// Punto de entrada para tests: inyecta el executor (típicamente
  /// `NativeDatabase.memory()`).
  factory LocalDatabase.forTesting(QueryExecutor e) => LocalDatabase._(e);

  @override
  int get schemaVersion => 4;

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
