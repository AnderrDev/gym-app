// OBSOLETO: Reemplazado por WorkoutRepository.getExercisesForDay
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/exercise.dart';
import '../repositories/workout_repository.dart';

@Deprecated('Use repository.getExercisesForDay instead')
class GetRoutineExercises {
  final WorkoutRepository repository;
  GetRoutineExercises(this.repository);

  Future<Either<Failure, List<Exercise>>> call(String routineDayId) {
    return repository.getExercisesForDay(routineDayId);
  }
}
