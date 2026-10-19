import 'package:flutter_test/flutter_test.dart';

import 'package:gym_flutter/core/sync/outbox_repository.dart';
import 'package:gym_flutter/core/sync/outbox_repository_impl.dart';

import '../../helpers/database_test_helper.dart';

/// Tests sobre la implementación de [`OutboxRepository`] (drift in-memory).
///
/// Cubre las primitivas que el SyncWorker consume:
///   - enqueue / peekReady FIFO + filtro temporal
///   - tryClaim atómico
///   - markSuccess elimina la fila
///   - markFailure incrementa attempts + reagenda
///   - watchPendingCount emite tras cada cambio
///   - releaseStaleLocks libera locks antiguos
///   - purgeAll deja la outbox vacía
void main() {
  late OutboxRepositoryImpl outbox;

  setUp(() {
    final db = openInMemoryDb();
    addTearDown(() async => db.close());
    outbox = OutboxRepositoryImpl(db);
  });

  test('enqueue persiste la mutación con kind y payload', () async {
    final id = await outbox.enqueue(MutationKind.insertSession, {
      'user_id': 'u1',
      'routine_day_id': 'd1',
      'session_date': '2026-05-18',
    });
    expect(id, isPositive);
    final pending = await outbox.peekReady(DateTime.now(), limit: 10);
    expect(pending.length, 1);
    expect(pending.first.kind, MutationKind.insertSession);
    expect(pending.first.payload['user_id'], 'u1');
  });

  test('peekReady devuelve FIFO por id ascendente', () async {
    await outbox.enqueue(MutationKind.insertSession, {'a': 1});
    await outbox.enqueue(MutationKind.upsertSetLog, {'b': 2});
    await outbox.enqueue(MutationKind.finalizeSession, {'c': 3});

    final batch = await outbox.peekReady(DateTime.now(), limit: 10);
    expect(batch.map((m) => m.kind), [
      MutationKind.insertSession,
      MutationKind.upsertSetLog,
      MutationKind.finalizeSession,
    ]);
  });

  test('peekReady excluye filas con next_attempt_at en el futuro', () async {
    final id = await outbox.enqueue(MutationKind.upsertSetLog, {
      'session_id': 's1',
    });
    final batch = await outbox.peekReady(DateTime.now(), limit: 1);
    expect(batch.first.id, id);
    await outbox.markFailure(
      id,
      'transient',
      DateTime.now().add(const Duration(minutes: 5)),
    );
    final later = await outbox.peekReady(DateTime.now(), limit: 1);
    expect(
      later,
      isEmpty,
      reason: 'filas con next_attempt_at futuro no son retomables',
    );

    final ahead = await outbox.peekReady(
      DateTime.now().add(const Duration(minutes: 6)),
      limit: 1,
    );
    expect(
      ahead,
      isNotEmpty,
      reason: 'cuando llega el tiempo agendado vuelve a aparecer',
    );
  });

  test('peekReady excluye filas con lock_token', () async {
    final id = await outbox.enqueue(MutationKind.upsertSetLog, {'x': 1});
    final claimed = await outbox.tryClaim(id, 'worker-1');
    expect(claimed, isTrue);
    final batch = await outbox.peekReady(DateTime.now(), limit: 10);
    expect(batch, isEmpty);
  });

  test('tryClaim es atómico: segunda llamada falla', () async {
    final id = await outbox.enqueue(MutationKind.upsertSetLog, {});
    final first = await outbox.tryClaim(id, 'worker-a');
    final second = await outbox.tryClaim(id, 'worker-b');
    expect(first, isTrue);
    expect(second, isFalse);
  });

  test('markSuccess elimina la fila y queda count=0', () async {
    final id = await outbox.enqueue(MutationKind.upsertSetLog, {'k': 'v'});
    expect(await outbox.pendingCount(), 1);
    await outbox.markSuccess(id);
    expect(await outbox.pendingCount(), 0);
  });

  test('markFailure incrementa attempts y reagenda', () async {
    final id = await outbox.enqueue(MutationKind.upsertSetLog, {});
    final firstBatch = await outbox.peekReady(DateTime.now(), limit: 1);
    expect(firstBatch.first.attempts, 0);

    await outbox.markFailure(
      id,
      'network down',
      DateTime.now().subtract(const Duration(seconds: 1)),
    );
    final retry = await outbox.peekReady(DateTime.now(), limit: 1);
    expect(retry.first.attempts, 1);
    expect(retry.first.lockToken, isNull);

    await outbox.markFailure(
      id,
      'still down',
      DateTime.now().subtract(const Duration(seconds: 1)),
    );
    final third = await outbox.peekReady(DateTime.now(), limit: 1);
    expect(third.first.attempts, 2);
  });

  test('watchPendingCount emite tras cada cambio', () async {
    final stream = outbox.watchPendingCount();
    final emissions = <int>[];
    final sub = stream.listen(emissions.add);

    // Primera lectura inmediata.
    await Future<void>.delayed(Duration.zero);

    final id = await outbox.enqueue(MutationKind.upsertSetLog, {});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await outbox.enqueue(MutationKind.upsertSetLog, {});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await outbox.markSuccess(id);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await sub.cancel();
    expect(emissions, isNotEmpty);
    expect(emissions.last, 1);
    expect(emissions, contains(0));
    expect(emissions, contains(2));
  });

  test('releaseStaleLocks libera locks con last_attempt_at antiguo', () async {
    final id = await outbox.enqueue(MutationKind.upsertSetLog, {});
    final claimed = await outbox.tryClaim(id, 'crashed-worker');
    expect(claimed, isTrue);
    // Forzamos last_attempt_at antiguo simulando un fallo previo: hacemos
    // markFailure y luego volvemos a claim. Para el caso "crashed pre-mark"
    // last_attempt_at queda null → debe liberarse de cualquier modo.
    final batch0 = await outbox.peekReady(DateTime.now(), limit: 1);
    expect(batch0, isEmpty, reason: 'el lock impide retomarla');

    await outbox.releaseStaleLocks(const Duration(milliseconds: 1));
    final batch1 = await outbox.peekReady(DateTime.now(), limit: 1);
    expect(batch1.length, 1, reason: 'el lock se liberó');
  });

  test('purgeAll deja la outbox vacía', () async {
    await outbox.enqueue(MutationKind.upsertSetLog, {});
    await outbox.enqueue(MutationKind.upsertSetLog, {});
    await outbox.purgeAll();
    expect(await outbox.pendingCount(), 0);
  });
}
