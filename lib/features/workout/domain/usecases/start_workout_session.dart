// OBSOLETO: Reemplazado por WorkoutRepository.startWorkoutForDay
// Mantenido para no romper compilación durante migración
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/workout_session.dart';
import '../repositories/workout_repository.dart';

@Deprecated('Use repository.startWorkoutForDay instead')
class StartWorkoutSession {
  final WorkoutRepository repository;
  StartWorkoutSession(this.repository);

  Future<Either<Failure, WorkoutSession>> call(String userId, String routineId) async {
    return const Left(ServerFailure('Use StartDayWorkout event instead'));
  }
}
