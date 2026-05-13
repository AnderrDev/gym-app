import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/features/workout/domain/usecases/add_exercise_to_day.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository repository;
  late AddExerciseToDay usecase;

  setUp(() {
    repository = MockWorkoutRepository();
    usecase = AddExerciseToDay(repository);
  });

  test('delega los parámetros al repositorio', () async {
    when(
      () => repository.addExerciseToDay(
        any(),
        any(),
        targetSets: any(named: 'targetSets'),
        targetReps: any(named: 'targetReps'),
        targetWeight: any(named: 'targetWeight'),
        restSeconds: any(named: 'restSeconds'),
      ),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase(
      'd1',
      'e1',
      targetSets: 4,
      targetReps: 8,
      targetWeight: 60,
      restSeconds: 120,
    );

    expect(result.isRight(), isTrue);
    verify(
      () => repository.addExerciseToDay(
        'd1',
        'e1',
        targetSets: 4,
        targetReps: 8,
        targetWeight: 60,
        restSeconds: 120,
      ),
    ).called(1);
  });
}
