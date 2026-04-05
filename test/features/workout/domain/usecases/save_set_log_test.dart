import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gym_flutter/features/workout/domain/usecases/save_set_log.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository mockRepository;
  late SaveSetLog usecase;

  setUp(() {
    mockRepository = MockWorkoutRepository();
    usecase = SaveSetLog(mockRepository);
  });

  test('retorna void cuando guarda la serie', () async {
    const setLog = SetLog(
      id: 'sl-1',
      sessionId: 's1',
      exerciseId: 'e1',
      setIndex: 1,
      actualWeight: 40,
      actualReps: 10,
      createdAt: null,
    );

    when(
      () => mockRepository.saveSetLog(setLog),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase(setLog);

    expect(result, const Right(null));
    verify(() => mockRepository.saveSetLog(setLog)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('retorna Failure cuando falla el guardado', () async {
    const setLog = SetLog(
      id: 'sl-1',
      sessionId: 's1',
      exerciseId: 'e1',
      setIndex: 1,
      actualWeight: 40,
      actualReps: 10,
      createdAt: null,
    );

    when(
      () => mockRepository.saveSetLog(setLog),
    ).thenAnswer((_) async => const Left(ServerFailure('boom')));

    final result = await usecase(setLog);

    expect(result, const Left(ServerFailure('boom')));
  });
}
