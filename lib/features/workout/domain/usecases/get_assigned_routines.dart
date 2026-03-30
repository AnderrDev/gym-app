import '../entities/routine.dart';
import '../repositories/workout_repository.dart';

class GetAssignedRoutines {
  final WorkoutRepository repository;

  GetAssignedRoutines(this.repository);

  Future<List<Routine>> call(String userId) {
    return repository.getAssignedRoutines(userId);
  }
}
