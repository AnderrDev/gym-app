import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/routine.dart';
import '../entities/set_log.dart';
import '../entities/exercise.dart';
import '../entities/workout_session.dart';

abstract class WorkoutRepository {
  /// Fetches the routines assigned to a specific user
  Future<Either<Failure, List<Routine>>> getAssignedRoutines(String userId);

  /// Fetches the latest set log for a given exercise to show previous performance
  Future<Either<Failure, SetLog?>> getLastExercisePerformance(String exerciseId);

  /// Saves a single set log to the database
  Future<Either<Failure, void>> saveSetLog(SetLog setLog);

  /// Finishes a workout session, updating its completion time and total volume
  Future<Either<Failure, void>> finishWorkoutSession(String sessionId, double totalVolume);

  Future<Either<Failure, void>> assignRoutineToUser(String userId, String routineId);

  /// Starts a new workout session for tracking
  Future<Either<Failure, WorkoutSession>> startWorkoutSession(String userId, String routineId);

  /// Gets all configure exercises for a specific routine
  Future<Either<Failure, List<Exercise>>> getRoutineExercises(String routineId);
}
