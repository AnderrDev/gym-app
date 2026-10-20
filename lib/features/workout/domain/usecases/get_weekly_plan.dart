import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/routine_day.dart';
import 'package:gym_flutter/core/utils/calendar_dates.dart';
import '../repositories/workout_repository.dart';

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
    final weekEnd = AppCalendar.addDays(weekStart, 6);
    final sessionsResult = await repository.getWeekSessions(
      userId,
      weekStart,
      weekEnd,
    );
    // Sin sesiones conocidas todos los días saldrían "sin entrenar" y se
    // invitaría a repetir un entreno ya hecho: mejor propagar el error.
    final sessionsFailure = sessionsResult.fold((f) => f, (_) => null);
    if (sessionsFailure != null) return Left(sessionsFailure);
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
      DateTime? lastSessionDate;
      if (sessionsForDay.isEmpty) {
        status = WorkoutDayStatus.pending;
      } else {
        final activeSession = sessionsForDay
            .where((s) => s.completedAt == null)
            .toList();

        if (activeSession.isNotEmpty) {
          activeSession.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
          lastSessionDate = activeSession.first.sessionDate;
          status = WorkoutDayStatus.inProgress;
        } else {
          sessionsForDay.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
          final latestClosedSession = sessionsForDay.first;
          lastSessionDate = latestClosedSession.sessionDate;

          final isFullyCompleted =
              latestClosedSession.completedSetsCount >=
              (latestClosedSession.totalTargetSets > 0
                  ? latestClosedSession.totalTargetSets
                  : day.targetSetsCount);
          status = isFullyCompleted
              ? WorkoutDayStatus.completed
              : WorkoutDayStatus.completedPartial;
        }
      }

      return day.copyWith(status: status, lastSessionDate: lastSessionDate);
    }).toList();

    return Right(enrichedDays);
  }
}
