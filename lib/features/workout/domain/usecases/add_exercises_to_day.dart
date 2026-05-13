import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class AddExercisesToDay {
  final WorkoutRepository repository;

  AddExercisesToDay(this.repository);

  Future<Either<Failure, void>> call(
    String dayId,
    List<AddExerciseToDayPayload> items,
  ) async {
    return await repository.addExercisesToDay(dayId, items);
  }
}
