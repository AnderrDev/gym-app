import '../entities/workout_session.dart';
import '../repositories/workout_repository.dart';

class StartWorkoutSession {
  final WorkoutRepository repository;

  StartWorkoutSession(this.repository);

  Future<WorkoutSession> call(String userId, String routineId) async {
    return await repository.startWorkoutSession(userId, routineId);
  }
}
