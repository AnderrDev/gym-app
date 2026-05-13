import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/features/workout/domain/usecases/update_exercise_target.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository repository;
  late UpdateExerciseTarget usecase;

  setUp(() {
    repository = MockWorkoutRepository();
    usecase = UpdateExerciseTarget(repository);
  });

  test('delega valores objetivo al repositorio', () async {
    when(
      () => repository.updateExerciseTarget(
        any(),
        any(),
        any(),
        any(),
        targetSets: any(named: 'targetSets'),
        restSeconds: any(named: 'restSeconds'),
      ),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase(
      'd1',
      'e1',
      50,
      10,
      targetSets: 4,
      restSeconds: 60,
    );

    expect(result.isRight(), isTrue);
    verify(
      () => repository.updateExerciseTarget(
        'd1',
        'e1',
        50,
        10,
        targetSets: 4,
        restSeconds: 60,
      ),
    ).called(1);
  });
}
