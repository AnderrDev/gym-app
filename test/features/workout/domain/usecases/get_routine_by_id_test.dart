import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_routine_by_id.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository repository;
  late GetRoutineById usecase;

  const tRoutine = Routine(id: 'r1', name: 'X', exerciseCount: 3);

  setUp(() {
    repository = MockWorkoutRepository();
    usecase = GetRoutineById(repository);
  });

  test('devuelve la rutina del repositorio', () async {
    when(
      () => repository.getRoutineById('r1'),
    ).thenAnswer((_) async => const Right(tRoutine));

    final result = await usecase('r1');

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected right'), (r) => expect(r, tRoutine));
  });
}
