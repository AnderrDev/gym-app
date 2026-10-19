import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';
import 'package:gym_flutter/features/workout/domain/usecases/add_exercises_to_day.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository repository;
  late AddExercisesToDay usecase;

  setUpAll(() {
    registerFallbackValue(<AddExerciseToDayPayload>[]);
  });

  setUp(() {
    repository = MockWorkoutRepository();
    usecase = AddExercisesToDay(repository);
  });

  test('delega lote completo al repositorio', () async {
    final items = const [
      AddExerciseToDayPayload(exerciseId: 'e1'),
      AddExerciseToDayPayload(exerciseId: 'e2', targetSets: 5),
    ];
    when(
      () => repository.addExercisesToDay(any(), any()),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase('d1', items);

    expect(result.isRight(), isTrue);
    verify(() => repository.addExercisesToDay('d1', items)).called(1);
  });
}
