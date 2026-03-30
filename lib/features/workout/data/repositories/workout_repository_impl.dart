import '../../domain/entities/routine.dart';
import '../../domain/entities/set_log.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasources/workout_remote_data_source.dart';
import '../models/set_log_model.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutRemoteDataSource remoteDataSource;

  WorkoutRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Routine>> getAssignedRoutines(String userId) async {
    try {
      return await remoteDataSource.getAssignedRoutines(userId);
    } catch (e) {
      // Real-world: throw custom exceptions based on status codes
      rethrow;
    }
  }

  @override
  Future<SetLog?> getLastExercisePerformance(String exerciseId) async {
    try {
      return await remoteDataSource.getLastExercisePerformance(exerciseId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> saveSetLog(SetLog setLog) async {
    try {
      final model = SetLogModel.fromEntity(setLog);
      await remoteDataSource.saveSetLog(model);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> finishWorkoutSession(
    String sessionId,
    double totalVolume,
  ) async {
    try {
      await remoteDataSource.finishWorkoutSession(sessionId, totalVolume);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> assignRoutineToUser(String userId, String routineId) async {
    try {
      await remoteDataSource.assignRoutineToUser(userId, routineId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<WorkoutSession> startWorkoutSession(
    String userId,
    String routineId,
  ) async {
    try {
      return await remoteDataSource.startWorkoutSession(userId, routineId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Exercise>> getRoutineExercises(String routineId) async {
    try {
      return await remoteDataSource.getRoutineExercises(routineId);
    } catch (e) {
      rethrow;
    }
  }
}
