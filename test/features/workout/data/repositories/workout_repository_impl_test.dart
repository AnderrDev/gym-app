import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_remote_data_source.dart';
import 'package:gym_flutter/features/workout/data/models/routine_model.dart';
import 'package:gym_flutter/features/workout/data/models/routine_day_model.dart';
import 'package:gym_flutter/features/workout/data/models/exercise_model.dart';
import 'package:gym_flutter/features/workout/data/models/workout_session_model.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkoutRemoteDataSource extends Mock
    implements WorkoutRemoteDataSource {}

void main() {
  late WorkoutRepositoryImpl repository;
  late MockWorkoutRemoteDataSource mockRemoteDataSource;

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
  });

  setUp(() {
    mockRemoteDataSource = MockWorkoutRemoteDataSource();
    repository = WorkoutRepositoryImpl(remoteDataSource: mockRemoteDataSource);
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
        result.fold((l) => fail('L'), (r) => expect(r, [tRoutineModel]));
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
        result.fold((l) => fail('L'), (r) => expect(r, tDays));
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
        result.fold((l) => fail('L'), (r) => expect(r, tExercises));
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
        result.fold((l) => fail('L'), (r) => expect(r, tSession));
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
      when(
        () => mockRemoteDataSource.saveRoutineDay(any()),
      ).thenAnswer((_) async => {});
      final result = await repository.saveRoutineDay(tDayModel);
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
      result.fold((l) => fail('L'), (r) => expect(r, tRoutineModel));
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
        result.fold((l) => fail('L'), (r) => expect(r, [tRoutineModel]));
      },
    );
  });
}
