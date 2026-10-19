import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_detail.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_exercise_detail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository repository;
  late GetExerciseDetail usecase;

  const tId = 'ex-1';
  const tDetail = ExerciseDetail(
    id: tId,
    name: 'Press de Banca',
    muscleGroup: 'Pecho',
    instructions:
        'Acuéstate en banco plano.\n\n- Agarre algo más ancho que hombros.',
  );

  setUp(() {
    repository = MockWorkoutRepository();
    usecase = GetExerciseDetail(repository);
  });

  test(
    'delega en repository.getExerciseDetail y devuelve la entidad',
    () async {
      when(
        () => repository.getExerciseDetail(any()),
      ).thenAnswer((_) async => const Right(tDetail));

      final result = await usecase(tId);

      expect(result, const Right<Failure, ExerciseDetail>(tDetail));
      verify(() => repository.getExerciseDetail(tId)).called(1);
    },
  );

  test('propaga Failure desde el repositorio', () async {
    when(
      () => repository.getExerciseDetail(any()),
    ).thenAnswer((_) async => const Left(NotFoundFailure('not found')));

    final result = await usecase(tId);

    expect(result.isLeft(), isTrue);
  });
}
