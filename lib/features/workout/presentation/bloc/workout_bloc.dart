import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
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

  WorkoutBloc({
    required this.getAssignedRoutines,
    required this.getWeeklyPlan,
    required this.saveSetLog,
    required this.repository,
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
        result.fold(
          (failure) => emit(WorkoutError(failure.message)),
          (days) => emit(WeeklyPlanLoaded(days, event.weekStart)),
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
          repository.getExistingSession(event.userId, event.routineDayId, event.sessionDate),
          repository.getRecentSessionsForDay(event.userId, event.routineDayId, event.sessionDate, limit: 3),
        ]);

        final exercises = (results[0] as Either<Failure, List<Exercise>>).getOrElse((_) => []);
        final session = (results[1] as Either<Failure, WorkoutSession?>).getOrElse((_) => null);
        final recentSessions = (results[2] as Either<Failure, List<WorkoutSession>>).getOrElse((_) => []);
        
        final Map<String, List<SetLog>> recentLogs = {};
        for (final s in recentSessions) {
          final res = await repository.getSessionSetLogs(s.id);
          recentLogs[s.id] = res.getOrElse((_) => []);
        }

        final perfRes = await _fetchPreloadedRecords(exercises);

        WorkoutSession? activeSession = session;
        if (activeSession == null) {
          final sessionResult = await repository.startWorkoutForDay(event.userId, event.routineDayId, event.sessionDate);
          activeSession = sessionResult.getOrElse((_) => throw Exception('Failed to start session'));
        }

        final logsRes = await repository.getSessionSetLogs(activeSession.id);
        final setLogs = logsRes.getOrElse((_) => []);

        emit(DayWorkoutStarted(
          activeSession, 
          exercises, 
          setLogs: setLogs, 
          lastPerformances: perfRes, 
          recentSessions: recentSessions, 
          recentSessionsLogs: recentLogs,
        ));
      } catch (e) {
        emit(WorkoutError('Error al cargar día: $e'));
      }
    });



    // ─── Registrar serie (fire & forget) ─────────────────────
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
        result.fold(
          (failure) => emit(WorkoutError(failure.message)),
          (_) => emit(WorkoutFinishedSuccess()),
        );
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
