import 'package:fpdart/fpdart.dart';

import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_detail.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class GetExerciseDetail {
  final WorkoutRepository repository;

  GetExerciseDetail(this.repository);

  Future<Either<Failure, ExerciseDetail>> call(String exerciseId) =>
      repository.getExerciseDetail(exerciseId);
}
