import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class DeleteRoutineDay {
  final WorkoutRepository repository;

  DeleteRoutineDay(this.repository);

  Future<Either<Failure, void>> call(String dayId) async {
    return await repository.deleteRoutineDay(dayId);
  }
}
