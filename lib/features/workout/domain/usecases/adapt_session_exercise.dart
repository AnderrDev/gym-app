import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class AdaptSessionExercise {
  AdaptSessionExercise(this.repository);
  final WorkoutRepository repository;
  Future<Either<Failure, List<Exercise>>> call(
    String sessionId,
    String exerciseId, {
    required int targetSets,
    required int targetReps,
    required double targetWeight,
    String? replaceExerciseId,
  }) {
    if (targetSets < 1 ||
        targetSets > 100 ||
        targetReps < 1 ||
        targetReps > 1000 ||
        !targetWeight.isFinite ||
        targetWeight < 0 ||
        targetWeight > 10000 ||
        exerciseId == replaceExerciseId) {
      return Future.value(
        const Left(
          ValidationFailure(
            'Revisa las series, repeticiones y peso del ejercicio.',
          ),
        ),
      );
    }
    return repository.adaptSessionExercise(
      sessionId,
      exerciseId,
      targetSets: targetSets,
      targetReps: targetReps,
      targetWeight: targetWeight,
      replaceExerciseId: replaceExerciseId,
    );
  }
}
