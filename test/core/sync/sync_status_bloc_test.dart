import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/core/sync/outbox_repository.dart';
import 'package:gym_flutter/core/sync/presentation/sync_status_bloc.dart';
import 'package:gym_flutter/core/sync/sync_worker.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockConnectivityService conn;
  late MockOutboxRepository outbox;
  late MockSyncWorker worker;
  late StreamController<bool> onlineCtrl;
  late StreamController<int> pendingCtrl;
  late StreamController<SyncWorkerEvent> eventsCtrl;

  setUp(() {
    conn = MockConnectivityService();
    outbox = MockOutboxRepository();
    worker = MockSyncWorker();
    onlineCtrl = StreamController<bool>.broadcast();
    pendingCtrl = StreamController<int>.broadcast();
    eventsCtrl = StreamController<SyncWorkerEvent>.broadcast();
    when(() => conn.isOnline).thenReturn(true);
    when(() => conn.isOnline$).thenAnswer((_) => onlineCtrl.stream);
    when(() => outbox.watchPendingCount())
        .thenAnswer((_) => pendingCtrl.stream);
    when(() => worker.events$).thenAnswer((_) => eventsCtrl.stream);
  });

  tearDown(() async {
    await onlineCtrl.close();
    await pendingCtrl.close();
    await eventsCtrl.close();
  });

  test('state inicial usa connectivity.isOnline', () {
    when(() => conn.isOnline).thenReturn(false);
    final bloc = SyncStatusBloc(
      connectivity: conn,
      outbox: outbox,
      syncWorker: worker,
    );
    addTearDown(bloc.close);
    expect(bloc.state.isOnline, isFalse);
    expect(bloc.state.pending, 0);
    expect(bloc.state.draining, isFalse);
  });

  blocTest<SyncStatusBloc, SyncStatusState>(
    'reacciona a connectivity online/offline',
    build: () => SyncStatusBloc(
      connectivity: conn,
      outbox: outbox,
      syncWorker: worker,
    ),
    act: (b) async {
      onlineCtrl.add(false);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      onlineCtrl.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    expect: () => [
      const SyncStatusState(isOnline: false, pending: 0, draining: false),
      const SyncStatusState(isOnline: true, pending: 0, draining: false),
    ],
  );

  blocTest<SyncStatusBloc, SyncStatusState>(
    'pending count actualiza tras emisión de outbox',
    build: () => SyncStatusBloc(
      connectivity: conn,
      outbox: outbox,
      syncWorker: worker,
    ),
    act: (b) async {
      pendingCtrl.add(3);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      pendingCtrl.add(0);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    expect: () => [
      const SyncStatusState(isOnline: true, pending: 3, draining: false),
      const SyncStatusState(isOnline: true, pending: 0, draining: false),
    ],
  );

  blocTest<SyncStatusBloc, SyncStatusState>(
    'draining se actualiza por SyncDrainStarted / SyncDrainEnded',
    build: () => SyncStatusBloc(
      connectivity: conn,
      outbox: outbox,
      syncWorker: worker,
    ),
    act: (b) async {
      eventsCtrl.add(const SyncDrainStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      eventsCtrl.add(const SyncDrainEnded(remaining: 0));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    expect: () => [
      const SyncStatusState(isOnline: true, pending: 0, draining: true),
      const SyncStatusState(isOnline: true, pending: 0, draining: false),
    ],
  );

  blocTest<SyncStatusBloc, SyncStatusState>(
    'eventos sin impacto (Applied/Failed) no cambian el state',
    build: () => SyncStatusBloc(
      connectivity: conn,
      outbox: outbox,
      syncWorker: worker,
    ),
    act: (b) async {
      eventsCtrl.add(const SyncMutationApplied(
        kind: MutationKind.upsertSetLog,
        id: 1,
      ));
      eventsCtrl.add(const SyncMutationFailed(
        kind: MutationKind.upsertSetLog,
        id: 2,
        error: 'transient',
        nextAttempt: Duration(seconds: 1),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    },
    expect: () => <SyncStatusState>[],
  );
}
