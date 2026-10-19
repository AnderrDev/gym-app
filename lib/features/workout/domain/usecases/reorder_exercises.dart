import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class ReorderExercises {
  final WorkoutRepository repository;

  ReorderExercises(this.repository);

  Future<Either<Failure, void>> call(
    String dayId,
    List<String> exerciseIds,
  ) async {
    return await repository.reorderExercisesInDay(dayId, exerciseIds);
  }
}
