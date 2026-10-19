import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class GetSessionExercises {
  GetSessionExercises(this.repository);
  final WorkoutRepository repository;
  Future<Either<Failure, List<Exercise>>> call(String sessionId) =>
      repository.getSessionExercises(sessionId);
}
