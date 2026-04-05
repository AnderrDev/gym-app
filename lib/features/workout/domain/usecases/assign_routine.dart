import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/workout_repository.dart';

class AssignRoutine {
  final WorkoutRepository repository;

  AssignRoutine(this.repository);

  Future<Either<Failure, void>> call(String userId, String routineId) async {
    return await repository.assignRoutineToUser(userId, routineId);
  }
}
