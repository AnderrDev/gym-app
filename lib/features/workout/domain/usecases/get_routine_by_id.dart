import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class GetRoutineById {
  final WorkoutRepository repository;

  GetRoutineById(this.repository);

  Future<Either<Failure, Routine>> call(String routineId) async {
    return await repository.getRoutineById(routineId);
  }
}
