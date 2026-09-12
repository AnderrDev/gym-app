import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_day/routine_day_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_day/routine_day_state.dart';

/// Bloc del subdominio "antes de iniciar la sesión".
///
/// Carga ejercicios, sesión previa, sesiones recientes y last-performance.
/// Detecta si hay una sesión activa en otro día (para advertir al usuario).
class RoutineDayBloc extends Bloc<RoutineDayEvent, RoutineDayState> {
  RoutineDayBloc({required this.repository}) : super(const RoutineDayState()) {
    on<LoadRoutineDay>(_onLoad);
    on<ResetRoutineDay>((_, emit) => emit(const RoutineDayState()));
  }

  final WorkoutRepository repository;

  Future<void> _onLoad(
    LoadRoutineDay event,
    Emitter<RoutineDayState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RoutineDayStatus.loading,
        userId: event.userId,
        routineDayId: event.routineDayId,
        sessionDate: event.sessionDate,
        clearErrorMessage: true,
      ),
    );

    try {
      final results = await Future.wait([
        repository.getExercisesForDay(event.routineDayId),
        repository.getExistingSession(
          event.userId,
          event.routineDayId,
          event.sessionDate,
        ),
        repository.getRecentSessionsForDay(
          event.userId,
          event.routineDayId,
          event.sessionDate,
          limit: 3,
        ),
        repository.getActiveSessionForUser(event.userId),
      ]);

      final exercises = (results[0] as Either<Failure, List<Exercise>>)
          .getOrElse((_) => const []);
      var existingSession = (results[1] as Either<Failure, WorkoutSession?>)
          .getOrElse((_) => null);
      // Una sesión nueva se registra con la fecha de hoy aunque se abra
      // desde un día anterior del calendario. Si no hay sesión en la fecha
      // exacta, buscamos la de este día de rutina dentro de la semana —
      // mismo criterio que usa el dashboard para marcarlo completado.
      existingSession ??= await _sessionInWeekFor(
        userId: event.userId,
        routineDayId: event.routineDayId,
        date: event.sessionDate,
      );
      final recentSessions =
          (results[2] as Either<Failure, List<WorkoutSession>>).getOrElse(
            (_) => const [],
          );
      final activeSession = (results[3] as Either<Failure, WorkoutSession?>)
          .getOrElse((_) => null);

      final recentLogsRes = await repository.getSetLogsForSessions(
        recentSessions.map((s) => s.id).toList(),
      );
      final recentLogs = recentLogsRes.getOrElse(
        (_) => <String, List<SetLog>>{},
      );

      final lastPerformances = await _fetchPreloadedRecords(exercises);

      var hasAnotherActiveSession = false;
      String? anotherActiveSessionDayName;
      if (activeSession != null &&
          activeSession.completedAt == null &&
          activeSession.routineDayId != event.routineDayId) {
        hasAnotherActiveSession = true;
        final nameRes = await repository.getRoutineDayNameById(
          activeSession.routineDayId,
        );
        anotherActiveSessionDayName = nameRes.getOrElse((_) => null);
      }

      emit(
        state.copyWith(
          status: RoutineDayStatus.ready,
          exercises: exercises,
          existingSession: existingSession,
          clearExistingSession: existingSession == null,
          recentSessions: recentSessions,
          recentSessionsLogs: recentLogs,
          lastPerformances: lastPerformances,
          hasAnotherActiveSession: hasAnotherActiveSession,
          anotherActiveSessionDayName: anotherActiveSessionDayName,
          clearAnotherActiveSessionDayName: anotherActiveSessionDayName == null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RoutineDayStatus.failure,
          errorMessage: 'Error al cargar día: $e',
        ),
      );
    }
  }

  /// Sesión de [routineDayId] dentro de la semana (lunes→domingo) que
  /// contiene [date]. Prefiere la abierta; si no, la más reciente.
  Future<WorkoutSession?> _sessionInWeekFor({
    required String userId,
    required String routineDayId,
    required DateTime date,
  }) async {
    final dayOnly = DateTime(date.year, date.month, date.day);
    final weekStart = dayOnly.subtract(Duration(days: dayOnly.weekday - 1));
    // Best-effort: si la consulta falla, la pantalla sigue usable en
    // prestart en vez de caer a `failure`.
    final List<WorkoutSession> sessions;
    try {
      sessions =
          (await repository.getWeekSessions(
                userId,
                weekStart,
                weekStart.add(const Duration(days: 6)),
              ))
              .getOrElse((_) => const [])
              .where((s) => s.routineDayId == routineDayId)
              .toList();
    } catch (_) {
      return null;
    }
    if (sessions.isEmpty) return null;
    final open = sessions.where((s) => s.completedAt == null);
    if (open.isNotEmpty) return open.first;
    sessions.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    return sessions.first;
  }

  Future<Map<String, SetLog?>> _fetchPreloadedRecords(
    List<Exercise> exercises,
  ) async {
    if (exercises.isEmpty) return const {};
    final exerciseIds = exercises.map((e) => e.id).toList();
    final result = await repository.getLastExercisePerformances(exerciseIds);
    final performances = Map<String, SetLog?>.from(
      result.getOrElse((_) => const <String, SetLog?>{}),
    );
    for (final id in exerciseIds) {
      performances.putIfAbsent(id, () => null);
    }
    return performances;
  }
}
