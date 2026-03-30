import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/routine.dart';
import '../repositories/workout_repository.dart';

class GetAssignedRoutines {
  final WorkoutRepository repository;

  GetAssignedRoutines(this.repository);

  Future<Either<Failure, List<Routine>>> call(String userId) {
    return repository.getAssignedRoutines(userId);
  }
}
