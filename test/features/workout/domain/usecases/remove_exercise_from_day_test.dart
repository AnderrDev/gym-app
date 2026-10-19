import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/features/workout/domain/usecases/remove_exercise_from_day.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository repository;
  late RemoveExerciseFromDay usecase;

  setUp(() {
    repository = MockWorkoutRepository();
    usecase = RemoveExerciseFromDay(repository);
  });

  test('delega en repository.removeExerciseFromDay', () async {
    when(
      () => repository.removeExerciseFromDay('d1', 'e1'),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase('d1', 'e1');

    expect(result.isRight(), isTrue);
    verify(() => repository.removeExerciseFromDay('d1', 'e1')).called(1);
  });
}
