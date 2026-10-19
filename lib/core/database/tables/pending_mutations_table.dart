import 'package:drift/drift.dart';

/// Outbox de mutaciones pendientes de empujar al backend.
///
/// Cada fila representa una mutación serializable que el SyncWorker drenará
/// en FIFO con backoff exponencial + jitter. `payloadJson` contiene la
/// representación canónica de la mutación (campos de la entidad afectada);
/// el SyncWorker la deserializa según `kind` antes de invocar el remote.
@DataClassName('PendingMutationRow')
class PendingMutations extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Tipo de mutación (string del enum MutationKind). Determina el shape
  /// de `payloadJson` y a qué método del remote llamar.
  TextColumn get kind => text()();

  /// Payload serializado (JSON). Snapshot inmutable: el SyncWorker no
  /// reabre la entidad desde la cache local — usa este blob como contrato.
  TextColumn get payloadJson => text()();

  /// Intentos acumulados. Solo incrementa en fallos retriable (no en pausas
  /// por auth ni en éxitos).
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Último error capturado en formato textual. Solo para diagnóstico /
  /// observabilidad — nunca lo lee la UI.
  TextColumn get lastError => text().nullable()();

  /// Epoch ms (UTC) del último intento (éxito o fallo).
  IntColumn get lastAttemptAt => integer().nullable()();

  /// Epoch ms (UTC) cuándo se encoló.
  IntColumn get createdAt => integer()();

  /// Epoch ms (UTC) — punto a partir del cual la mutación es retomable. La
  /// query de `peekReady` filtra `next_attempt_at IS NULL OR next_attempt_at <= now`.
  IntColumn get nextAttemptAt => integer().nullable()();

  /// Token opaco para señalizar que un worker la está procesando. Se libera
  /// en éxito/fallo y por `releaseStaleLocks` al arrancar.
  TextColumn get lockToken => text().nullable()();
}
