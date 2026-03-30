import '../repositories/workout_repository.dart';

class FinishWorkoutSession {
  final WorkoutRepository repository;

  FinishWorkoutSession(this.repository);

  Future<void> call(String sessionId, double totalVolume) {
    return repository.finishWorkoutSession(sessionId, totalVolume);
  }
}
