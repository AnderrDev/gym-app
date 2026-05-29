import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class DeleteRoutine {
  final WorkoutRepository repository;

  DeleteRoutine(this.repository);

  Future<Either<Failure, void>> call(String routineId) async {
    return await repository.deleteRoutine(routineId);
  }
}
