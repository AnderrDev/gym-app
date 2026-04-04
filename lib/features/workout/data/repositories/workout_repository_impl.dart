import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../datasources/workout_remote_data_source.dart';
import '../models/set_log_model.dart';
import '../models/routine_model.dart';
import '../models/routine_day_model.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/routine_day.dart';
import '../../domain/entities/set_log.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/coaching_analysis.dart';
import '../../domain/entities/exercise_history_session.dart';
import '../../domain/entities/routine_history_session.dart';
import '../../domain/repositories/workout_repository.dart';

/// Implementación 100% remota (Supabase).
/// El offline-first está desactivado temporalmente para validar el flujo completo.
class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutRemoteDataSource remoteDataSource;

  WorkoutRepositoryImpl({required this.remoteDataSource});

  // ─── Rutinas ──────────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, List<Routine>>> getAssignedRoutines(String userId) async {
    try {
      final result = await remoteDataSource.getAssignedRoutines(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ─── Días de rutina ───────────────────────────────────────────────────────
  @override
  Future<Either<Failure, List<RoutineDay>>> getRoutineDays(String routineId) async {
    try {
      final result = await remoteDataSource.getRoutineDays(routineId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ─── Ejercicios del día ───────────────────────────────────────────────────
  @override
  Future<Either<Failure, List<Exercise>>> getExercisesForDay(String routineDayId) async {
    try {
      final result = await remoteDataSource.getExercisesForDay(routineDayId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ─── Sesiones de la semana ────────────────────────────────────────────────
  @override
  Future<Either<Failure, List<WorkoutSession>>> getWeekSessions(
      String userId, DateTime weekStart, DateTime weekEnd) async {
    try {
      final result = await remoteDataSource.getWeekSessions(userId, weekStart, weekEnd);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ─── Buscar sesión existente (sin crear) ──────────────────────────────────
  @override
  Future<Either<Failure, WorkoutSession?>> getExistingSession(
      String userId, String routineDayId, DateTime sessionDate) async {
    try {
      final result = await remoteDataSource.getExistingSession(userId, routineDayId, sessionDate);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ─── Iniciar sesión ───────────────────────────────────────────────────────
  @override
  Future<Either<Failure, WorkoutSession>> startWorkoutForDay(
      String userId, String routineDayId, DateTime sessionDate) async {
    try {
      final result = await remoteDataSource.startWorkoutForDay(userId, routineDayId, sessionDate);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }


  // ─── Guardar serie ────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, void>> saveSetLog(SetLog setLog) async {
    try {
      final model = SetLogModel.fromEntity(setLog);
      await remoteDataSource.saveSetLog(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ─── Rendimiento anterior ─────────────────────────────────────────────────
  @override
  Future<Either<Failure, SetLog?>> getLastExercisePerformance(String exerciseId) async {
    try {
      final result = await remoteDataSource.getLastExercisePerformance(exerciseId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ─── Historial de sets de una sesión ──────────────────────────────────────
  @override
  Future<Either<Failure, List<SetLog>>> getSessionSetLogs(String sessionId) async {
    try {
      final result = await remoteDataSource.getSessionSetLogs(sessionId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ─── Asignar rutina a usuario ─────────────────────────────────────────────
  @override
  Future<Either<Failure, void>> assignRoutineToUser(String userId, String routineId) async {
    try {
      await remoteDataSource.assignRoutineToUser(userId, routineId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WorkoutSession>>> getRecentSessionsForDay(
      String userId, String routineDayId, DateTime beforeDate, {int limit = 3}) async {
    try {
      final result = await remoteDataSource.getRecentSessionsForDay(userId, routineDayId, beforeDate, limit: limit);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> finishWorkoutSession(String sessionId, {List<CoachingAnalysis>? coachingAnalysis}) async {
    try {
      await remoteDataSource.finishWorkoutSession(sessionId, coachingAnalysis: coachingAnalysis);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ExerciseHistorySession>>> getExerciseLogsHistory(String userId, String exerciseId) async {
    try {
      final rawData = await remoteDataSource.getExerciseLogsHistory(userId, exerciseId);
      
      // Agrupar por session_date
      final Map<String, List<SetLogModel>> grouped = {};
      
      for (var row in rawData) {
        final sessionData = row['workout_sessions'] as Map<String, dynamic>;
        final String sessionDateStr = sessionData['session_date'] as String;
        // Parse the session date down to just the day structure if needed, but it's usually YYYY-MM-DD
        final parsedDate = DateTime.tryParse(sessionDateStr);
        if (parsedDate == null) continue;
        
        final String dateKey = "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
        
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        
        grouped[dateKey]!.add(SetLogModel.fromJson(row));
      }
      
      final List<ExerciseHistorySession> sessions = grouped.entries.map((entry) {
        final date = DateTime.parse(entry.key);
        return ExerciseHistorySession(
          sessionDate: date,
          logs: entry.value,
        );
      }).toList();
      
      // Sort desc by date so the newest is first
      sessions.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
      
      return Right(sessions);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ─── Gestión de Rutinas ───────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> saveRoutine(Routine routine) async {
    try {
      final model = RoutineModel(
        id: routine.id,
        name: routine.name,
        exerciseCount: routine.exerciseCount,
      );
      await remoteDataSource.saveRoutine(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRoutine(String routineId) async {
    try {
      await remoteDataSource.deleteRoutine(routineId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveRoutineDay(RoutineDay day) async {
    try {
      final model = RoutineDayModel(
        id: day.id,
        routineId: day.routineId,
        name: day.name,
        dayOfWeek: day.dayOfWeek,
      );
      await remoteDataSource.saveRoutineDay(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRoutineDay(String dayId) async {
    try {
      await remoteDataSource.deleteRoutineDay(dayId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleExerciseInDay(String dayId, String exerciseId) async {
    try {
      await remoteDataSource.toggleExerciseInDay(dayId, exerciseId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reorderExercisesInDay(String dayId, List<String> exerciseIds) async {
    try {
      await remoteDataSource.reorderExercisesInDay(dayId, exerciseIds);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateExerciseTarget(String routineDayId, String exerciseId, double targetWeight, int targetReps) async {
    try {
      await remoteDataSource.updateExerciseTarget(routineDayId, exerciseId, targetWeight, targetReps);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RoutineHistorySession>>> getRoutineStats(String userId, String routineId) async {
    try {
      final rawData = await remoteDataSource.getRoutineStats(userId, routineId);
      
      final List<RoutineHistorySession> stats = rawData.map((row) {
        final sessionDateStr = row['session_date'] as String;
        final date = DateTime.parse(sessionDateStr);
        final routineDayData = row['routine_days'] as Map<String, dynamic>;
        
        // set_logs puede ser null si se acaba de empezar y no hay sets
        final logs = (row['set_logs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        
        double totalVolume = 0;
        int totalReps = 0;
        
        for (var log in logs) {
          final w = (log['actual_weight'] as num?)?.toDouble() ?? 0.0;
          final r = (log['actual_reps'] as int?) ?? 0;
          totalVolume += w * r;
          totalReps += r;
        }

        return RoutineHistorySession(
          sessionDate: date,
          routineDayId: row['routine_day_id'].toString(),
          routineDayName: routineDayData['name'].toString(),
          totalVolume: totalVolume,
          totalReps: totalReps,
          exerciseCount: logs.length, 
        );
      }).toList();

      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ─── Sync (no-op mientras offline está desactivado) ───────────────────────
  @override
  Future<Either<Failure, void>> syncPendingData() async {
    // Offline desactivado temporalmente
    return const Right(null);
  }
}
