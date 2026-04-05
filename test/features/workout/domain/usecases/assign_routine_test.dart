import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gym_flutter/features/workout/domain/usecases/assign_routine.dart';
import 'package:gym_flutter/core/error/failures.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository mockRepository;
  late AssignRoutine usecase;

  setUp(() {
    mockRepository = MockWorkoutRepository();
    usecase = AssignRoutine(mockRepository);
  });

  test('retorna void cuando asigna rutina', () async {
    when(
      () => mockRepository.assignRoutineToUser('user-1', 'r1'),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase('user-1', 'r1');

    expect(result, const Right(null));
    verify(() => mockRepository.assignRoutineToUser('user-1', 'r1')).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('retorna Failure cuando falla la asignacion', () async {
    when(
      () => mockRepository.assignRoutineToUser('user-1', 'r1'),
    ).thenAnswer((_) async => const Left(ServerFailure('boom')));

    final result = await usecase('user-1', 'r1');

    expect(result, const Left(ServerFailure('boom')));
  });
}
