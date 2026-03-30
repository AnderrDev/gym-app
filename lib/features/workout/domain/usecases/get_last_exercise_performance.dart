import '../entities/set_log.dart';
import '../repositories/workout_repository.dart';

class GetLastExercisePerformance {
  final WorkoutRepository repository;

  GetLastExercisePerformance(this.repository);

  Future<SetLog?> call(String exerciseId) {
    return repository.getLastExercisePerformance(exerciseId);
  }
}
