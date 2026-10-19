import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/usecases/delete_routine.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository repository;
  late DeleteRoutine usecase;

  setUp(() {
    repository = MockWorkoutRepository();
    usecase = DeleteRoutine(repository);
  });

  test('delega en repository.deleteRoutine', () async {
    when(
      () => repository.deleteRoutine('r1'),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase('r1');

    expect(result.isRight(), isTrue);
    verify(() => repository.deleteRoutine('r1')).called(1);
  });

  test('propaga Failure', () async {
    when(
      () => repository.deleteRoutine('r1'),
    ).thenAnswer((_) async => const Left(ServerFailure('x')));

    final result = await usecase('r1');
    expect(result.isLeft(), isTrue);
  });
}
