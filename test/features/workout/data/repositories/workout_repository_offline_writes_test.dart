import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import 'package:gym_flutter/core/sync/outbox_repository.dart';
import 'package:gym_flutter/features/workout/data/models/set_log_model.dart';
import 'package:gym_flutter/features/workout/data/models/workout_session_model.dart';
import 'package:gym_flutter/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';

import '../../../../helpers/mocks.dart';

/// Phase 2 write-path local-first: cuando `outbox + localDataSource + uuid`
/// están provistos, los métodos write escriben en local y encolan; nunca
/// llaman al remote directamente desde el camino "happy".
void main() {
  late WorkoutRepositoryImpl repo;
  late MockWorkoutRemoteDataSource remote;
  late MockWorkoutLocalDataSource local;
  late MockConnectivityService conn;
  late MockOutboxRepository outbox;
  late MockSyncWorker worker;
  late Uuid uuid;

  const tUserId = 'u1';
  const tRoutineDayId = 'd1';
  final tSessionDate = DateTime.utc(2026, 5, 18);

  setUpAll(() {
    registerFallbackValue(MutationKind.insertSession);
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(
      WorkoutSession(
        id: 'x',
        userId: 'u',
        routineDayId: 'd',
        sessionDate: DateTime.utc(2026, 1, 1),
      ),
    );
    registerFallbackValue(
      const SetLog(
        sessionId: 's',
        exerciseId: 'e',
        actualWeight: 0,
        actualReps: 0,
        setIndex: 0,
      ),
    );
    registerFallbackValue(DateTime.utc(2026, 1, 1));
    registerFallbackValue(const SetLogModel(
      sessionId: 's',
      exerciseId: 'e',
      actualWeight: 0,
      actualReps: 0,
      setIndex: 0,
    ));
  });

  setUp(() {
    remote = MockWorkoutRemoteDataSource();
    local = MockWorkoutLocalDataSource();
    conn = MockConnectivityService();
    outbox = MockOutboxRepository();
    worker = MockSyncWorker();
    uuid = const Uuid();
    when(() => conn.isOnline).thenReturn(true);
    when(() => local.saveCachedSession(any())).thenAnswer((_) async {});
    when(() => local.upsertCachedSetLog(any())).thenAnswer((_) async {});
    when(() => local.markSessionCompleted(any(), any()))
        .thenAnswer((_) async {});
    when(() => outbox.enqueue(any(), any())).thenAnswer((_) async => 1);
    when(() => worker.kick()).thenAnswer((_) async {});

    repo = WorkoutRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      connectivity: conn,
      outbox: outbox,
      syncWorker: worker,
      uuid: uuid,
      currentUserIdResolver: () => tUserId,
    );
  });

  group('startWorkoutForDay (offline-capable)', () {
    test('online: escribe local + encola, NO llama al remote', () async {
      final result = await repo.startWorkoutForDay(
        tUserId,
        tRoutineDayId,
        tSessionDate,
      );
      result.fold((l) => fail('expected Right, got $l'), (session) {
        expect(session.id, isNotEmpty);
        expect(session.userId, tUserId);
        expect(session.routineDayId, tRoutineDayId);
      });
      verify(() => local.saveCachedSession(any())).called(1);
      verify(() => outbox.enqueue(MutationKind.insertSession, any())).called(1);
      verify(() => worker.kick()).called(1);
      verifyNever(() => remote.startWorkoutForDay(any(), any(), any()));
    });

    test('offline: mismo comportamiento — local + outbox', () async {
      when(() => conn.isOnline).thenReturn(false);
      final result = await repo.startWorkoutForDay(
        tUserId,
        tRoutineDayId,
        tSessionDate,
      );
      result.fold((l) => fail('expected Right'), (session) {
        expect(session.id, isNotEmpty);
      });
      verify(() => local.saveCachedSession(any())).called(1);
      verify(() => outbox.enqueue(MutationKind.insertSession, any())).called(1);
      verifyNever(() => remote.startWorkoutForDay(any(), any(), any()));
    });
  });

  group('saveSetLog (offline-capable)', () {
    test('escribe local + encola sin llamar al remote', () async {
      const log = SetLog(
        sessionId: 'sess-1',
        exerciseId: 'e1',
        actualWeight: 60,
        actualReps: 10,
        setIndex: 0,
      );
      final result = await repo.saveSetLog(log);
      expect(result.isRight(), isTrue);
      verify(() => local.upsertCachedSetLog(log)).called(1);
      verify(() => outbox.enqueue(MutationKind.upsertSetLog, any())).called(1);
      verifyNever(() => remote.saveSetLog(any()));
    });
  });

  group('finishWorkoutSession (offline-capable)', () {
    test('marca local completed + encola finalizeSession', () async {
      final result = await repo.finishWorkoutSession(
        'sess-1',
        coachingAnalysis: const [
          CoachingAnalysis(
            exerciseName: 'X',
            recommendation: 'r',
          ),
        ],
      );
      expect(result.isRight(), isTrue);
      verify(() => local.markSessionCompleted('sess-1', any())).called(1);
      verify(() => outbox.enqueue(MutationKind.finalizeSession, any()))
          .called(1);
      verifyNever(() => remote.finishWorkoutSession(any(),
          coachingAnalysis: any(named: 'coachingAnalysis')));
    });
  });

  group('legacy fallback (sin outbox/uuid)', () {
    test('startWorkoutForDay: cae al remote cuando no hay outbox', () async {
      final legacyRepo = WorkoutRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
        connectivity: conn,
        currentUserIdResolver: () => tUserId,
      );
      when(() => remote.startWorkoutForDay(any(), any(), any()))
          .thenAnswer((_) async => WorkoutSessionModel(
                id: 'remote-id',
                userId: 'u1',
                routineDayId: 'd1',
                sessionDate: DateTime.utc(2026, 5, 18),
              ));
      await legacyRepo.startWorkoutForDay(
        tUserId,
        tRoutineDayId,
        tSessionDate,
      );
      verify(() => remote.startWorkoutForDay(any(), any(), any()))
          .called(greaterThanOrEqualTo(1));
      verifyNever(() => outbox.enqueue(any(), any()));
    });
  });

  test(
      'online + outbox.enqueue lanza → return Left pero local ya escribió '
      '(idempotencia preservada vía PK)', () async {
    when(() => outbox.enqueue(any(), any()))
        .thenThrow(const SocketException('disk full'));
    const log = SetLog(
      sessionId: 'sess-1',
      exerciseId: 'e1',
      actualWeight: 60,
      actualReps: 10,
      setIndex: 0,
    );
    final result = await repo.saveSetLog(log);
    expect(result.isLeft(), isTrue);
    // El write local sí pasó (drift-tx en producción haría rollback; aquí
    // mockeamos sin envolver en una db real). Verificamos el orden esperado.
    verify(() => local.upsertCachedSetLog(log)).called(1);
  });
}
