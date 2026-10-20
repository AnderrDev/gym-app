import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import 'package:gym_flutter/core/sync/outbox_repository.dart';
import 'package:gym_flutter/features/workout/data/models/set_log_model.dart';
import 'package:gym_flutter/features/workout/data/models/workout_session_model.dart';
import 'package:gym_flutter/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';

import '../../../../helpers/mocks.dart';

/// Write-path online-first: cuando hay red (default en simulador), las
/// escrituras van directo al remoto y refrescan el cache. Sólo cuando
/// `connectivity.isOnline = false` caen al outbox para diferir el push.
/// Esto fija el bug donde set_log POSTs no salían "ahí mismo" en iOS
/// porque el SyncWorker se atascaba con backoffs / auth-pause.
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
    registerFallbackValue(
      const SetLogModel(
        sessionId: 's',
        exerciseId: 'e',
        actualWeight: 0,
        actualReps: 0,
        setIndex: 0,
      ),
    );
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
    when(
      () => local.markSessionCompleted(any(), any()),
    ).thenAnswer((_) async {});
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
    test(
      'online: escribe directo al remoto + refresca cache, NO encola',
      () async {
        when(() => remote.startWorkoutForDay(any(), any(), any())).thenAnswer(
          (_) async => WorkoutSessionModel(
            id: 'srv-id',
            userId: tUserId,
            routineDayId: tRoutineDayId,
            sessionDate: tSessionDate,
          ),
        );
        final result = await repo.startWorkoutForDay(
          tUserId,
          tRoutineDayId,
          tSessionDate,
        );
        result.fold((l) => fail('expected Right, got $l'), (session) {
          expect(session.id, 'srv-id');
          expect(session.userId, tUserId);
          expect(session.routineDayId, tRoutineDayId);
        });
        verify(() => remote.startWorkoutForDay(any(), any(), any())).called(1);
        verify(() => local.saveCachedSession(any())).called(1);
        verifyNever(() => outbox.enqueue(any(), any()));
        verifyNever(() => worker.kick());
      },
    );

    test('offline: local + outbox, no toca remoto', () async {
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
    test(
      'online: escribe directo al remoto + refresca cache, NO encola',
      () async {
        when(() => remote.saveSetLog(any())).thenAnswer((_) async {});
        const log = SetLog(
          sessionId: 'sess-1',
          exerciseId: 'e1',
          actualWeight: 60,
          actualReps: 10,
          setIndex: 0,
        );
        final result = await repo.saveSetLog(log);
        expect(result.isRight(), isTrue);
        verify(() => remote.saveSetLog(any())).called(1);
        verify(() => local.upsertCachedSetLog(log)).called(1);
        verifyNever(() => outbox.enqueue(any(), any()));
      },
    );

    test('offline: local + outbox, no toca remoto', () async {
      when(() => conn.isOnline).thenReturn(false);
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
    test(
      'online: llama al remoto + marca local completed, NO encola',
      () async {
        when(
          () => remote.finishWorkoutSession(
            any(),
            coachingAnalysis: any(named: 'coachingAnalysis'),
          ),
        ).thenAnswer((_) async {});
        final result = await repo.finishWorkoutSession(
          'sess-1',
          coachingAnalysis: const [
            CoachingAnalysis(exerciseName: 'X', recommendation: 'r'),
          ],
        );
        expect(result.isRight(), isTrue);
        verify(
          () => remote.finishWorkoutSession(
            any(),
            coachingAnalysis: any(named: 'coachingAnalysis'),
          ),
        ).called(1);
        verify(() => local.markSessionCompleted('sess-1', any())).called(1);
        verifyNever(() => outbox.enqueue(any(), any()));
      },
    );

    test('offline: marca local completed + encola finalizeSession', () async {
      when(() => conn.isOnline).thenReturn(false);
      final result = await repo.finishWorkoutSession(
        'sess-1',
        coachingAnalysis: const [
          CoachingAnalysis(exerciseName: 'X', recommendation: 'r'),
        ],
      );
      expect(result.isRight(), isTrue);
      verify(() => local.markSessionCompleted('sess-1', any())).called(1);
      verify(
        () => outbox.enqueue(MutationKind.finalizeSession, any()),
      ).called(1);
      verifyNever(
        () => remote.finishWorkoutSession(
          any(),
          coachingAnalysis: any(named: 'coachingAnalysis'),
        ),
      );
    });
  });

  group('finishWorkoutSession con red caída a mitad', () {
    test(
      'online pero el POST falla por red: encola en vez de fallar',
      () async {
        when(
          () => remote.finishWorkoutSession(
            any(),
            coachingAnalysis: any(named: 'coachingAnalysis'),
          ),
        ).thenThrow(const SocketException('sin salida'));
        final result = await repo.finishWorkoutSession('sess-1');
        expect(result.isRight(), isTrue);
        verify(() => local.markSessionCompleted('sess-1', any())).called(1);
        verify(
          () => outbox.enqueue(MutationKind.finalizeSession, any()),
        ).called(1);
      },
    );

    test('un error que no es de red se propaga y no encola', () async {
      when(
        () => remote.finishWorkoutSession(
          any(),
          coachingAnalysis: any(named: 'coachingAnalysis'),
        ),
      ).thenThrow(Exception('boom'));
      final result = await repo.finishWorkoutSession('sess-1');
      expect(result.isLeft(), isTrue);
      verifyNever(() => outbox.enqueue(any(), any()));
    });
  });

  group('getSessionExercises con fallback al plan cacheado', () {
    const cached = [
      Exercise(
        id: 'e1',
        routineDayId: tRoutineDayId,
        name: 'Press',
        targetMuscle: 'Pecho',
        targetWeight: 60,
        targetReps: 8,
        targetSets: 3,
      ),
    ];

    test('offline: usa el plan del día sin llamar al servidor', () async {
      when(() => conn.isOnline).thenReturn(false);
      when(
        () => local.getExercisesForDay(tRoutineDayId),
      ).thenAnswer((_) async => cached);
      final result = await repo.getSessionExercises(
        'local-id',
        routineDayId: tRoutineDayId,
      );
      expect(result.getOrElse((_) => const []), cached);
      verifyNever(() => remote.getSessionExercises(any()));
    });

    test('online pero el RPC falla por red: usa el plan cacheado', () async {
      when(
        () => remote.getSessionExercises(any()),
      ).thenThrow(const SocketException('timeout'));
      when(
        () => local.getExercisesForDay(tRoutineDayId),
      ).thenAnswer((_) async => cached);
      final result = await repo.getSessionExercises(
        'sess-1',
        routineDayId: tRoutineDayId,
      );
      expect(result.getOrElse((_) => const []), cached);
    });

    test('sin routineDayId no hay fallback', () async {
      when(
        () => remote.getSessionExercises(any()),
      ).thenThrow(const SocketException('timeout'));
      final result = await repo.getSessionExercises('sess-1');
      expect(result.isLeft(), isTrue);
      verifyNever(() => local.getExercisesForDay(any()));
    });
  });

  group('getSessionSetLogs con fallback a la caché local', () {
    const cachedLog = SetLog(
      sessionId: 'sess-1',
      exerciseId: 'e1',
      actualWeight: 60,
      actualReps: 10,
      setIndex: 1,
    );

    test('offline: series guardadas en local', () async {
      when(() => conn.isOnline).thenReturn(false);
      when(
        () => local.getCachedSetLogs('sess-1'),
      ).thenAnswer((_) async => const [cachedLog]);
      final result = await repo.getSessionSetLogs('sess-1');
      expect(result.getOrElse((_) => const []), const [cachedLog]);
      verifyNever(() => remote.getSessionSetLogs(any()));
    });

    test('online pero la red cae: series guardadas en local', () async {
      when(
        () => remote.getSessionSetLogs(any()),
      ).thenThrow(const SocketException('timeout'));
      when(
        () => local.getCachedSetLogs('sess-1'),
      ).thenAnswer((_) async => const [cachedLog]);
      final result = await repo.getSessionSetLogs('sess-1');
      expect(result.getOrElse((_) => const []), const [cachedLog]);
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
      when(() => remote.startWorkoutForDay(any(), any(), any())).thenAnswer(
        (_) async => WorkoutSessionModel(
          id: 'remote-id',
          userId: 'u1',
          routineDayId: 'd1',
          sessionDate: DateTime.utc(2026, 5, 18),
        ),
      );
      await legacyRepo.startWorkoutForDay(tUserId, tRoutineDayId, tSessionDate);
      verify(
        () => remote.startWorkoutForDay(any(), any(), any()),
      ).called(greaterThanOrEqualTo(1));
      verifyNever(() => outbox.enqueue(any(), any()));
    });
  });

  test('online: si la cache local falla tras el remote OK, igual devuelve '
      'Right (best-effort write a cache)', () async {
    when(() => remote.saveSetLog(any())).thenAnswer((_) async {});
    when(
      () => local.upsertCachedSetLog(any()),
    ).thenThrow(const SocketException('disk full'));
    const log = SetLog(
      sessionId: 'sess-1',
      exerciseId: 'e1',
      actualWeight: 60,
      actualReps: 10,
      setIndex: 0,
    );
    final result = await repo.saveSetLog(log);
    expect(result.isRight(), isTrue);
    verify(() => remote.saveSetLog(any())).called(1);
  });
}
