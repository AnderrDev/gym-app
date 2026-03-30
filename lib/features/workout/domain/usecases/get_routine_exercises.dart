import '../entities/exercise.dart';
import '../repositories/workout_repository.dart';

class GetRoutineExercises {
  final WorkoutRepository repository;

  GetRoutineExercises(this.repository);

  Future<List<Exercise>> call(String routineId) async {
    return await repository.getRoutineExercises(routineId);
  }
}
