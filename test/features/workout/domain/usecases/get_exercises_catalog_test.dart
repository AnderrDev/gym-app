import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/features/workout/domain/entities/exercise_catalog_item.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_exercises_catalog.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository repository;
  late GetExercisesCatalog usecase;

  const tItems = [
    ExerciseCatalogItem(id: 'e1', name: 'Press', muscleGroup: 'Pecho'),
    ExerciseCatalogItem(id: 'e2', name: 'Remo', muscleGroup: 'Espalda'),
  ];

  setUp(() {
    repository = MockWorkoutRepository();
    usecase = GetExercisesCatalog(repository);
  });

  test('delega filtros y devuelve catálogo', () async {
    when(
      () => repository.getExercisesCatalog(
        muscleGroup: any(named: 'muscleGroup'),
        search: any(named: 'search'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => const Right(tItems));

    final result = await usecase(muscleGroup: 'Pecho', search: 'pre', limit: 50);

    expect(result.isRight(), isTrue);
    verify(
      () => repository.getExercisesCatalog(
        muscleGroup: 'Pecho',
        search: 'pre',
        limit: 50,
      ),
    ).called(1);
  });
}
