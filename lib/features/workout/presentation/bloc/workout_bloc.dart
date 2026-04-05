import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/active_session_service.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/routine.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../domain/usecases/get_assigned_routines.dart';
import '../../domain/usecases/get_weekly_plan.dart';
import '../../domain/usecases/save_set_log.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/set_log.dart';
import 'workout_event.dart';
import 'workout_state.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final GetAssignedRoutines getAssignedRoutines;
  final GetWeeklyPlan getWeeklyPlan;
  final SaveSetLog saveSetLog;
  final WorkoutRepository repository;
  final ActiveSessionService activeSessionService;

  WorkoutBloc({
    required this.getAssignedRoutines,
    required this.getWeeklyPlan,
    required this.saveSetLog,
    required this.repository,
    required this.activeSessionService,
  }) : super(WorkoutInitial()) {
    
    // ─── Cargar rutinas ──────────────────────────────────────
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
        final result = await getWeeklyPlan(
          userId: event.userId,
          routineId: event.routineId,
          weekStart: event.weekStart,
        );

        if (result.isLeft()) {
          emit(WorkoutError(result.fold((failure) => failure.message, (_) => 'Error al cargar plan semanal')));
          return;
        }

        final days = result.getOrElse((_) => []);
        final insightsResult = await repository.getWeeklyInsights(
          routineId: event.routineId,
          weekStart: event.weekStart,
        );

        if (insightsResult.isRight()) {
          emit(WeeklyPlanLoaded(
            days,
            event.weekStart,
            insights: insightsResult.getOrElse((_) => throw StateError('Unreachable')),
          ));
        } else {
          emit(WeeklyPlanLoaded(
            days,
            event.weekStart,
            insightsError: insightsResult.fold((f) => f.message, (_) => null),
          ));
        }
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
          repository.getExistingSession(event.userId, event.routineDayId, event.sessionDate),
          repository.getRecentSessionsForDay(event.userId, event.routineDayId, event.sessionDate, limit: 3),
          repository.getActiveSessionForUser(event.userId),
        ]);

        final exercises = (results[0] as Either<Failure, List<Exercise>>).getOrElse((_) => []);
        final session = (results[1] as Either<Failure, WorkoutSession?>).getOrElse((_) => null);
        final recentSessions = (results[2] as Either<Failure, List<WorkoutSession>>).getOrElse((_) => []);
        final activeSession = (results[3] as Either<Failure, WorkoutSession?>).getOrElse((_) => null);

        final Map<String, List<SetLog>> recentLogs = {};
        for (final s in recentSessions) {
          final res = await repository.getSessionSetLogs(s.id);
          recentLogs[s.id] = res.getOrElse((_) => []);
        }

        final perfRes = await _fetchPreloadedRecords(exercises);

        // Si ya existe sesión del día (completada o no), abrirla directamente.
        // Cuando completedAt != null la UI entra en modo solo lectura y muestra resultados.
        if (session != null) {
          final logsRes = await repository.getSessionSetLogs(session.id);
          final setLogs = logsRes.getOrElse((_) => []);
          emit(DayWorkoutStarted(
            session,
            exercises,
            setLogs: setLogs,
            lastPerformances: perfRes,
            recentSessions: recentSessions,
            recentSessionsLogs: recentLogs,
          ));
        } else {
          bool hasAnotherActiveSession = false;
          String? anotherActiveSessionDayName;

          if (activeSession != null &&
              activeSession.completedAt == null &&
              activeSession.routineDayId != event.routineDayId) {
            hasAnotherActiveSession = true;
            final nameRes = await repository.getRoutineDayNameById(activeSession.routineDayId);
            anotherActiveSessionDayName = nameRes.getOrElse((_) => null);
          }

          // No hay sesión en curso: mostrar pantalla de preinicio
          emit(DayInfoLoaded(
            exercises: exercises,
            userId: event.userId,
            routineDayId: event.routineDayId,
            sessionDate: event.sessionDate,
            existingSession: session, // null o completada de otro día
            recentSessions: recentSessions,
            recentSessionsLogs: recentLogs,
            hasAnotherActiveSession: hasAnotherActiveSession,
            anotherActiveSessionDayName: anotherActiveSessionDayName,
            lastPerformances: perfRes,
          ));
        }
      } catch (e) {
        emit(WorkoutError('Error al cargar día: $e'));
      }
    });

    // ─── Confirmar inicio: ahora sí se crea la sesión ─────────
    on<ConfirmStartWorkout>((event, emit) async {
      emit(WorkoutLoading());
      try {
        final sessionResult = await repository.startWorkoutForDay(
          event.userId, event.routineDayId, event.sessionDate,
        );
        final session = sessionResult.getOrElse(
          (_) => throw Exception('No se pudo iniciar la sesión'),
        );

        final effectiveRoutineDayId = session.routineDayId;
        final effectiveSessionDate = session.sessionDate;

        final results = await Future.wait([
          repository.getExercisesForDay(effectiveRoutineDayId),
          repository.getRecentSessionsForDay(event.userId, effectiveRoutineDayId, effectiveSessionDate, limit: 3),
          repository.getSessionSetLogs(session.id),
        ]);

        final exercises = (results[0] as Either<Failure, List<Exercise>>).getOrElse((_) => []);
        final recentSessions = (results[1] as Either<Failure, List<WorkoutSession>>).getOrElse((_) => []);
        final setLogs = (results[2] as Either<Failure, List<SetLog>>).getOrElse((_) => []);

        final Map<String, List<SetLog>> recentLogs = {};
        for (final s in recentSessions) {
          final res = await repository.getSessionSetLogs(s.id);
          recentLogs[s.id] = res.getOrElse((_) => []);
        }

        final perfRes = await _fetchPreloadedRecords(exercises);

        String routineDayName = event.routineDayName;
        if (effectiveRoutineDayId != event.routineDayId) {
          final nameRes = await repository.getRoutineDayNameById(effectiveRoutineDayId);
          routineDayName = nameRes.getOrElse((_) => null) ?? routineDayName;

          // Guardrail: si el backend devolvió una sesión activa de otro día,
          // volvemos a la vista de preinicio con bloqueo explícito.
          final fallbackRecentSessions = (await repository.getRecentSessionsForDay(
            event.userId,
            event.routineDayId,
            event.sessionDate,
            limit: 3,
          )).getOrElse((_) => <WorkoutSession>[]);

          final Map<String, List<SetLog>> fallbackRecentLogs = {};
          for (final s in fallbackRecentSessions) {
            final res = await repository.getSessionSetLogs(s.id);
            fallbackRecentLogs[s.id] = res.getOrElse((_) => <SetLog>[]);
          }

          final requestedExercises =
              (await repository.getExercisesForDay(event.routineDayId))
                  .getOrElse((_) => <Exercise>[]);
          final requestedPerf = await _fetchPreloadedRecords(requestedExercises);

          emit(DayInfoLoaded(
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
          ));
          return;
        }

        // Persistir contexto para reanudación automática
        await activeSessionService.save(
          sessionId: session.id,
          routineDayId: effectiveRoutineDayId,
          userId: event.userId,
          sessionDate: effectiveSessionDate,
          routineDayName: routineDayName,
        );

        emit(DayWorkoutStarted(
          session,
          exercises,
          setLogs: setLogs,
          lastPerformances: perfRes,
          recentSessions: recentSessions,
          recentSessionsLogs: recentLogs,
        ));
      } catch (e) {
        emit(WorkoutError('Error al iniciar sesión: $e'));
      }
    });

    // ─── Verificar sesión activa al abrir app ───────────────────
    on<CheckActiveSession>((event, emit) async {
      try {
        final ctx = activeSessionService.getContext();

        // Siempre validar con remoto para cubrir reinstalaciones, limpieza de cache
        // o contexto local perdido.
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
          final nameRes = await repository.getRoutineDayNameById(session.routineDayId);
          routineDayName = nameRes.getOrElse((_) => null) ?? 'Sesion en curso';

          await activeSessionService.save(
            sessionId: session.id,
            routineDayId: session.routineDayId,
            userId: session.userId,
            sessionDate: session.sessionDate,
            routineDayName: routineDayName,
          );
        }

        emit(ActiveSessionDetected(
          sessionId: session.id,
          routineDayId: session.routineDayId,
          userId: session.userId,
          sessionDate: session.sessionDate,
          routineDayName: routineDayName,
        ));
      } catch (_) {
        // Fallo silencioso: no bloquear al usuario
      }
    });
    on<AddSetLogEvent>((event, emit) async {
      final currentState = state;
      try {
        await repository.saveSetLog(event.setLog);
        
        if (currentState is DayWorkoutStarted) {
          final newLogs = List<SetLog>.from(currentState.setLogs);
          final idx = newLogs.indexWhere((l) => l.exerciseId == event.setLog.exerciseId && l.setIndex == event.setLog.setIndex);
          if (idx != -1) {
            newLogs[idx] = event.setLog;
          } else {
            newLogs.add(event.setLog);
          }
          emit(DayWorkoutStarted(
            currentState.session, 
            currentState.exercises, 
            setLogs: newLogs, 
            lastPerformances: currentState.lastPerformances,
            recentSessions: currentState.recentSessions,
            recentSessionsLogs: currentState.recentSessionsLogs,
          ));
        }
      } catch (e) {
        emit(WorkoutError('Error al guardar serie: $e'));
      }
    });

    // ─── Rendimiento anterior (Legacy, mantenido para compatibilidad) ──
    on<FetchLastExercisePerformance>((event, emit) async {
      try {
        final result = await repository.getLastExercisePerformance(event.exerciseId);
        result.fold((failure) => emit(WorkoutError(failure.message)), (lastSet) => emit(ExercisePerformanceLoaded(lastSet)));
      } catch (e) {
        emit(WorkoutError('Error al cargar rendimiento: $e'));
      }
    });

    on<ResetWorkout>((event, emit) => emit(WorkoutInitial()));

    on<FinishWorkoutSession>((event, emit) async {
      emit(WorkoutLoading());
      try {
        final result = await repository.finishWorkoutSession(
          event.sessionId, 
          coachingAnalysis: event.coachingAnalysis,
        );
        // No usar fold con lambda async: el handler terminaría antes de que
        // el Future se resuelva y emit lanzaría _AssertionError.
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

    on<CreateOrUpdateRoutine>((event, emit) async {
      emit(WorkoutLoading());
      try {
        final routine = Routine(
          id: event.id ?? '',
          name: event.name,
          exerciseCount: 0,
        );
        final result = await repository.saveRoutine(routine);
        result.fold(
          (failure) => emit(WorkoutError(failure.message)),
          (_) async {
            // Refrescamos la lista de rutinas para el usuario actual
            add(FetchAssignedRoutines(event.userId));
          },
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
        result.fold(
          (failure) => emit(WorkoutError(failure.message)),
          (_) {
            emit(const ManagementSuccess('Día guardado correctamente'));
            add(FetchWeeklyPlan(
              userId: event.userId, 
              routineId: event.routineId, 
              weekStart: DateTime.now(), // Refresh current week
            ));
          },
        );
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
          (_) => null, // El UI debería manejar la navegación atrás o refresco
        );
      } catch (e) {
        emit(WorkoutError('Error al eliminar día: $e'));
      }
    });

    on<ToggleExerciseInDay>((event, emit) async {
      try {
        await repository.toggleExerciseInDay(event.dayId, event.exerciseId);
        emit(const ManagementSuccess('Ejercicio actualizado'));
        add(FetchWeeklyPlan(
          userId: event.userId,
          routineId: event.routineId,
          weekStart: DateTime.now(),
        ));
      } catch (e) {
        emit(WorkoutError('Error al alternar ejercicio: $e'));
      }
    });

    on<ReorderExercises>((event, emit) async {
      try {
        await repository.reorderExercisesInDay(event.dayId, event.exerciseIds);
        emit(const ManagementSuccess('Orden actualizado'));
        add(FetchWeeklyPlan(
          userId: event.userId,
          routineId: event.routineId,
          weekStart: DateTime.now(),
        ));
      } catch (e) {
        emit(WorkoutError('Error al reordenar ejercicios: $e'));
      }
    });

    on<UpdateExerciseTarget>((event, emit) async {
      final currentState = state;
      if (currentState is DayWorkoutStarted) {
        try {
          // 1. Actualizar localmente el estado actual
          final newExercises = currentState.exercises.map((e) {
            if (e.id == event.exerciseId) {
              return e.copyWith(
                targetWeight: event.targetWeight,
                targetReps: event.targetReps,
              );
            }
            return e;
          }).toList();

          // 2. Persistir en repositorio
          await repository.updateExerciseTarget(currentState.session.routineDayId, event.exerciseId, event.targetWeight, event.targetReps);

          // 3. Emitir nuevo estado con los ejercicios actualizados
          emit(DayWorkoutStarted(
            currentState.session,
            newExercises,
            setLogs: currentState.setLogs,
            lastPerformances: currentState.lastPerformances,
            recentSessions: currentState.recentSessions,
            recentSessionsLogs: currentState.recentSessionsLogs,
          ));
        } catch (e) {
          emit(WorkoutError('Error al actualizar objetivo: $e'));
        }
      }
    });
  }

  // Helper para precargar récords de todos los ejercicios del día
  Future<Map<String, SetLog?>> _fetchPreloadedRecords(List<Exercise> exercises) async {
    final Map<String, SetLog?> performances = {};
    if (exercises.isEmpty) return performances;
    
    final futures = exercises.map((e) => repository.getLastExercisePerformance(e.id)).toList();
    final results = await Future.wait(futures);
    
    for (int i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];
        final result = results[i];
        performances[exercise.id] = result.getOrElse((_) => null);
    }
    return performances;
  }
}
