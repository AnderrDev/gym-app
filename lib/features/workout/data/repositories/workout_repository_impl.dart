import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/workout_local_data_source.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/set_log.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasources/workout_remote_data_source.dart';
import '../models/set_log_model.dart';
import '../models/workout_session_model.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutRemoteDataSource remoteDataSource;
  final WorkoutLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  WorkoutRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Routine>>> getAssignedRoutines(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteRoutines = await remoteDataSource.getAssignedRoutines(userId);
        return Right(remoteRoutines);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('Sin conexión para obtener rutinas'));
    }
  }

  @override
  Future<Either<Failure, SetLog?>> getLastExercisePerformance(String exerciseId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteLog = await remoteDataSource.getLastExercisePerformance(exerciseId);
        if (remoteLog != null) {
          await localDataSource.cacheSetLog(SetLogModel.fromEntity(remoteLog));
          await localDataSource.markSetLogAsSynced(remoteLog.id!);
        }
        return Right(remoteLog);
      } catch (e) {
        // Si falla remoto, intentamos local
        final localLog = await localDataSource.getLastExercisePerformance(exerciseId);
        return Right(localLog);
      }
    } else {
      final localLog = await localDataSource.getLastExercisePerformance(exerciseId);
      return Right(localLog);
    }
  }

  @override
  Future<Either<Failure, void>> saveSetLog(SetLog setLog) async {
    final model = SetLogModel.fromEntity(setLog);
    
    // Siempre guardamos en local primero (Offline-first write)
    await localDataSource.cacheSetLog(model);

    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.saveSetLog(model);
        if (model.id != null) {
          await localDataSource.markSetLogAsSynced(model.id!);
        }
        return const Right(null);
      } catch (e) {
        // Si falla remoto, el registro queda en local con is_synced = 0
        return const Right(null);
      }
    } else {
      // Offline: se queda en local para sincronizar luego
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, void>> finishWorkoutSession(
    String sessionId,
    double totalVolume,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.finishWorkoutSession(sessionId, totalVolume);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('Sin conexión para finalizar sesión en la nube'));
    }
  }

  @override
  Future<Either<Failure, void>> assignRoutineToUser(String userId, String routineId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.assignRoutineToUser(userId, routineId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, WorkoutSession>> startWorkoutSession(
    String userId,
    String routineId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteSession = await remoteDataSource.startWorkoutSession(userId, routineId);
        // Cachear localmente
        await localDataSource.cacheWorkoutSession(remoteSession as WorkoutSessionModel);
        await localDataSource.markWorkoutSessionAsSynced(remoteSession.id);
        return Right(remoteSession);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('Debes estar conectado para iniciar una sesión nueva'));
    }
  }

  @override
  Future<Either<Failure, List<Exercise>>> getRoutineExercises(String routineId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteExercises = await remoteDataSource.getRoutineExercises(routineId);
        return Right(remoteExercises);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
