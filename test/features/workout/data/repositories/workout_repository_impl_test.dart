import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_remote_data_source.dart';
import 'package:gym_flutter/features/workout/data/models/routine_model.dart';
import 'package:gym_flutter/features/workout/data/models/routine_day_model.dart';
import 'package:gym_flutter/features/workout/data/models/set_log_model.dart';
import 'package:gym_flutter/features/workout/data/models/workout_session_model.dart';
import 'package:gym_flutter/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_fixtures.dart';

class MockWorkoutRemoteDataSource extends Mock
    implements WorkoutRemoteDataSource {}

void main() {
  late WorkoutRepositoryImpl repository;
  late MockWorkoutRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockWorkoutRemoteDataSource();
    repository = WorkoutRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  const tUserId = 'user-1';

  final tRoutineModel = RoutineModel(
    id: testRoutine.id,
    name: testRoutine.name,
    exerciseCount: testRoutine.exerciseCount,
    isPublic: testRoutine.isPublic,
  );

  final tWorkoutSessionModel = WorkoutSessionModel(
    id: testWorkoutSession.id,
    userId: testWorkoutSession.userId,
    routineDayId: testWorkoutSession.routineDayId,
    sessionDate: testSessionDate,
  );

  final tSetLog = SetLog(
    id: 'log-1',
    sessionId: 'session-1',
    exerciseId: 'exercise-1',
    setIndex: 0,
    actualWeight: 50.0,
    actualReps: 10,
    createdAt: testSessionDate,
  );

  setUpAll(() {
    registerFallbackValue(SetLogModel.fromEntity(tSetLog));
  });

  group('getAssignedRoutines', () {
    test('debería retornar la lista de rutinas desde el remote', () async {
      // arrange
      when(
        () => mockRemoteDataSource.getAssignedRoutines(any()),
      ).thenAnswer((_) async => [tRoutineModel]);

      // act
      final result = await repository.getAssignedRoutines(tUserId);

      // assert
      expect(result.isRight(), true);
      final list = result.getOrElse((_) => []);
      expect(list.length, 1);
      expect(list.first.id, testRoutine.id);
      verify(() => mockRemoteDataSource.getAssignedRoutines(tUserId)).called(1);
    });

    test('debería retornar ServerFailure cuando falla el remote', () async {
      // arrange
      when(
        () => mockRemoteDataSource.getAssignedRoutines(any()),
      ).thenThrow(Exception('remote error'));

      // act
      final result = await repository.getAssignedRoutines(tUserId);

      // assert
      expect(result, const Left(ServerFailure('Exception: remote error')));
    });
  });

  group('startWorkoutForDay', () {
    test('debería retornar la sesión creada desde el remote', () async {
      // arrange
      when(
        () => mockRemoteDataSource.startWorkoutForDay(any(), any(), any()),
      ).thenAnswer((_) async => tWorkoutSessionModel);

      // act
      final result = await repository.startWorkoutForDay(
        tUserId,
        'day-1',
        testSessionDate,
      );

      // assert
      expect(result, Right(tWorkoutSessionModel));
      verify(
        () => mockRemoteDataSource.startWorkoutForDay(
          tUserId,
          'day-1',
          testSessionDate,
        ),
      ).called(1);
    });
  });

  group('saveSetLog', () {
    test('debería llamar al remote con el modelo correcto', () async {
      // arrange
      when(
        () => mockRemoteDataSource.saveSetLog(any()),
      ).thenAnswer((_) async => Future.value());

      // act
      final result = await repository.saveSetLog(tSetLog);

      // assert
      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.saveSetLog(any())).called(1);
    });
  });

  group('finishWorkoutSession', () {
    test('debería llamar al remote para finalizar la sesión', () async {
      // arrange
      when(
        () => mockRemoteDataSource.finishWorkoutSession(
          any(),
          coachingAnalysis: any(named: 'coachingAnalysis'),
        ),
      ).thenAnswer((_) async => Future.value());

      // act
      final result = await repository.finishWorkoutSession('session-1');

      // assert
      expect(result, const Right(null));
      verify(
        () => mockRemoteDataSource.finishWorkoutSession('session-1'),
      ).called(1);
    });
  });
}
