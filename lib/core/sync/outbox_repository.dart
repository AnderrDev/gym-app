// Outbox FIFO de mutaciones pendientes. La interfaz vive desacoplada del
// storage para que tests puedan mockear sin tocar drift.
//
// Phase 2 — write-path local-first. El repositorio escribe local primero
// y encola aquí; el SyncWorker drena con backoff exponencial + jitter.

/// Tipos de mutación soportados. El SyncWorker hace switch sobre este enum
/// para decidir a qué método del remote llamar.
enum MutationKind {
  /// Insert de una nueva `workout_session` (start workout).
  insertSession,

  /// Upsert de un `set_log` por `(sessionId, exerciseId, setIndex)`.
  upsertSetLog,

  /// Borrado de un `set_log` por `(sessionId, exerciseId, setIndex)` — el
  /// usuario desmarcó una serie. Va por outbox (y no directo al remote) para
  /// respetar el orden FIFO respecto del `upsertSetLog` del mismo set.
  deleteSetLog,

  /// Finalize de la sesión (cierra `completed_at` + dispara coaching).
  finalizeSession;

  /// Representación textual estable para persistir en `pending_mutations.kind`.
  String toWire() => name;

  /// Inversa: lanza si el string no matchea ningún enum.
  static MutationKind fromWire(String s) =>
      values.firstWhere((e) => e.name == s);
}

/// Snapshot inmutable de una mutación pendiente.
class PendingMutation {
  const PendingMutation({
    required this.id,
    required this.kind,
    required this.payload,
    required this.attempts,
    required this.createdAt,
    this.nextAttemptAt,
    this.lockToken,
  });

  /// PK autoincrement de `pending_mutations`. Estable durante el ciclo de
  /// vida de la fila.
  final int id;
  final MutationKind kind;

  /// Payload deserializado. El productor (repository) inyecta un map
  /// JSON-safe; el dispatcher del worker lo reabre según `kind`.
  final Map<String, dynamic> payload;

  /// Intentos acumulados (no incluye la pausa por auth).
  final int attempts;

  final DateTime createdAt;

  /// Si está en el futuro, la fila no es retornada por `peekReady`.
  final DateTime? nextAttemptAt;

  /// Si no es null, otro worker la está procesando (lock).
  final String? lockToken;
}

abstract class OutboxRepository {
  /// Encola una nueva mutación. Devuelve el id autoasignado.
  Future<int> enqueue(MutationKind kind, Map<String, dynamic> payload);

  /// Devuelve hasta `limit` mutaciones listas para procesar:
  /// - sin lock (`lock_token IS NULL`)
  /// - retomables ahora (`next_attempt_at IS NULL OR next_attempt_at <= now`)
  /// - ordenadas por `id ASC` (FIFO).
  Future<List<PendingMutation>> peekReady(DateTime now, {int limit = 1});

  /// Intenta tomar el lock atómicamente. `true` si la fila estaba libre y
  /// quedó marcada con `lockToken`; `false` si otro worker se adelantó.
  Future<bool> tryClaim(int id, String lockToken);

  /// Elimina la fila tras una mutación exitosa.
  Future<void> markSuccess(int id);

  /// Incrementa `attempts`, persiste el último error y reagenda con
  /// `next_attempt_at = nextAttempt`. Libera el lock.
  Future<void> markFailure(int id, String error, DateTime nextAttempt);

  /// Libera locks tomados hace más de [olderThan] (caso de crash entre
  /// claim y mark). Debe llamarse al arrancar el SyncWorker.
  Future<void> releaseStaleLocks(Duration olderThan);

  /// Conteo síncrono de mutaciones pendientes (para badge de UI inicial).
  Future<int> pendingCount();

  /// Stream con el count actualizado tras cada cambio (insert / delete /
  /// update). Lo consume el SyncStatusBloc.
  Stream<int> watchPendingCount();

  /// Borra todas las filas. Solo se usa en tests / logout total.
  Future<void> purgeAll();
}
