import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/exercise.dart';
import '../entities/set_log.dart';
import '../entities/workout_session.dart';
import '../repositories/workout_repository.dart';

class GetSessionHistory {
  final WorkoutRepository repository;
  GetSessionHistory(this.repository);

  Future<Either<Failure, ({WorkoutSession session, List<SetLog> setLogs, List<Exercise> exercises})>>
      call(String sessionId, String routineDayId) async {
    // Cargar set logs y ejercicios en paralelo
    final results = await Future.wait([
      repository.getSessionSetLogs(sessionId),
      repository.getExercisesForDay(routineDayId),
    ]);

    final setLogsResult = results[0] as Either<Failure, List<SetLog>>;
    final exercisesResult = results[1] as Either<Failure, List<Exercise>>;

    if (setLogsResult.isLeft()) return Left(setLogsResult.swap().getOrElse((_) => const ServerFailure()));
    if (exercisesResult.isLeft()) return Left(exercisesResult.swap().getOrElse((_) => const ServerFailure()));

    return Right((
      session: WorkoutSession(id: sessionId, userId: '', routineDayId: routineDayId, sessionDate: DateTime.now()),
      setLogs: setLogsResult.getOrElse((_) => []),
      exercises: exercisesResult.getOrElse((_) => []),
    ));
  }
}
