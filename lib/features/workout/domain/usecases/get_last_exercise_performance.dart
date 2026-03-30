import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/set_log.dart';
import '../repositories/workout_repository.dart';

class GetLastExercisePerformance {
  final WorkoutRepository repository;

  GetLastExercisePerformance(this.repository);

  Future<Either<Failure, SetLog?>> call(String exerciseId) {
    return repository.getLastExercisePerformance(exerciseId);
  }
}
