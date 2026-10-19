import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/features/workout/domain/usecases/reorder_exercises.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository repository;
  late ReorderExercises usecase;

  setUp(() {
    repository = MockWorkoutRepository();
    usecase = ReorderExercises(repository);
  });

  test('delega ids al repositorio.reorderExercisesInDay', () async {
    when(
      () => repository.reorderExercisesInDay('d1', ['a', 'b', 'c']),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase('d1', ['a', 'b', 'c']);

    expect(result.isRight(), isTrue);
    verify(
      () => repository.reorderExercisesInDay('d1', ['a', 'b', 'c']),
    ).called(1);
  });
}
