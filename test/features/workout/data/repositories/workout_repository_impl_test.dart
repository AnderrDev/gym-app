import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/error/exceptions.dart' as core_ex;
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/data/models/routine_model.dart';
import 'package:gym_flutter/features/workout/data/models/routine_day_model.dart';
import 'package:gym_flutter/features/workout/data/models/exercise_model.dart';
import 'package:gym_flutter/features/workout/data/models/workout_session_model.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:gym_flutter/features/workout/data/repositories/workout_repository_mappers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../helpers/mocks.dart';

void main() {
  late WorkoutRepositoryImpl repository;
  late MockWorkoutRemoteDataSource mockRemoteDataSource;
  late MockWorkoutLocalDataSource mockLocalDataSource;
  late MockConnectivityService mockConnectivity;

  const tUserId = 'u1';
  const tRoutineId = 'r1';
  const tRoutineModel = RoutineModel(
    id: tRoutineId,
    name: 'Test Routine',
    exerciseCount: 0,
  );

  setUpAll(() {
    registerFallbackValue(tRoutineModel);
    registerFallbackValue(DateTime.now());
    registerFallbackValue(
      const RoutineDayModel(
        id: 'd1',
        routineId: 'r1',
        name: 'Lunes',
        dayOfWeek: 1,
      ),
    );
    registerFallbackValue(
      WeeklyInsights(
        weekStart: DateTime(2026, 1, 1),
        weekEnd: DateTime(2026, 1, 7),
        plannedDays: 0,
        completedDays: 0,
        completedSessions: 0,
        adherenceRate: 0,
        totalVolume: 0,
        previousWeekVolume: 0,
        volumeTrendPercent: 0,
        personalRecords: 0,
      ),
    );
  });

  setUp(() {
    mockRemoteDataSource = MockWorkoutRemoteDataSource();
    mockLocalDataSource = MockWorkoutLocalDataSource();
    mockConnectivity = MockConnectivityService();
    when(() => mockConnectivity.isOnline).thenReturn(true);
    // Stubs por defecto: cache vacío. Los tests SWR específicos los
    // sobrescriben cuando necesitan otro comportamiento.
    when(() => mockLocalDataSource.cacheRoutineDays(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockLocalDataSource.cacheExercisesForDay(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockLocalDataSource.cacheLastPerformances(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockLocalDataSource.cacheAssignedRoutines(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockLocalDataSource.cacheWeekSessions(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockLocalDataSource.cacheWeeklyInsights(
          userId: any(named: 'userId'),
          routineId: any(named: 'routineId'),
          insights: any(named: 'insights'),
        )).thenAnswer((_) async {});
    when(() => mockLocalDataSource.getRoutineDays(any()))
        .thenAnswer((_) async => const []);
    when(() => mockLocalDataSource.getExercisesForDay(any()))
        .thenAnswer((_) async => const []);
    when(() =>
            mockLocalDataSource.getLastPerformancesForExercises(any(), any()))
        .thenAnswer((_) async => const {});
    when(() => mockLocalDataSource.getAssignedRoutines(any()))
        .thenAnswer((_) async => null);
    when(() => mockLocalDataSource.getWeekSessions(any(), any(), any()))
        .thenAnswer((_) async => const []);
    when(() => mockLocalDataSource.getWeeklyInsights(any(), any(), any()))
        .thenAnswer((_) async => null);
    repository = WorkoutRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      connectivity: mockConnectivity,
      currentUserIdResolver: () => tUserId,
    );
  });

  group('getAssignedRoutines', () {
    test(
      'debería retornar lista de rutinas cuando la llamada es exitosa',
      () async {
        when(
          () => mockRemoteDataSource.getAssignedRoutines(any()),
        ).thenAnswer((_) async => [tRoutineModel]);
        final result = await repository.getAssignedRoutines(tUserId);
        expect(result.isRight(), isTrue);
        result.fold(
          (l) => fail('L'),
          (r) => expect(r, [tRoutineModel.toEntity()]),
        );
      },
    );
  });

  group('getRoutineDays', () {
    test(
      'debería retornar lista de días cuando la llamada es exitosa',
      () async {
        const tDays = [
          RoutineDayModel(
            id: 'd1',
            routineId: tRoutineId,
            name: 'Lunes',
            dayOfWeek: 1,
          ),
        ];
        when(
          () => mockRemoteDataSource.getRoutineDays(any()),
        ).thenAnswer((_) async => tDays);
        final result = await repository.getRoutineDays(tRoutineId);
        expect(result.isRight(), isTrue);
        result.fold(
          (l) => fail('L'),
          (r) => expect(r, tDays.map((m) => m.toEntity()).toList()),
        );
      },
    );
  });

  group('getExercisesForDay', () {
    test(
      'debería retornar lista de ejercicios cuando la llamada es exitosa',
      () async {
        const tExercises = [
          ExerciseModel(
            id: 'e1',
            routineDayId: 'd1',
            name: 'P',
            targetMuscle: 'P',
            targetWeight: 60,
            targetReps: 10,
            targetSets: 3,
            restTimerSeconds: 90,
          ),
        ];
        when(
          () => mockRemoteDataSource.getExercisesForDay(any()),
        ).thenAnswer((_) async => tExercises);
        final result = await repository.getExercisesForDay('d1');
        expect(result.isRight(), isTrue);
        result.fold(
          (l) => fail('L'),
          (r) => expect(r, tExercises.map((m) => m.toEntity()).toList()),
        );
      },
    );
  });

  group('startWorkoutForDay', () {
    test(
      'debería retornar WorkoutSession cuando la llamada es exitosa',
      () async {
        final tSession = WorkoutSessionModel(
          id: 's1',
          userId: tUserId,
          routineDayId: 'd1',
          sessionDate: DateTime(2026, 4, 5),
        );
        when(
          () => mockRemoteDataSource.startWorkoutForDay(any(), any(), any()),
        ).thenAnswer((_) async => tSession);
        final result = await repository.startWorkoutForDay(
          tUserId,
          'd1',
          DateTime(2026, 4, 5),
        );
        expect(result.isRight(), isTrue);
        result.fold((l) => fail('L'), (r) => expect(r, tSession.toEntity()));
      },
    );
  });

  group('finishWorkoutSession', () {
    test('debería llamar a finishWorkoutSession en el data source', () async {
      when(
        () => mockRemoteDataSource.finishWorkoutSession(
          any(),
          coachingAnalysis: any(named: 'coachingAnalysis'),
        ),
      ).thenAnswer((_) async => {});
      final result = await repository.finishWorkoutSession('s1');
      expect(result.isRight(), isTrue);
    });
  });

  group('getWeeklyInsights', () {
    test(
      'debería retornar WeeklyInsights cuando la llamada es exitosa',
      () async {
        final tInsights = WeeklyInsights(
          weekStart: DateTime(2026, 4, 5),
          weekEnd: DateTime(2026, 4, 11),
          plannedDays: 5,
          completedDays: 3,
          completedSessions: 3,
          adherenceRate: 0.6,
          totalVolume: 1000,
          previousWeekVolume: 900,
          volumeTrendPercent: 10,
          personalRecords: 1,
        );
        when(
          () => mockRemoteDataSource.getWeeklyInsights(
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => tInsights);
        final result = await repository.getWeeklyInsights(
          routineId: 'r1',
          weekStart: DateTime(2026, 4, 5),
        );
        expect(result.isRight(), isTrue);
        result.fold((l) => fail('L'), (r) => expect(r, tInsights));
      },
    );
  });

  group('saveRoutineDay', () {
    test('debería llamar a saveRoutineDay en el data source', () async {
      const tDayModel = RoutineDayModel(
        id: 'd1',
        routineId: 'r1',
        name: 'Lunes',
        dayOfWeek: 1,
      );
      const tDay = RoutineDay(
        id: 'd1',
        routineId: 'r1',
        name: 'Lunes',
        dayOfWeek: 1,
      );
      when(
        () => mockRemoteDataSource.saveRoutineDay(any()),
      ).thenAnswer((_) async => tDayModel);
      final result = await repository.saveRoutineDay(tDay);
      expect(result.isRight(), isTrue);
      verify(() => mockRemoteDataSource.saveRoutineDay(any())).called(1);
    });
  });

  group('getRoutineById', () {
    test('debería retornar Routine cuando la llamada es exitosa', () async {
      when(
        () => mockRemoteDataSource.getRoutineById(any()),
      ).thenAnswer((_) async => tRoutineModel);
      final result = await repository.getRoutineById('r1');
      expect(result.isRight(), isTrue);
      result.fold((l) => fail('L'), (r) => expect(r, tRoutineModel.toEntity()));
    });
  });

  group('getAllRoutines', () {
    test(
      'debería retornar lista de rutinas cuando la llamada es exitosa',
      () async {
        when(
          () => mockRemoteDataSource.getAllRoutines(),
        ).thenAnswer((_) async => [tRoutineModel]);
        final result = await repository.getAllRoutines();
        expect(result.isRight(), isTrue);
        result.fold(
          (l) => fail('L'),
          (r) => expect(r, [tRoutineModel.toEntity()]),
        );
      },
    );
  });

  // ─── Error-path mapping ────────────────────────────────────────────────
  group('error mapping (guard)', () {
    test('PostgrestException(PGRST116) → NotFoundFailure', () async {
      when(() => mockRemoteDataSource.getAssignedRoutines(any())).thenThrow(
        const supabase.PostgrestException(message: 'no rows', code: 'PGRST116'),
      );
      final result = await repository.getAssignedRoutines(tUserId);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('SocketException → NetworkFailure', () async {
      when(
        () => mockRemoteDataSource.getRoutineDays(any()),
      ).thenThrow(const SocketException('down'));
      final result = await repository.getRoutineDays('r1');
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('supabase.AuthException → AuthFailure', () async {
      when(
        () => mockRemoteDataSource.getActiveSessionForUser(any()),
      ).thenThrow(const supabase.AuthException('expired'));
      final result = await repository.getActiveSessionForUser(tUserId);
      result.fold(
        (f) {
          expect(f, isA<AuthFailure>());
          expect(f.message, 'expired');
        },
        (_) => fail('expected Left'),
      );
    });

    test('ServerException → ServerFailure', () async {
      when(
        () => mockRemoteDataSource.getAllRoutines(),
      ).thenThrow(core_ex.ServerException('500'));
      final result = await repository.getAllRoutines();
      result.fold(
        (f) {
          expect(f, isA<ServerFailure>());
          expect(f.message, '500');
        },
        (_) => fail('expected Left'),
      );
    });

    test(
      'finishWorkoutSession propaga AuthFailure cuando hay AuthException',
      () async {
        when(
          () => mockRemoteDataSource.finishWorkoutSession(
            any(),
            coachingAnalysis: any(named: 'coachingAnalysis'),
          ),
        ).thenThrow(const supabase.AuthException('JWT expired'));
        final result = await repository.finishWorkoutSession('s1');
        result.fold(
          (f) => expect(f, isA<AuthFailure>()),
          (_) => fail('expected Left'),
        );
      },
    );

    test('getWeeklyInsights propaga ServerFailure ante error genérico',
        () async {
      when(
        () => mockRemoteDataSource.getWeeklyInsights(
          routineId: any(named: 'routineId'),
          weekStart: any(named: 'weekStart'),
        ),
      ).thenThrow(StateError('rpc-down'));
      final result = await repository.getWeeklyInsights(
        routineId: 'r1',
        weekStart: DateTime(2026, 4, 5),
      );
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });
}
