import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class AddExerciseToDay {
  final WorkoutRepository repository;

  AddExerciseToDay(this.repository);

  Future<Either<Failure, void>> call(
    String dayId,
    String exerciseId, {
    required int targetSets,
    required int targetReps,
    required double targetWeight,
    int restSeconds = 90,
  }) async {
    return await repository.addExerciseToDay(
      dayId,
      exerciseId,
      targetSets: targetSets,
      targetReps: targetReps,
      targetWeight: targetWeight,
      restSeconds: restSeconds,
    );
  }
}
