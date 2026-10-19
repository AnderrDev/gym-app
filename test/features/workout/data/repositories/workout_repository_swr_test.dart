import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/data/models/exercise_model.dart';
import 'package:gym_flutter/features/workout/data/models/routine_day_model.dart';
import 'package:gym_flutter/features/workout/data/models/set_log_model.dart';
import 'package:gym_flutter/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

/// Tres métodos están en SWR:
///  - getRoutineDays
///  - getExercisesForDay
///  - getLastExercisePerformances
///
/// Para cada uno cubrimos los 6 escenarios:
///  1. online + remote ok + cache vacío → escribe cache + devuelve fresh.
///  2. online + remote ok + cache ya tenía datos → fresh sobrescribe.
///  3. online + remote falla + cache con datos → devuelve cache.
///  4. online + remote falla + cache vacío → Left(failure) propagado.
///  5. offline + cache con datos → devuelve cache (no llama remote).
///  6. offline + cache vacío → NetworkFailure.
void main() {
  late WorkoutRepositoryImpl repo;
  late MockWorkoutRemoteDataSource remote;
  late MockWorkoutLocalDataSource local;
  late MockConnectivityService conn;

  const tUserId = 'u1';
  const tRoutineId = 'r1';
  const tDayId = 'd1';

  const tDay = RoutineDay(
    id: tDayId,
    routineId: tRoutineId,
    dayOfWeek: 1,
    name: 'Lunes',
  );
  const tDayModel = RoutineDayModel(
    id: tDayId,
    routineId: tRoutineId,
    dayOfWeek: 1,
    name: 'Lunes',
  );

  const tExercise = Exercise(
    id: 'e1',
    routineDayId: tDayId,
    name: 'Press Banca',
    targetMuscle: 'pecho',
    targetWeight: 60.0,
    targetReps: 10,
  );
  const tExerciseModel = ExerciseModel(
    id: 'e1',
    routineDayId: tDayId,
    name: 'Press Banca',
    targetMuscle: 'pecho',
    targetWeight: 60.0,
    targetReps: 10,
  );

  const tSetLogModel = SetLogModel(
    id: 'sl-1',
    sessionId: 's1',
    exerciseId: 'e1',
    actualWeight: 60.0,
    actualReps: 10,
    setIndex: 0,
  );
  const tSetLogCached = SetLog(
    id: 'sl-cached',
    sessionId: 's0',
    exerciseId: 'e1',
    actualWeight: 50.0,
    actualReps: 8,
    setIndex: 0,
  );

  setUp(() {
    remote = MockWorkoutRemoteDataSource();
    local = MockWorkoutLocalDataSource();
    conn = MockConnectivityService();
    when(() => conn.isOnline).thenReturn(true);

    when(() => local.cacheRoutineDays(any(), any())).thenAnswer((_) async {});
    when(
      () => local.cacheExercisesForDay(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => local.cacheLastPerformances(any(), any()),
    ).thenAnswer((_) async {});

    repo = WorkoutRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      connectivity: conn,
      currentUserIdResolver: () => tUserId,
    );
  });

  // ─── getRoutineDays ───────────────────────────────────────────────────

  group('getRoutineDays SWR', () {
    test('online + remote ok → devuelve fresh y escribe cache', () async {
      when(
        () => remote.getRoutineDays(tRoutineId),
      ).thenAnswer((_) async => const [tDayModel]);
      when(
        () => local.getRoutineDays(tRoutineId),
      ).thenAnswer((_) async => const []);

      final result = await repo.getRoutineDays(tRoutineId);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.length, 1);
        expect(r.first.id, tDayId);
      });
      verify(() => local.cacheRoutineDays(tRoutineId, any())).called(1);
    });

    test('online + remote ok + cache ya tenía datos → fresh gana', () async {
      const cached = RoutineDay(
        id: 'stale',
        routineId: tRoutineId,
        dayOfWeek: 1,
        name: 'Stale',
      );
      when(
        () => remote.getRoutineDays(tRoutineId),
      ).thenAnswer((_) async => const [tDayModel]);
      when(
        () => local.getRoutineDays(tRoutineId),
      ).thenAnswer((_) async => const [cached]);

      final result = await repo.getRoutineDays(tRoutineId);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.map((d) => d.id), [tDayId]);
      });
    });

    test('online + remote falla + cache con datos → devuelve cache', () async {
      when(
        () => remote.getRoutineDays(tRoutineId),
      ).thenThrow(const SocketException('down'));
      when(
        () => local.getRoutineDays(tRoutineId),
      ).thenAnswer((_) async => const [tDay]);

      final result = await repo.getRoutineDays(tRoutineId);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.single.id, tDayId);
      });
    });

    test('online + remote falla + cache vacío → NetworkFailure', () async {
      when(
        () => remote.getRoutineDays(tRoutineId),
      ).thenThrow(const SocketException('down'));
      when(
        () => local.getRoutineDays(tRoutineId),
      ).thenAnswer((_) async => const []);

      final result = await repo.getRoutineDays(tRoutineId);
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test(
      'offline + cache con datos → devuelve cache (sin llamar remote)',
      () async {
        when(() => conn.isOnline).thenReturn(false);
        when(
          () => local.getRoutineDays(tRoutineId),
        ).thenAnswer((_) async => const [tDay]);

        final result = await repo.getRoutineDays(tRoutineId);
        result.fold((l) => fail('expected Right'), (r) {
          expect(r.single.id, tDayId);
        });
        verifyNever(() => remote.getRoutineDays(any()));
      },
    );

    test('offline + cache vacío → NetworkFailure', () async {
      when(() => conn.isOnline).thenReturn(false);
      when(
        () => local.getRoutineDays(tRoutineId),
      ).thenAnswer((_) async => const []);

      final result = await repo.getRoutineDays(tRoutineId);
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  // ─── getExercisesForDay ──────────────────────────────────────────────

  group('getExercisesForDay SWR', () {
    test('online + remote ok → fresh + escribe cache', () async {
      when(
        () => remote.getExercisesForDay(tDayId),
      ).thenAnswer((_) async => const [tExerciseModel]);
      when(
        () => local.getExercisesForDay(tDayId),
      ).thenAnswer((_) async => const []);

      final result = await repo.getExercisesForDay(tDayId);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.single.id, 'e1');
      });
      verify(() => local.cacheExercisesForDay(tDayId, any())).called(1);
    });

    test('online + remote ok + cache stale → fresh gana', () async {
      const stale = Exercise(
        id: 'stale',
        routineDayId: tDayId,
        name: 'Old',
        targetMuscle: '',
        targetWeight: 0,
        targetReps: 0,
      );
      when(
        () => remote.getExercisesForDay(tDayId),
      ).thenAnswer((_) async => const [tExerciseModel]);
      when(
        () => local.getExercisesForDay(tDayId),
      ).thenAnswer((_) async => const [stale]);

      final result = await repo.getExercisesForDay(tDayId);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.single.id, 'e1');
      });
    });

    test('online + remote falla + cache con datos → cache', () async {
      when(
        () => remote.getExercisesForDay(tDayId),
      ).thenThrow(const SocketException('down'));
      when(
        () => local.getExercisesForDay(tDayId),
      ).thenAnswer((_) async => const [tExercise]);

      final result = await repo.getExercisesForDay(tDayId);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.single.id, 'e1');
      });
    });

    test('online + remote falla + cache vacío → NetworkFailure', () async {
      when(
        () => remote.getExercisesForDay(tDayId),
      ).thenThrow(const SocketException('down'));
      when(
        () => local.getExercisesForDay(tDayId),
      ).thenAnswer((_) async => const []);

      final result = await repo.getExercisesForDay(tDayId);
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('offline + cache con datos → cache, sin tocar remote', () async {
      when(() => conn.isOnline).thenReturn(false);
      when(
        () => local.getExercisesForDay(tDayId),
      ).thenAnswer((_) async => const [tExercise]);

      final result = await repo.getExercisesForDay(tDayId);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r.single.id, 'e1');
      });
      verifyNever(() => remote.getExercisesForDay(any()));
    });

    test('offline + cache vacío → NetworkFailure', () async {
      when(() => conn.isOnline).thenReturn(false);
      when(
        () => local.getExercisesForDay(tDayId),
      ).thenAnswer((_) async => const []);

      final result = await repo.getExercisesForDay(tDayId);
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  // ─── getLastExercisePerformances ─────────────────────────────────────

  group('getLastExercisePerformances SWR', () {
    test('online + remote ok → fresh + escribe cache', () async {
      when(
        () => remote.getLastExercisePerformances(['e1']),
      ).thenAnswer((_) async => {'e1': tSetLogModel});
      when(
        () => local.getLastPerformancesForExercises(tUserId, ['e1']),
      ).thenAnswer((_) async => const {'e1': null});

      final result = await repo.getLastExercisePerformances(['e1']);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r['e1']!.sessionId, 's1');
      });
      verify(() => local.cacheLastPerformances(tUserId, any())).called(1);
    });

    test('online + remote ok + cache stale → fresh gana', () async {
      when(
        () => remote.getLastExercisePerformances(['e1']),
      ).thenAnswer((_) async => {'e1': tSetLogModel});
      when(
        () => local.getLastPerformancesForExercises(tUserId, ['e1']),
      ).thenAnswer((_) async => {'e1': tSetLogCached});

      final result = await repo.getLastExercisePerformances(['e1']);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r['e1']!.id, 'sl-1');
        expect(r['e1']!.actualWeight, 60.0);
      });
    });

    test('online + remote falla + cache con datos → cache', () async {
      when(
        () => remote.getLastExercisePerformances(['e1']),
      ).thenThrow(const SocketException('down'));
      when(
        () => local.getLastPerformancesForExercises(tUserId, ['e1']),
      ).thenAnswer((_) async => {'e1': tSetLogCached});

      final result = await repo.getLastExercisePerformances(['e1']);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r['e1']!.id, 'sl-cached');
      });
    });

    test(
      'online + remote falla + cache vacío (todo null) → NetworkFailure',
      () async {
        when(
          () => remote.getLastExercisePerformances(['e1']),
        ).thenThrow(const SocketException('down'));
        when(
          () => local.getLastPerformancesForExercises(tUserId, ['e1']),
        ).thenAnswer((_) async => const {'e1': null});

        final result = await repo.getLastExercisePerformances(['e1']);
        result.fold(
          (f) => expect(f, isA<NetworkFailure>()),
          (_) => fail('expected Left'),
        );
      },
    );

    test('offline + cache con datos → cache, sin tocar remote', () async {
      when(() => conn.isOnline).thenReturn(false);
      when(
        () => local.getLastPerformancesForExercises(tUserId, ['e1']),
      ).thenAnswer((_) async => {'e1': tSetLogCached});

      final result = await repo.getLastExercisePerformances(['e1']);
      result.fold((l) => fail('expected Right'), (r) {
        expect(r['e1']!.id, 'sl-cached');
      });
      verifyNever(() => remote.getLastExercisePerformances(any()));
    });

    test('offline + cache todo null → NetworkFailure', () async {
      when(() => conn.isOnline).thenReturn(false);
      when(
        () => local.getLastPerformancesForExercises(tUserId, ['e1']),
      ).thenAnswer((_) async => const {'e1': null});

      final result = await repo.getLastExercisePerformances(['e1']);
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('exerciseIds vacío → map vacío sin tocar remote ni cache', () async {
      final result = await repo.getLastExercisePerformances(const []);
      result.fold((l) => fail('expected Right'), (r) => expect(r, isEmpty));
      verifyNever(() => remote.getLastExercisePerformances(any()));
      verifyNever(() => local.getLastPerformancesForExercises(any(), any()));
    });
  });
}
