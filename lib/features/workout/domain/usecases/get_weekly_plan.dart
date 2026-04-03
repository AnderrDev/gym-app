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
    final sessionsResult = await repository.getWeekSessions(userId, weekStart, weekEnd);
    final sessions = sessionsResult.getOrElse((_) => []);

    // 3. Mapear cada día con su estado de completado
    final enrichedDays = days.map((day) {
      final sessionsForDay = sessions.where((s) => s.routineDayId == day.id).toList();

      WorkoutDayStatus status;
      if (sessionsForDay.isEmpty) {
        status = WorkoutDayStatus.pending;
      } else {
        final session = sessionsForDay.first;
        // A session is completed ONLY if all target sets are performed
        final isFullyCompleted = session.completedAt != null && 
                                  session.completedSetsCount >= day.targetSetsCount;
        
        status = isFullyCompleted ? WorkoutDayStatus.completed : WorkoutDayStatus.inProgress;
      }

      if (day is RoutineDayModel) {
        return day.copyWithStatus(status);
      }
      return day;
    }).toList();

    return Right(enrichedDays);
  }
}
