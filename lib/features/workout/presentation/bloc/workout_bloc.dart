import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/active_session_service.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/routine_day.dart';
import '../../domain/entities/weekly_insights.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../domain/usecases/get_assigned_routines.dart';
import '../../domain/usecases/get_weekly_plan.dart';
import '../../domain/usecases/save_set_log.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/set_log.dart';
import 'workout_event.dart';
import 'workout_state.dart';
import '../../domain/usecases/assign_routine.dart';
import '../../domain/usecases/get_all_routines.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final GetAssignedRoutines getAssignedRoutines;
  final GetWeeklyPlan getWeeklyPlan;
  final SaveSetLog saveSetLog;
  final WorkoutRepository repository;
  final ActiveSessionService activeSessionService;
  final AssignRoutine assignRoutine;
  final GetAllRoutines getAllRoutines;

  WorkoutBloc({
    required this.getAssignedRoutines,
    required this.getWeeklyPlan,
    required this.saveSetLog,
    required this.repository,
    required this.activeSessionService,
    required this.assignRoutine,
    required this.getAllRoutines,
  }) : super(WorkoutInitial()) {
    // ─── Cargar rutinas asignadas ─────────────────────────────
    on<FetchAssignedRoutines>((event, emit) async {
      emit(WorkoutLoading());
      try {
        final result = await getAssignedRoutines(event.userId);
        result.fold(
          (failure) => emit(WorkoutError(failure.message)),
          (routines) => emit(RoutinesLoaded(routines)),
        );
      } catch (e) {
        emit(WorkoutError('Error al cargar rutinas: $e'));
      }
    });

    // ─── Cargar plan semanal ───────────────────────────────────
    on<FetchWeeklyPlan>((event, emit) async {
      emit(WorkoutLoading());
      try {
        final normalizedWeekStart = event.weekStart.subtract(
          Duration(days: event.weekStart.weekday - 1),
        );
        final results = await Future.wait([
          getWeeklyPlan(
            userId: event.userId,
            routineId: event.routineId,
            weekStart: normalizedWeekStart,
          ),
          repository.getWeeklyInsights(
            routineId: event.routineId,
            weekStart: normalizedWeekStart,
          ),
          repository.getRoutineById(event.routineId),
        ]);

        final daysResult = results[0] as Either<Failure, List<RoutineDay>>;
        final insightsResult = results[1] as Either<Failure, WeeklyInsights>;
        final routineResult = results[2] as Either<Failure, Routine>;

        if (daysResult.isLeft()) {
          emit(
            WorkoutError(
              daysResult.fold((f) => f.message, (_) => 'Error charging days'),
            ),
          );
          return;
        }

        emit(
          WeeklyPlanLoaded(
            daysResult.getOrElse((_) => []),
            normalizedWeekStart,
            routine: routineResult.getOrElse(
              (_) => throw Exception('Routine not found'),
            ),
            insights: insightsResult.getOrElse(
              (_) => throw Exception('Insights error'),
            ),
          ),
        );
      } catch (e) {
        emit(WorkoutError('Error al cargar plan semanal: $e'));
      }
    });

    // ─── Cargar info del día (SIN crear sesión) ───────────────
    on<LoadDayInfo>((event, emit) async {
      emit(WorkoutLoading());
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
            .getOrElse((_) => []);
        final session = (results[1] as Either<Failure, WorkoutSession?>)
            .getOrElse((_) => null);
        final recentSessions =
            (results[2] as Either<Failure, List<WorkoutSession>>).getOrElse(
              (_) => [],
            );
        final activeSession = (results[3] as Either<Failure, WorkoutSession?>)
            .getOrElse((_) => null);

        final recentLogsRes = await repository.getSetLogsForSessions(
          recentSessions.map((s) => s.id).toList(),
        );
        final recentLogs = recentLogsRes.getOrElse(
          (_) => <String, List<SetLog>>{},
        );

        final perfRes = await _fetchPreloadedRecords(exercises);

        if (session != null) {
          final logsRes = await repository.getSessionSetLogs(session.id);
          final setLogs = logsRes.getOrElse((_) => []);
          emit(
            DayWorkoutStarted(
              session,
              exercises,
              setLogs: setLogs,
              lastPerformances: perfRes,
              recentSessions: recentSessions,
              recentSessionsLogs: recentLogs,
            ),
          );
        } else {
          bool hasAnotherActiveSession = false;
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
            DayInfoLoaded(
              exercises: exercises,
              userId: event.userId,
              routineDayId: event.routineDayId,
              sessionDate: event.sessionDate,
              existingSession: session,
              recentSessions: recentSessions,
              recentSessionsLogs: recentLogs,
              hasAnotherActiveSession: hasAnotherActiveSession,
              anotherActiveSessionDayName: anotherActiveSessionDayName,
              lastPerformances: perfRes,
            ),
          );
        }
      } catch (e) {
        emit(WorkoutError('Error al cargar día: $e'));
      }
    });

    on<ConfirmStartWorkout>((event, emit) async {
      emit(WorkoutLoading());
      try {
        final sessionResult = await repository.startWorkoutForDay(
          event.userId,
          event.routineDayId,
          event.sessionDate,
        );
        final session = sessionResult.getOrElse(
          (_) => throw Exception('No se pudo iniciar la sesión'),
        );

        final effectiveRoutineDayId = session.routineDayId;
        final effectiveSessionDate = session.sessionDate;

        final results = await Future.wait([
          repository.getExercisesForDay(effectiveRoutineDayId),
          repository.getRecentSessionsForDay(
            event.userId,
            effectiveRoutineDayId,
            effectiveSessionDate,
            limit: 3,
          ),
          repository.getSessionSetLogs(session.id),
        ]);

        final exercises = (results[0] as Either<Failure, List<Exercise>>)
            .getOrElse((_) => []);
        final recentSessions =
            (results[1] as Either<Failure, List<WorkoutSession>>).getOrElse(
              (_) => [],
            );
        final setLogs = (results[2] as Either<Failure, List<SetLog>>).getOrElse(
          (_) => [],
        );

        final recentLogsRes = await repository.getSetLogsForSessions(
          recentSessions.map((s) => s.id).toList(),
        );
        final recentLogs = recentLogsRes.getOrElse(
          (_) => <String, List<SetLog>>{},
        );

        final perfRes = await _fetchPreloadedRecords(exercises);

        String routineDayName = event.routineDayName;
        if (effectiveRoutineDayId != event.routineDayId) {
          final nameRes = await repository.getRoutineDayNameById(
            effectiveRoutineDayId,
          );
          routineDayName = nameRes.getOrElse((_) => null) ?? routineDayName;

          final fallbackRecentSessions =
              (await repository.getRecentSessionsForDay(
                event.userId,
                event.routineDayId,
                event.sessionDate,
                limit: 3,
              )).getOrElse((_) => <WorkoutSession>[]);

          final fallbackRecentLogsRes = await repository.getSetLogsForSessions(
            fallbackRecentSessions.map((s) => s.id).toList(),
          );
          final fallbackRecentLogs = fallbackRecentLogsRes.getOrElse(
            (_) => <String, List<SetLog>>{},
          );

          final requestedExercises = (await repository.getExercisesForDay(
            event.routineDayId,
          )).getOrElse((_) => <Exercise>[]);
          final requestedPerf = await _fetchPreloadedRecords(
            requestedExercises,
          );

          emit(
            DayInfoLoaded(
              exercises: requestedExercises,
              userId: event.userId,
              routineDayId: event.routineDayId,
              sessionDate: event.sessionDate,
              existingSession: null,
              recentSessions: fallbackRecentSessions,
              recentSessionsLogs: fallbackRecentLogs,
              hasAnotherActiveSession: true,
              anotherActiveSessionDayName: routineDayName,
              lastPerformances: requestedPerf,
            ),
          );
          return;
        }

        await activeSessionService.save(
          sessionId: session.id,
          routineDayId: effectiveRoutineDayId,
          userId: event.userId,
          sessionDate: effectiveSessionDate,
          routineDayName: routineDayName,
        );

        emit(
          DayWorkoutStarted(
            session,
            exercises,
            setLogs: setLogs,
            lastPerformances: perfRes,
            recentSessions: recentSessions,
            recentSessionsLogs: recentLogs,
          ),
        );
      } catch (e) {
        emit(WorkoutError('Error al iniciar sesión: $e'));
      }
    });

    on<CheckActiveSession>((event, emit) async {
      try {
        final ctx = activeSessionService.getContext();
        final result = await repository.getActiveSessionForUser(event.userId);
        final session = result.getOrElse((_) => null);

        if (session == null || session.completedAt != null) {
          await activeSessionService.clear();
          return;
        }

        String routineDayName = 'Sesion en curso';
        if (ctx != null && ctx.sessionId == session.id) {
          routineDayName = ctx.routineDayName;
        } else {
          final nameRes = await repository.getRoutineDayNameById(
            session.routineDayId,
          );
          routineDayName = nameRes.getOrElse((_) => null) ?? 'Sesion en curso';

          await activeSessionService.save(
            sessionId: session.id,
            routineDayId: session.routineDayId,
            userId: session.userId,
            sessionDate: session.sessionDate,
            routineDayName: routineDayName,
          );
        }

        emit(
          ActiveSessionDetected(
            sessionId: session.id,
            routineDayId: session.routineDayId,
            userId: session.userId,
            sessionDate: session.sessionDate,
            routineDayName: routineDayName,
          ),
        );
      } catch (_) {}
    });

    on<AddSetLogEvent>((event, emit) async {
      final currentState = state;
      try {
        await repository.saveSetLog(event.setLog);

        if (currentState is DayWorkoutStarted) {
          final newLogs = List<SetLog>.from(currentState.setLogs);
          final idx = newLogs.indexWhere(
            (l) =>
                l.exerciseId == event.setLog.exerciseId &&
                l.setIndex == event.setLog.setIndex,
          );
          if (idx != -1) {
            newLogs[idx] = event.setLog;
          } else {
            newLogs.add(event.setLog);
          }
          emit(
            DayWorkoutStarted(
              currentState.session,
              currentState.exercises,
              setLogs: newLogs,
              lastPerformances: currentState.lastPerformances,
              recentSessions: currentState.recentSessions,
              recentSessionsLogs: currentState.recentSessionsLogs,
            ),
          );
        }
      } catch (e) {
        emit(WorkoutError('Error al guardar serie: $e'));
      }
    });

    on<FinishWorkoutSession>((event, emit) async {
      emit(WorkoutLoading());
      try {
        final result = await repository.finishWorkoutSession(
          event.sessionId,
          coachingAnalysis: event.coachingAnalysis,
        );
        if (result.isLeft()) {
          emit(WorkoutError(result.fold((f) => f.message, (_) => 'Error')));
        } else {
          await activeSessionService.clear();
          emit(WorkoutFinishedSuccess());
        }
      } catch (e) {
        emit(WorkoutError('Error al finalizar sesión: $e'));
      }
    });

    // ─── Gestión de Rutinas ──────────────────────────────────────────

    on<FetchAllRoutines>((event, emit) async {
      emit(WorkoutLoading());
      try {
        final result = await getAllRoutines();
        result.fold(
          (failure) => emit(WorkoutError(failure.message)),
          (routines) => emit(AllRoutinesLoaded(routines)),
        );
      } catch (e) {
        emit(WorkoutError('Error al cargar catálogo de rutinas: $e'));
      }
    });

    on<AssignRoutineEvent>((event, emit) async {
      emit(WorkoutLoading());
      try {
        final result = await assignRoutine(event.userId, event.routineId);
        result.fold((failure) => emit(WorkoutError(failure.message)), (_) {
          emit(const ManagementSuccess('Rutina activada correctamente'));
          add(FetchAssignedRoutines(event.userId));
        });
      } catch (e) {
        emit(WorkoutError('Error al activar rutina: $e'));
      }
    });

    on<CreateOrUpdateRoutine>((event, emit) async {
      emit(WorkoutLoading());
      try {
        final routine = Routine(
          id: event.id ?? '',
          name: event.name,
          exerciseCount: 0,
          isPublic: event.isPublic,
        );
        final result = await repository.saveRoutine(routine);
        result.fold(
          (failure) => emit(WorkoutError(failure.message)),
          (_) => add(FetchAssignedRoutines(event.userId)),
        );
      } catch (e) {
        emit(WorkoutError('Error al guardar rutina: $e'));
      }
    });

    on<DeleteRoutine>((event, emit) async {
      emit(WorkoutLoading());
      try {
        final result = await repository.deleteRoutine(event.routineId);
        result.fold(
          (failure) => emit(WorkoutError(failure.message)),
          (_) => add(FetchAssignedRoutines(event.userId)),
        );
      } catch (e) {
        emit(WorkoutError('Error al eliminar rutina: $e'));
      }
    });

    on<SaveRoutineDay>((event, emit) async {
      emit(WorkoutLoading());
      try {
        final result = await repository.saveRoutineDay(event.day);
        result.fold((failure) => emit(WorkoutError(failure.message)), (_) {
          emit(const ManagementSuccess('Día guardado correctamente'));
          add(
            FetchWeeklyPlan(
              userId: event.userId,
              routineId: event.routineId,
              weekStart: DateTime.now(),
            ),
          );
        });
      } catch (e) {
        emit(WorkoutError('Error al guardar día: $e'));
      }
    });

    on<DeleteRoutineDay>((event, emit) async {
      emit(WorkoutLoading());
      try {
        final result = await repository.deleteRoutineDay(event.dayId);
        result.fold(
          (failure) => emit(WorkoutError(failure.message)),
          (_) => null,
        );
      } catch (e) {
        emit(WorkoutError('Error al eliminar día: $e'));
      }
    });

    on<ToggleExerciseInDay>((event, emit) async {
      try {
        await repository.toggleExerciseInDay(event.dayId, event.exerciseId);
        emit(const ManagementSuccess('Ejercicio actualizado'));
        add(
          FetchWeeklyPlan(
            userId: event.userId,
            routineId: event.routineId,
            weekStart: DateTime.now(),
          ),
        );
      } catch (e) {
        emit(WorkoutError('Error al alternar ejercicio: $e'));
      }
    });

    on<ReorderExercises>((event, emit) async {
      try {
        await repository.reorderExercisesInDay(event.dayId, event.exerciseIds);
        emit(const ManagementSuccess('Orden actualizado'));
        add(
          FetchWeeklyPlan(
            userId: event.userId,
            routineId: event.routineId,
            weekStart: DateTime.now(),
          ),
        );
      } catch (e) {
        emit(WorkoutError('Error al reordenar ejercicios: $e'));
      }
    });

    on<UpdateExerciseTarget>((event, emit) async {
      final currentState = state;
      if (currentState is DayWorkoutStarted) {
        try {
          final newExercises = currentState.exercises.map((e) {
            if (e.id == event.exerciseId) {
              return e.copyWith(
                targetWeight: event.targetWeight,
                targetReps: event.targetReps,
              );
            }
            return e;
          }).toList();

          await repository.updateExerciseTarget(
            currentState.session.routineDayId,
            event.exerciseId,
            event.targetWeight,
            event.targetReps,
          );

          emit(
            DayWorkoutStarted(
              currentState.session,
              newExercises,
              setLogs: currentState.setLogs,
              lastPerformances: currentState.lastPerformances,
              recentSessions: currentState.recentSessions,
              recentSessionsLogs: currentState.recentSessionsLogs,
            ),
          );
        } catch (e) {
          emit(WorkoutError('Error al actualizar objetivo: $e'));
        }
      }
    });

    // Legacy support
    on<FetchLastExercisePerformance>((event, emit) async {
      try {
        final result = await repository.getLastExercisePerformance(
          event.exerciseId,
        );
        result.fold(
          (failure) => emit(WorkoutError(failure.message)),
          (lastSet) => emit(ExercisePerformanceLoaded(lastSet)),
        );
      } catch (e) {
        emit(WorkoutError('Error al cargar rendimiento: $e'));
      }
    });

    on<ResetWorkout>((event, emit) => emit(WorkoutInitial()));
  }

  Future<Map<String, SetLog?>> _fetchPreloadedRecords(
    List<Exercise> exercises,
  ) async {
    if (exercises.isEmpty) return {};

    final exerciseIds = exercises.map((e) => e.id).toList();
    final result = await repository.getLastExercisePerformances(exerciseIds);
    final performances = result.getOrElse((_) => <String, SetLog?>{});

    for (final id in exerciseIds) {
      performances.putIfAbsent(id, () => null);
    }

    return performances;
  }
}
