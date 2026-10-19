import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_catalog_item.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class GetExercisesCatalog {
  final WorkoutRepository repository;

  GetExercisesCatalog(this.repository);

  Future<Either<Failure, List<ExerciseCatalogItem>>> call({
    String? muscleGroup,
    String? search,
    int limit = 200,
  }) async {
    return await repository.getExercisesCatalog(
      muscleGroup: muscleGroup,
      search: search,
      limit: limit,
    );
  }
}
