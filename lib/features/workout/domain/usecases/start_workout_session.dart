import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/workout_session.dart';
import '../repositories/workout_repository.dart';

class StartWorkoutSession {
  final WorkoutRepository repository;

  StartWorkoutSession(this.repository);

  Future<Either<Failure, WorkoutSession>> call(String userId, String routineId) async {
    return await repository.startWorkoutSession(userId, routineId);
  }
}
