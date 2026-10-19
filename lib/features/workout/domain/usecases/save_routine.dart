import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class SaveRoutine {
  final WorkoutRepository repository;

  SaveRoutine(this.repository);

  Future<Either<Failure, Routine>> call(Routine routine) async {
    return await repository.saveRoutine(routine);
  }
}
