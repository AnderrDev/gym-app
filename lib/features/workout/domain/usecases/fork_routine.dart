import 'package:fpdart/fpdart.dart';

import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class ForkRoutine {
  final WorkoutRepository repository;

  ForkRoutine(this.repository);

  Future<Either<Failure, String>> call(
    String sourceRoutineId, {
    String? newName,
  }) => repository.forkRoutine(sourceRoutineId, newName: newName);
}
