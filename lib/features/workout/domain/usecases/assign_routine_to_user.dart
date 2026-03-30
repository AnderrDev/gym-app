import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/workout_repository.dart';

class AssignRoutineToUser {
  final WorkoutRepository repository;

  AssignRoutineToUser(this.repository);

  Future<Either<Failure, void>> call(String userId, String routineId) async {
    return await repository.assignRoutineToUser(userId, routineId);
  }
}
