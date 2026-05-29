import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:gym_flutter/core/error/exceptions.dart' as core_ex;
import 'package:gym_flutter/core/sync/outbox_repository.dart';
import 'package:gym_flutter/core/sync/sync_worker.dart';
import 'package:gym_flutter/core/sync/sync_worker_impl.dart';
import 'package:gym_flutter/features/workout/data/models/set_log_model.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockOutboxRepository outbox;
  late MockWorkoutRemoteDataSource remote;
  late MockWorkoutLocalDataSource local;
  late MockConnectivityService conn;
  late MockAuthRepository auth;
  late StreamController<bool> onlineCtrl;
  late StreamController<bool> authCtrl;
  late Random fixedRandom;

  PendingMutation pending({
    int id = 1,
    MutationKind kind = MutationKind.upsertSetLog,
    Map<String, dynamic>? payload,
    int attempts = 0,
  }) =>
      PendingMutation(
        id: id,
        kind: kind,
        payload: payload ??
            {
              'session_id': 'sess-1',
              'exercise_id': 'e1',
              'actual_weight': 60,
              'actual_reps': 10,
              'set_index': 0,
            },
        attempts: attempts,
        createdAt: DateTime.utc(2026, 5, 18),
      );

  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026, 1, 1));
    registerFallbackValue(Duration.zero);
    registerFallbackValue(const SetLogModel(
      sessionId: 's',
      exerciseId: 'e',
      actualWeight: 0,
      actualReps: 0,
      setIndex: 0,
    ));
  });

  setUp(() {
    outbox = MockOutboxRepository();
    remote = MockWorkoutRemoteDataSource();
    local = MockWorkoutLocalDataSource();
    conn = MockConnectivityService();
    auth = MockAuthRepository();
    onlineCtrl = StreamController<bool>.broadcast();
    authCtrl = StreamController<bool>.broadcast();
    fixedRandom = Random(42);

    when(() => conn.isOnline).thenReturn(true);
    when(() => conn.isOnline$).thenAnswer((_) => onlineCtrl.stream);
    when(() => auth.authStateChanges).thenAnswer((_) => authCtrl.stream);
    when(() => outbox.releaseStaleLocks(any())).thenAnswer((_) async {});
    when(() => outbox.pendingCount()).thenAnswer((_) async => 0);
    when(() => outbox.tryClaim(any(), any())).thenAnswer((_) async => true);
    when(() => outbox.markSuccess(any())).thenAnswer((_) async {});
    when(() => outbox.markFailure(any(), any(), any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await onlineCtrl.close();
    await authCtrl.close();
  });

  SyncWorkerImpl buildWorker() => SyncWorkerImpl(
        outbox: outbox,
        remote: remote,
        local: local,
        connectivity: conn,
        authRepository: auth,
        clock: fakeClockAt(DateTime.utc(2026, 5, 18, 12)),
        random: fixedRandom,
      );

  group('drain FIFO', () {
    test('procesa varias mutaciones en orden hasta vaciar', () async {
      final events = <SyncWorkerEvent>[];
      final m1 = pending(id: 1);
      final m2 = pending(id: 2);
      var callCount = 0;
      when(() => outbox.peekReady(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return [m1];
        if (callCount == 2) return [m2];
        return [];
      });
      when(() => remote.saveSetLog(any())).thenAnswer((_) async {});

      final worker = buildWorker();
      worker.events$.listen(events.add);
      worker.start();
      await worker.drain();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      verify(() => remote.saveSetLog(any())).called(2);
      expect(events.whereType<SyncMutationApplied>().length, 2);
      await worker.stop();
    });

    test('saveSetLog OK → markSuccess + Applied event', () async {
      final m = pending();
      var first = true;
      when(() => outbox.peekReady(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async {
        if (first) {
          first = false;
          return [m];
        }
        return [];
      });
      when(() => remote.saveSetLog(any())).thenAnswer((_) async {});

      final events = <SyncWorkerEvent>[];
      final worker = buildWorker();
      worker.events$.listen(events.add);
      worker.start();
      await worker.drain();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      verify(() => remote.saveSetLog(any())).called(1);
      verify(() => outbox.markSuccess(m.id)).called(1);
      expect(events.whereType<SyncMutationApplied>().length, 1);
      await worker.stop();
    });
  });

  group('errores no-recuperables → drop', () {
    test('PostgrestException 23505 en insertSession → drop superseded',
        () async {
      final m = pending(
        id: 7,
        kind: MutationKind.insertSession,
        payload: {
          'user_id': 'u1',
          'routine_day_id': 'd1',
          'session_date': '2026-05-18',
        },
      );
      var first = true;
      when(() => outbox.peekReady(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async {
        if (first) {
          first = false;
          return [m];
        }
        return [];
      });
      when(() => remote.startWorkoutForDay(any(), any(), any())).thenThrow(
        const supabase.PostgrestException(
          message: 'duplicate key',
          code: '23505',
        ),
      );

      final events = <SyncWorkerEvent>[];
      final worker = buildWorker();
      worker.events$.listen(events.add);
      worker.start();
      await worker.drain();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      verify(() => outbox.markSuccess(7)).called(1);
      final drops = events.whereType<SyncMutationDropped>();
      expect(drops.length, 1);
      expect(drops.first.reason, 'session_superseded');
      await worker.stop();
    });

    test('WorkoutFunctionException VALIDATION_ERROR → drop validation',
        () async {
      final m = pending(id: 9, kind: MutationKind.finalizeSession, payload: {
        'session_id': 'sess-1',
        'coaching_analysis': null,
      });
      var first = true;
      when(() => outbox.peekReady(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async {
        if (first) {
          first = false;
          return [m];
        }
        return [];
      });
      when(() => remote.finishWorkoutSession(any(),
              coachingAnalysis: any(named: 'coachingAnalysis')))
          .thenThrow(const core_ex.WorkoutFunctionException(
        code: 'VALIDATION_ERROR',
        userMessage: 'bad',
      ));

      final events = <SyncWorkerEvent>[];
      final worker = buildWorker();
      worker.events$.listen(events.add);
      worker.start();
      await worker.drain();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      verify(() => outbox.markSuccess(9)).called(1);
      final drops = events.whereType<SyncMutationDropped>().toList();
      expect(drops.length, 1);
      expect(drops.first.reason, 'validation_failed');
      await worker.stop();
    });
  });

  group('pausa por auth', () {
    test('UNAUTHORIZED → emite SyncAuthPaused y NO incrementa attempts',
        () async {
      final m = pending(id: 11, kind: MutationKind.upsertSetLog);
      var first = true;
      when(() => outbox.peekReady(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async {
        if (first) {
          first = false;
          return [m];
        }
        return [];
      });
      when(() => remote.saveSetLog(any())).thenThrow(
        const supabase.AuthException('jwt expired'),
      );

      final events = <SyncWorkerEvent>[];
      final worker = buildWorker();
      worker.events$.listen(events.add);
      worker.start();
      await worker.drain();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(events.whereType<SyncAuthPaused>().length, 1);
      // Verificamos que NO se llamó markSuccess y SÍ markFailure con
      // nextAttempt = ahora (no penaliza).
      verifyNever(() => outbox.markSuccess(11));
      verify(() => outbox.markFailure(11, any(that: contains('auth')), any()))
          .called(1);

      // Reanuda al recibir authStateChanges(true).
      authCtrl.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await worker.stop();
    });
  });

  group('backoff', () {
    test('failure transient agenda con backoff dentro de rango', () async {
      final m = pending(id: 21, kind: MutationKind.upsertSetLog, attempts: 1);
      var first = true;
      when(() => outbox.peekReady(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async {
        if (first) {
          first = false;
          return [m];
        }
        return [];
      });
      when(() => remote.saveSetLog(any()))
          .thenThrow(Exception('transient down'));

      final events = <SyncWorkerEvent>[];
      final worker = buildWorker();
      worker.events$.listen(events.add);
      worker.start();
      await worker.drain();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final failed = events.whereType<SyncMutationFailed>();
      expect(failed.length, 1);
      // attempts=1 → base=2s, jitter 80..120% → ms entre 1600 y 2400.
      final delay = failed.first.nextAttempt.inMilliseconds;
      expect(delay, greaterThanOrEqualTo(1600));
      expect(delay, lessThanOrEqualTo(2400));
      await worker.stop();
    });
  });

  group('bootstrap', () {
    test('start() llama releaseStaleLocks', () async {
      final worker = buildWorker();
      worker.start();
      // Espera el microtask del bootstrap.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      verify(() => outbox.releaseStaleLocks(any())).called(1);
      await worker.stop();
    });

    test('kick es no-op cuando offline', () async {
      when(() => conn.isOnline).thenReturn(false);
      when(() => outbox.peekReady(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => []);
      final worker = buildWorker();
      worker.start();
      await worker.kick();
      verifyNever(() => outbox.peekReady(any(), limit: any(named: 'limit')));
      await worker.stop();
    });
  });
}

