import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/routine.dart';
import '../repositories/workout_repository.dart';

class GetAllRoutines {
  final WorkoutRepository repository;

  GetAllRoutines(this.repository);

  Future<Either<Failure, List<Routine>>> call() async {
    return await repository.getAllRoutines();
  }
}
