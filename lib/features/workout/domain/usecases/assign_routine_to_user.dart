import '../repositories/workout_repository.dart';

class AssignRoutineToUser {
  final WorkoutRepository repository;

  AssignRoutineToUser(this.repository);

  Future<void> call(String userId, String routineId) async {
    return await repository.assignRoutineToUser(userId, routineId);
  }
}
