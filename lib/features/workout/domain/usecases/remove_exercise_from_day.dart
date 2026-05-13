import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class RemoveExerciseFromDay {
  final WorkoutRepository repository;

  RemoveExerciseFromDay(this.repository);

  Future<Either<Failure, void>> call(String dayId, String exerciseId) async {
    return await repository.removeExerciseFromDay(dayId, exerciseId);
  }
}
