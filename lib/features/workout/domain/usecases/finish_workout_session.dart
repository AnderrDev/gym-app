import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/workout_repository.dart';

class FinishWorkoutSession {
  final WorkoutRepository repository;

  FinishWorkoutSession(this.repository);

  Future<Either<Failure, void>> call(String sessionId, double totalVolume) {
    return repository.finishWorkoutSession(sessionId, totalVolume);
  }
}
