import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class SaveRoutineDay {
  final WorkoutRepository repository;

  SaveRoutineDay(this.repository);

  Future<Either<Failure, RoutineDay>> call(RoutineDay day) async {
    return await repository.saveRoutineDay(day);
  }
}
