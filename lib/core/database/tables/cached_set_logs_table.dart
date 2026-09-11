import 'package:drift/drift.dart';

/// Cache local de `set_logs`. Phase 2 escribe primero aquí (sync_status =
/// 'pending') y la outbox sincroniza al backend más tarde.
///
/// PK compuesta `(sessionId, exerciseId, setIndex)` que es la misma
/// unique constraint que usa el backend para upsert.
@DataClassName('CachedSetLogRow')
class CachedSetLogs extends Table {
  TextColumn get sessionId => text()();
  TextColumn get exerciseId => text()();
  IntColumn get setIndex => integer()();
  RealColumn get actualWeight => real()();
  IntColumn get actualReps => integer()();

  /// Epoch ms (UTC) — cuándo se registró el set localmente.
  IntColumn get createdAt => integer()();

  /// Id remoto asignado tras el primer upsert exitoso (cuando el backend lo
  /// devuelve). Hasta entonces el log se identifica solo por la PK compuesta.
  TextColumn get remoteId => text().nullable()();

  /// Estado de sincronización: `pending`, `syncing`, `synced`, `error`.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  /// Epoch ms (UTC) del último write local.
  IntColumn get fetchedAt => integer()();

  @override
  Set<Column> get primaryKey => {sessionId, exerciseId, setIndex};
}
