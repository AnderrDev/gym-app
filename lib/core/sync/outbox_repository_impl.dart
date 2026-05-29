import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:gym_flutter/core/database/local_database.dart';
import 'package:gym_flutter/core/sync/outbox_repository.dart';

/// Implementación de [`OutboxRepository`] sobre [`LocalDatabase`].
///
/// Sólo expone operaciones primitivas; ni el backoff ni la decisión de
/// kick drain viven aquí — los maneja el SyncWorker.
class OutboxRepositoryImpl implements OutboxRepository {
  OutboxRepositoryImpl(this._db);

  final LocalDatabase _db;

  int _nowMs() => DateTime.now().toUtc().millisecondsSinceEpoch;

  @override
  Future<int> enqueue(MutationKind kind, Map<String, dynamic> payload) {
    final now = _nowMs();
    return _db.into(_db.pendingMutations).insert(
          PendingMutationsCompanion.insert(
            kind: kind.toWire(),
            payloadJson: jsonEncode(payload),
            createdAt: now,
            nextAttemptAt: Value(now),
          ),
        );
  }

  @override
  Future<List<PendingMutation>> peekReady(
    DateTime now, {
    int limit = 1,
  }) async {
    final nowMs = now.toUtc().millisecondsSinceEpoch;
    final query = _db.select(_db.pendingMutations)
      ..where(
        (t) =>
            t.lockToken.isNull() &
            (t.nextAttemptAt.isNull() |
                t.nextAttemptAt.isSmallerOrEqualValue(nowMs)),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.id)])
      ..limit(limit);
    final rows = await query.get();
    return rows.map(_rowToPending).toList(growable: false);
  }

  @override
  Future<bool> tryClaim(int id, String lockToken) async {
    final affected = await (_db.update(_db.pendingMutations)
          ..where((t) => t.id.equals(id) & t.lockToken.isNull()))
        .write(PendingMutationsCompanion(lockToken: Value(lockToken)));
    return affected > 0;
  }

  @override
  Future<void> markSuccess(int id) async {
    await (_db.delete(_db.pendingMutations)..where((t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> markFailure(
    int id,
    String error,
    DateTime nextAttempt,
  ) async {
    // Leemos primero el row para incrementar attempts (drift no expone
    // `column = column + 1` con seguridad de tipos en update genérico, así
    // que hacemos read-modify-write).
    final row = await (_db.select(_db.pendingMutations)
          ..where((t) => t.id.equals(id))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return;
    await (_db.update(_db.pendingMutations)..where((t) => t.id.equals(id)))
        .write(
      PendingMutationsCompanion(
        attempts: Value(row.attempts + 1),
        lastError: Value(error),
        lastAttemptAt: Value(_nowMs()),
        nextAttemptAt: Value(
          nextAttempt.toUtc().millisecondsSinceEpoch,
        ),
        lockToken: const Value(null),
      ),
    );
  }

  @override
  Future<void> releaseStaleLocks(Duration olderThan) async {
    final thresholdMs =
        _nowMs() - olderThan.inMilliseconds;
    await (_db.update(_db.pendingMutations)
          ..where(
            (t) =>
                t.lockToken.isNotNull() &
                (t.lastAttemptAt.isNull() |
                    t.lastAttemptAt.isSmallerThanValue(thresholdMs)),
          ))
        .write(const PendingMutationsCompanion(lockToken: Value(null)));
  }

  @override
  Future<int> pendingCount() async {
    final count = _db.pendingMutations.id.count();
    final row = await (_db.selectOnly(_db.pendingMutations)
          ..addColumns([count]))
        .getSingle();
    return row.read(count) ?? 0;
  }

  @override
  Stream<int> watchPendingCount() {
    final count = _db.pendingMutations.id.count();
    final query = _db.selectOnly(_db.pendingMutations)..addColumns([count]);
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  @override
  Future<void> purgeAll() async {
    await _db.delete(_db.pendingMutations).go();
  }

  PendingMutation _rowToPending(PendingMutationRow r) {
    final decoded = jsonDecode(r.payloadJson);
    final payload = decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded as Map);
    return PendingMutation(
      id: r.id,
      kind: MutationKind.fromWire(r.kind),
      payload: payload,
      attempts: r.attempts,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt, isUtc: true),
      nextAttemptAt: r.nextAttemptAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(r.nextAttemptAt!, isUtc: true),
      lockToken: r.lockToken,
    );
  }
}
