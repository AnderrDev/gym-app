import 'package:gym_flutter/core/sync/outbox_repository.dart';

/// Eventos emitidos por el [`SyncWorker`] para observabilidad y UI (badge).
sealed class SyncWorkerEvent {
  const SyncWorkerEvent();
}

/// El worker comenzó un drain (uno o más items listos).
class SyncDrainStarted extends SyncWorkerEvent {
  const SyncDrainStarted();
}

/// Una mutación se aplicó correctamente y se removió de la outbox.
class SyncMutationApplied extends SyncWorkerEvent {
  const SyncMutationApplied({required this.kind, required this.id});
  final MutationKind kind;
  final int id;
}

/// Una mutación se descartó por un error no-recuperable (4xx, conflicto,
/// dato inválido). La fila se elimina como en el caso éxito pero la app
/// puede mostrar feedback en base a la razón.
class SyncMutationDropped extends SyncWorkerEvent {
  const SyncMutationDropped({
    required this.kind,
    required this.id,
    required this.reason,
  });
  final MutationKind kind;
  final int id;
  final String reason;
}

/// Una mutación falló de forma retriable. La fila quedó reagendada con
/// `next_attempt_at` aplicado.
class SyncMutationFailed extends SyncWorkerEvent {
  const SyncMutationFailed({
    required this.kind,
    required this.id,
    required this.error,
    required this.nextAttempt,
  });
  final MutationKind kind;
  final int id;
  final String error;
  final Duration nextAttempt;
}

/// El drain se pausó porque el remote devolvió un error de autenticación.
/// El worker reanudará cuando AuthRepository.authStateChanges emita `true`.
class SyncAuthPaused extends SyncWorkerEvent {
  const SyncAuthPaused();
}

/// El drain terminó (con o sin éxito). [remaining] = items aún pendientes.
class SyncDrainEnded extends SyncWorkerEvent {
  const SyncDrainEnded({required this.remaining});
  final int remaining;
}

/// API del worker. Single-flight: si ya está draining, [`kick`] / [`drain`]
/// son no-ops; el caller no necesita cuidarse de concurrencia.
abstract class SyncWorker {
  /// Arranca el worker: suscripciones a connectivity + auth, release de
  /// locks viejos, drain inicial si aplica. Idempotente — múltiples llamadas
  /// equivalen a una.
  void start();

  /// Pide un drain "ya". Si el worker está offline, en pausa por auth o
  /// ya draining, no hace nada.
  Future<void> kick();

  /// Drena la outbox de forma greedy: procesa items hasta vaciar o hasta
  /// que un fallo bloquee. Devuelve cuando ya no hay items procesables.
  Future<void> drain();

  /// Cancela suscripciones y libera recursos.
  Future<void> stop();

  /// Stream broadcast de eventos para UI / tests.
  Stream<SyncWorkerEvent> get events$;
}
