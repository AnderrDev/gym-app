import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_assigned_routines.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository mockRepository;
  late GetAssignedRoutines usecase;

  setUp(() {
    mockRepository = MockWorkoutRepository();
    usecase = GetAssignedRoutines(mockRepository);
  });

  test('retorna lista de rutinas asignadas', () async {
    const routines = [
      Routine(id: 'r1', name: 'Rutina 1', exerciseCount: 0, isPublic: false),
      Routine(id: 'r2', name: 'Rutina 2', exerciseCount: 0, isPublic: true),
    ];
    when(
      () => mockRepository.getAssignedRoutines('user-1'),
    ).thenAnswer((_) async => const Right(routines));

    final result = await usecase('user-1');

    expect(result, const Right(routines));
    verify(() => mockRepository.getAssignedRoutines('user-1')).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('retorna Failure cuando falla la carga', () async {
    when(
      () => mockRepository.getAssignedRoutines('user-1'),
    ).thenAnswer((_) async => const Left(ServerFailure('boom')));

    final result = await usecase('user-1');

    expect(result, const Left(ServerFailure('boom')));
  });
}
