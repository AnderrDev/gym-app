import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class UpdateExerciseTarget {
  final WorkoutRepository repository;

  UpdateExerciseTarget(this.repository);

  Future<Either<Failure, void>> call(
    String routineDayId,
    String exerciseId,
    double targetWeight,
    int targetReps, {
    int? targetSets,
    int? restSeconds,
  }) async {
    return await repository.updateExerciseTarget(
      routineDayId,
      exerciseId,
      targetWeight,
      targetReps,
      targetSets: targetSets,
      restSeconds: restSeconds,
    );
  }
}
