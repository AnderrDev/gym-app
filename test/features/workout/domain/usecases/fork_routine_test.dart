import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/usecases/fork_routine.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository repository;
  late ForkRoutine usecase;

  const tSourceId = 'src-routine-1';
  const tNewId = 'new-routine-1';

  setUp(() {
    repository = MockWorkoutRepository();
    usecase = ForkRoutine(repository);
  });

  test('delega en repository.forkRoutine y devuelve el nuevo id', () async {
    when(
      () => repository.forkRoutine(any(), newName: any(named: 'newName')),
    ).thenAnswer((_) async => const Right(tNewId));

    final result = await usecase(tSourceId);

    expect(result, const Right<Failure, String>(tNewId));
    verify(() => repository.forkRoutine(tSourceId, newName: null)).called(1);
  });

  test('propaga newName cuando se pasa', () async {
    when(
      () => repository.forkRoutine(any(), newName: any(named: 'newName')),
    ).thenAnswer((_) async => const Right(tNewId));

    await usecase(tSourceId, newName: 'Mi versión');

    verify(
      () => repository.forkRoutine(tSourceId, newName: 'Mi versión'),
    ).called(1);
  });

  test('propaga Failure desde el repositorio', () async {
    when(
      () => repository.forkRoutine(any(), newName: any(named: 'newName')),
    ).thenAnswer((_) async => const Left(ServerFailure('boom')));

    final result = await usecase(tSourceId);

    expect(result.isLeft(), isTrue);
  });
}
