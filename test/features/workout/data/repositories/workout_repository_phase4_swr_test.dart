import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/data/models/routine_model.dart';
import 'package:gym_flutter/features/workout/data/models/workout_session_model.dart';
import 'package:gym_flutter/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

/// Tres métodos pasan a SWR con `offlineFallback` en Phase 4:
///  - getAssignedRoutines
///  - getWeekSessions
///  - getWeeklyInsights
///
/// Para cada uno cubrimos los 6 escenarios SWR:
///  1. online + remote ok + cache vacío → fresh + escribe cache.
///  2. online + remote ok + cache stale → fresh gana.
///  3. online + remote falla (network) + cache con datos → cache.
///  4. online + remote falla (network) + sin cache → offlineFallback (NO error).
///  5. offline + cache con datos → cache.
///  6. offline + sin cache → offlineFallback.
void main() {
  late WorkoutRepositoryImpl repo;
  late MockWorkoutRemoteDataSource remote;
  late MockWorkoutLocalDataSource local;
  late MockConnectivityService conn;

  const tUserId = 'u1';
  const tRoutineId = 'r1';
  final tWeekStart = DateTime.utc(2026, 5, 11);
  final tWeekEnd = DateTime.utc(2026, 5, 17);

  const tRoutineModel = RoutineModel(id: 'r1', name: 'Push', exerciseCount: 4);
  const tRoutineCached = Routine(
    id: 'r-cached',
    name: 'Cached Push',
    exerciseCount: 1,
  );

  final tSessionModel = WorkoutSessionModel(
    id: 's-mon',
    userId: tUserId,
    routineDayId: 'd1',
    sessionDate: tWeekStart,
  );
  final tSessionCached = WorkoutSession(
    id: 's-cached',
    userId: tUserId,
    routineDayId: 'd1',
    sessionDate: tWeekStart,
  );

  final tInsights = WeeklyInsights(
    weekStart: tWeekStart,
    weekEnd: tWeekEnd,
    plannedDays: 5,
    completedDays: 3,
    completedSessions: 3,
    adherenceRate: 0.6,
    totalVolume: 1500,
    previousWeekVolume: 1000,
    volumeTrendPercent: 50,
    personalRecords: 2,
  );
  final tInsightsCached = WeeklyInsights(
    weekStart: tWeekStart,
    weekEnd: tWeekEnd,
    plannedDays: 5,
    completedDays: 1,
    completedSessions: 1,
    adherenceRate: 0.2,
    totalVolume: 500,
    previousWeekVolume: 400,
    volumeTrendPercent: 25,
    personalRecords: 0,
  );

  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026, 1, 1));
    registerFallbackValue(tInsights);
  });

  setUp(() {
    remote = MockWorkoutRemoteDataSource();
    local = MockWorkoutLocalDataSource();
    conn = MockConnectivityService();
    when(() => conn.isOnline).thenReturn(true);

    when(
      () => local.cacheAssignedRoutines(any(), any()),
    ).thenAnswer((_) async {});
    when(() => local.cacheWeekSessions(any(), any())).thenAnswer((_) async {});
    when(
      () => local.cacheWeeklyInsights(
        userId: any(named: 'userId'),
        routineId: any(named: 'routineId'),
        insights: any(named: 'insights'),
      ),
    ).thenAnswer((_) async {});

    repo = WorkoutRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      connectivity: conn,
      currentUserIdResolver: () => tUserId,
    );
  });

  // ─── getAssignedRoutines ──────────────────────────────────────────────

  group('getAssignedRoutines SWR', () {
    test('online + remote ok + cache null → fresh + escribe cache', () async {
      when(
        () => remote.getAssignedRoutines(tUserId),
      ).thenAnswer((_) async => const [tRoutineModel]);
      when(
        () => local.getAssignedRoutines(tUserId),
      ).thenAnswer((_) async => null);

      final result = await repo.getAssignedRoutines(tUserId);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.single.id, 'r1');
      });
      verify(() => local.cacheAssignedRoutines(tUserId, any())).called(1);
    });

    test('online + remote ok + cache stale → fresh gana', () async {
      when(
        () => remote.getAssignedRoutines(tUserId),
      ).thenAnswer((_) async => const [tRoutineModel]);
      when(
        () => local.getAssignedRoutines(tUserId),
      ).thenAnswer((_) async => const [tRoutineCached]);

      final result = await repo.getAssignedRoutines(tUserId);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.single.id, 'r1');
      });
    });

    test('online + remote falla + cache con datos → cache', () async {
      when(
        () => remote.getAssignedRoutines(tUserId),
      ).thenThrow(const SocketException('down'));
      when(
        () => local.getAssignedRoutines(tUserId),
      ).thenAnswer((_) async => const [tRoutineCached]);

      final result = await repo.getAssignedRoutines(tUserId);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.single.id, 'r-cached');
      });
    });

    test('online + remote falla + sin cache → offlineFallback ([])', () async {
      when(
        () => remote.getAssignedRoutines(tUserId),
      ).thenThrow(const SocketException('down'));
      when(
        () => local.getAssignedRoutines(tUserId),
      ).thenAnswer((_) async => null);

      final result = await repo.getAssignedRoutines(tUserId);
      result.fold((l) => fail('expected Right'), (r) => expect(r, isEmpty));
    });

    test('offline + cache con datos → cache, sin tocar remote', () async {
      when(() => conn.isOnline).thenReturn(false);
      when(
        () => local.getAssignedRoutines(tUserId),
      ).thenAnswer((_) async => const [tRoutineCached]);

      final result = await repo.getAssignedRoutines(tUserId);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.single.id, 'r-cached');
      });
      verifyNever(() => remote.getAssignedRoutines(any()));
    });

    test('offline + sin cache → offlineFallback ([])', () async {
      when(() => conn.isOnline).thenReturn(false);
      when(
        () => local.getAssignedRoutines(tUserId),
      ).thenAnswer((_) async => null);

      final result = await repo.getAssignedRoutines(tUserId);
      result.fold((l) => fail('expected Right'), (r) => expect(r, isEmpty));
      verifyNever(() => remote.getAssignedRoutines(any()));
    });
  });

  // ─── getWeekSessions ──────────────────────────────────────────────────

  group('getWeekSessions SWR', () {
    test('online + remote ok + cache vacío → fresh + escribe cache', () async {
      when(
        () => remote.getWeekSessions(tUserId, tWeekStart, tWeekEnd),
      ).thenAnswer((_) async => [tSessionModel]);
      when(
        () => local.getWeekSessions(tUserId, tWeekStart, tWeekEnd),
      ).thenAnswer((_) async => const []);

      final result = await repo.getWeekSessions(tUserId, tWeekStart, tWeekEnd);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.single.id, 's-mon');
      });
      verify(() => local.cacheWeekSessions(tUserId, any())).called(1);
    });

    test('online + remote ok + cache stale → fresh gana', () async {
      when(
        () => remote.getWeekSessions(tUserId, tWeekStart, tWeekEnd),
      ).thenAnswer((_) async => [tSessionModel]);
      when(
        () => local.getWeekSessions(tUserId, tWeekStart, tWeekEnd),
      ).thenAnswer((_) async => [tSessionCached]);

      final result = await repo.getWeekSessions(tUserId, tWeekStart, tWeekEnd);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.single.id, 's-mon');
      });
    });

    test('online + remote falla + cache con datos → cache', () async {
      when(
        () => remote.getWeekSessions(tUserId, tWeekStart, tWeekEnd),
      ).thenThrow(const SocketException('down'));
      when(
        () => local.getWeekSessions(tUserId, tWeekStart, tWeekEnd),
      ).thenAnswer((_) async => [tSessionCached]);

      final result = await repo.getWeekSessions(tUserId, tWeekStart, tWeekEnd);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.single.id, 's-cached');
      });
    });

    test(
      'online + remote falla + cache vacío → offlineFallback ([])',
      () async {
        when(
          () => remote.getWeekSessions(tUserId, tWeekStart, tWeekEnd),
        ).thenThrow(const SocketException('down'));
        when(
          () => local.getWeekSessions(tUserId, tWeekStart, tWeekEnd),
        ).thenAnswer((_) async => const []);

        final result = await repo.getWeekSessions(
          tUserId,
          tWeekStart,
          tWeekEnd,
        );
        result.fold((l) => fail('expected Right'), (r) => expect(r, isEmpty));
      },
    );

    test('offline + cache con datos → cache, sin tocar remote', () async {
      when(() => conn.isOnline).thenReturn(false);
      when(
        () => local.getWeekSessions(tUserId, tWeekStart, tWeekEnd),
      ).thenAnswer((_) async => [tSessionCached]);

      final result = await repo.getWeekSessions(tUserId, tWeekStart, tWeekEnd);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.single.id, 's-cached');
      });
      verifyNever(() => remote.getWeekSessions(any(), any(), any()));
    });

    test('offline + cache vacío → offlineFallback ([])', () async {
      when(() => conn.isOnline).thenReturn(false);
      when(
        () => local.getWeekSessions(tUserId, tWeekStart, tWeekEnd),
      ).thenAnswer((_) async => const []);

      final result = await repo.getWeekSessions(tUserId, tWeekStart, tWeekEnd);
      result.fold((l) => fail('expected Right'), (r) => expect(r, isEmpty));
    });
  });

  // ─── getWeeklyInsights ────────────────────────────────────────────────

  group('getWeeklyInsights SWR', () {
    test('online + remote ok + cache null → fresh + escribe cache', () async {
      when(
        () => remote.getWeeklyInsights(
          routineId: tRoutineId,
          weekStart: tWeekStart,
        ),
      ).thenAnswer((_) async => tInsights);
      when(
        () => local.getWeeklyInsights(tUserId, tRoutineId, tWeekStart),
      ).thenAnswer((_) async => null);

      final result = await repo.getWeeklyInsights(
        routineId: tRoutineId,
        weekStart: tWeekStart,
      );
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.completedDays, 3);
      });
      verify(
        () => local.cacheWeeklyInsights(
          userId: tUserId,
          routineId: tRoutineId,
          insights: any(named: 'insights'),
        ),
      ).called(1);
    });

    test('online + remote ok + cache stale → fresh gana', () async {
      when(
        () => remote.getWeeklyInsights(
          routineId: tRoutineId,
          weekStart: tWeekStart,
        ),
      ).thenAnswer((_) async => tInsights);
      when(
        () => local.getWeeklyInsights(tUserId, tRoutineId, tWeekStart),
      ).thenAnswer((_) async => tInsightsCached);

      final result = await repo.getWeeklyInsights(
        routineId: tRoutineId,
        weekStart: tWeekStart,
      );
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.completedDays, 3);
        expect(r.totalVolume, 1500);
      });
    });

    test('online + remote falla + cache con datos → cache', () async {
      when(
        () => remote.getWeeklyInsights(
          routineId: tRoutineId,
          weekStart: tWeekStart,
        ),
      ).thenThrow(const SocketException('down'));
      when(
        () => local.getWeeklyInsights(tUserId, tRoutineId, tWeekStart),
      ).thenAnswer((_) async => tInsightsCached);

      final result = await repo.getWeeklyInsights(
        routineId: tRoutineId,
        weekStart: tWeekStart,
      );
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.completedDays, 1);
        expect(r.totalVolume, 500);
      });
    });

    test('online + remote falla + cache vacío → offlineFallback '
        '(WeeklyInsights todo a cero)', () async {
      when(
        () => remote.getWeeklyInsights(
          routineId: tRoutineId,
          weekStart: tWeekStart,
        ),
      ).thenThrow(const SocketException('down'));
      when(
        () => local.getWeeklyInsights(tUserId, tRoutineId, tWeekStart),
      ).thenAnswer((_) async => null);

      final result = await repo.getWeeklyInsights(
        routineId: tRoutineId,
        weekStart: tWeekStart,
      );
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.plannedDays, 0);
        expect(r.completedDays, 0);
        expect(r.totalVolume, 0);
        expect(r.adherenceRate, 0);
        expect(r.weekStart, tWeekStart);
        expect(r.weekEnd, tWeekStart.add(const Duration(days: 6)));
      });
    });

    test('offline + cache con datos → cache, sin tocar remote', () async {
      when(() => conn.isOnline).thenReturn(false);
      when(
        () => local.getWeeklyInsights(tUserId, tRoutineId, tWeekStart),
      ).thenAnswer((_) async => tInsightsCached);

      final result = await repo.getWeeklyInsights(
        routineId: tRoutineId,
        weekStart: tWeekStart,
      );
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.completedDays, 1);
      });
      verifyNever(
        () => remote.getWeeklyInsights(
          routineId: any(named: 'routineId'),
          weekStart: any(named: 'weekStart'),
        ),
      );
    });

    test('offline + cache vacío → offlineFallback', () async {
      when(() => conn.isOnline).thenReturn(false);
      when(
        () => local.getWeeklyInsights(tUserId, tRoutineId, tWeekStart),
      ).thenAnswer((_) async => null);

      final result = await repo.getWeeklyInsights(
        routineId: tRoutineId,
        weekStart: tWeekStart,
      );
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.plannedDays, 0);
        expect(r.weekStart, tWeekStart);
      });
    });

    test('sin currentUserId resoluble → salta cache, sólo remote', () async {
      // Repo sin user resoluble.
      final anonymousRepo = WorkoutRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
        connectivity: conn,
        currentUserIdResolver: () => null,
      );
      when(
        () => remote.getWeeklyInsights(
          routineId: tRoutineId,
          weekStart: tWeekStart,
        ),
      ).thenAnswer((_) async => tInsights);

      final result = await anonymousRepo.getWeeklyInsights(
        routineId: tRoutineId,
        weekStart: tWeekStart,
      );
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.completedDays, 3);
      });
      // No debió tocar el cache para lectura ni escritura.
      verifyNever(() => local.getWeeklyInsights(any(), any(), any()));
      verifyNever(
        () => local.cacheWeeklyInsights(
          userId: any(named: 'userId'),
          routineId: any(named: 'routineId'),
          insights: any(named: 'insights'),
        ),
      );
    });
  });
}
