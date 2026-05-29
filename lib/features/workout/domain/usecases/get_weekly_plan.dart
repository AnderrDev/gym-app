import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/routine_day.dart';
import '../repositories/workout_repository.dart';
import '../../data/models/routine_day_model.dart';

class GetWeeklyPlan {
  final WorkoutRepository repository;
  GetWeeklyPlan(this.repository);

  Future<Either<Failure, List<RoutineDay>>> call({
    required String userId,
    required String routineId,
    required DateTime weekStart,
  }) async {
    // 1. Obtener los días de la rutina
    final daysResult = await repository.getRoutineDays(routineId);
    if (daysResult.isLeft()) return daysResult;

    final days = daysResult.getOrElse((_) => []);
    if (days.isEmpty) return const Right([]);

    // 2. Obtener las sesiones de la semana
    final weekEnd = weekStart.add(const Duration(days: 6));
    final sessionsResult = await repository.getWeekSessions(
      userId,
      weekStart,
      weekEnd,
    );
    final sessions = sessionsResult.getOrElse((_) => []);

    // 3. Mapear cada día con su estado semanal:
    // - inProgress: existe sesión abierta (completedAt == null)
    // - completed: sesión cerrada y objetivo de series cumplido
    // - completedPartial: sesión cerrada sin cumplir objetivo completo
    // - pending: sin sesiones
    final enrichedDays = days.map((day) {
      final sessionsForDay = sessions
          .where((s) => s.routineDayId == day.id)
          .toList();

      WorkoutDayStatus status;
      if (sessionsForDay.isEmpty) {
        status = WorkoutDayStatus.pending;
      } else {
        final activeSession = sessionsForDay
            .where((s) => s.completedAt == null)
            .toList();

        if (activeSession.isNotEmpty) {
          status = WorkoutDayStatus.inProgress;
        } else {
          sessionsForDay.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
          final latestClosedSession = sessionsForDay.first;

          final isFullyCompleted =
              latestClosedSession.completedSetsCount >= day.targetSetsCount;
          status = isFullyCompleted
              ? WorkoutDayStatus.completed
              : WorkoutDayStatus.completedPartial;
        }
      }

      if (day is RoutineDayModel) {
        return day.copyWithStatus(status);
      }
      return day;
    }).toList();

    return Right(enrichedDays);
  }
}
