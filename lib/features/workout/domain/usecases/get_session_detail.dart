import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

/// Lo que hace falta para enseñar una sesión pasada: sus series, los
/// ejercicios de esa sesión y el coaching que guardó el servidor.
class SessionDetail {
  const SessionDetail({
    required this.session,
    required this.logs,
    required this.exercises,
  });

  final WorkoutSession session;
  final List<SetLog> logs;
  final List<Exercise> exercises;
}

/// Carga el detalle de una sesión cerrada a partir de su id (el historial de
/// rutina sólo trae fecha y volumen). Sin coaching no falla: es opcional.
class GetSessionDetail {
  GetSessionDetail(this.repository);
  final WorkoutRepository repository;

  Future<Either<Failure, SessionDetail>> call({
    required String sessionId,
    required String userId,
    required String routineDayId,
    required DateTime sessionDate,
  }) async {
    final (logs, exercises, coaching) = await (
      repository.getSessionSetLogs(sessionId),
      repository.getSessionExercises(sessionId),
      repository.getSessionCoaching(sessionId),
    ).wait;
    return logs.flatMap(
      (l) => exercises.map(
        (e) => SessionDetail(
          session: WorkoutSession(
            id: sessionId,
            userId: userId,
            routineDayId: routineDayId,
            sessionDate: sessionDate,
            coachingAnalysis: coaching.toNullable(),
          ),
          logs: l,
          exercises: e,
        ),
      ),
    );
  }
}
