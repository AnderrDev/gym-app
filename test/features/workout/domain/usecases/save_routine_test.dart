import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/usecases/save_routine.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository repository;
  late SaveRoutine usecase;

  const tRoutine = Routine(id: '', name: 'Mi rutina', exerciseCount: 0);
  const tSaved = Routine(id: 'r1', name: 'Mi rutina', exerciseCount: 0);

  setUpAll(() {
    registerFallbackValue(tRoutine);
  });

  setUp(() {
    repository = MockWorkoutRepository();
    usecase = SaveRoutine(repository);
  });

  test(
    'delega en repository.saveRoutine y devuelve Routine persistida',
    () async {
      when(
        () => repository.saveRoutine(any()),
      ).thenAnswer((_) async => const Right(tSaved));

      final result = await usecase(tRoutine);

      expect(result, const Right<Failure, Routine>(tSaved));
      verify(() => repository.saveRoutine(tRoutine)).called(1);
    },
  );

  test('propaga Failure desde el repositorio', () async {
    when(
      () => repository.saveRoutine(any()),
    ).thenAnswer((_) async => const Left(ServerFailure('boom')));

    final result = await usecase(tRoutine);

    expect(result.isLeft(), isTrue);
  });
}
