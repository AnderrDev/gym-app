import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/core/notifications/active_workout_notifier.dart';
import 'package:gym_flutter/core/services/active_session_service.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_state.dart';

/// Bloc del subdominio "sesión activa". Maneja el ciclo de vida de una
/// `WorkoutSession`: start, save sets, update target, finish.
class ActiveWorkoutBloc extends Bloc<ActiveWorkoutEvent, ActiveWorkoutState> {
  ActiveWorkoutBloc({
    required this.repository,
    required this.activeSessionService,
    required this.notifier,
  }) : super(const ActiveWorkoutState()) {
    on<StartActiveWorkout>(_onStart);
    on<ResumeActiveWorkout>(_onResume);
    on<SaveActiveSetLog>(_onSaveSet);
    on<UnsaveActiveSetLog>(_onUnsaveSet);
    on<UpdateActiveExerciseTarget>(_onUpdateTarget);
    on<FinishActiveWorkout>(_onFinish);
    on<ResetActiveWorkout>((_, emit) async {
      emit(const ActiveWorkoutState());
      await notifier.onEnded();
    });
  }

  final WorkoutRepository repository;
  final ActiveSessionService activeSessionService;
  final ActiveWorkoutNotifier notifier;

  int _totalTargetSetsFor(List<Exercise> exercises) =>
      exercises.fold<int>(0, (sum, e) => sum + e.targetSets);

  Future<void> _onStart(
    StartActiveWorkout event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ActiveWorkoutStatus.starting,
        clearErrorMessage: true,
      ),
    );
    try {
      final sessionResult = await repository.startWorkoutForDay(
        event.userId,
        event.routineDayId,
        event.sessionDate,
      );
      final session = sessionResult.getOrElse(
        (_) => throw Exception('No se pudo iniciar la sesión'),
      );

      // El backend puede devolver una sesión existente cuyo `routineDayId`
      // difiera del solicitado (caso de sesión activa pendiente). En ese
      // caso emitimos `failure` con un mensaje claro — la página decide
      // si redirigir.
      if (session.routineDayId != event.routineDayId) {
        emit(
          state.copyWith(
            status: ActiveWorkoutStatus.failure,
            errorMessage:
                'Ya hay una sesión activa en otro día. Termínala antes de iniciar esta.',
          ),
        );
        return;
      }

      final results = await Future.wait([
        repository.getExercisesForDay(session.routineDayId),
        repository.getRecentSessionsForDay(
          event.userId,
          session.routineDayId,
          session.sessionDate,
          limit: 3,
        ),
        repository.getSessionSetLogs(session.id),
      ]);

      final exercises = (results[0] as Either<Failure, List<Exercise>>)
          .getOrElse((_) => const []);
      final recentSessions =
          (results[1] as Either<Failure, List<WorkoutSession>>).getOrElse(
            (_) => const [],
          );
      final setLogs = (results[2] as Either<Failure, List<SetLog>>).getOrElse(
        (_) => const [],
      );

      final recentLogsRes = await repository.getSetLogsForSessions(
        recentSessions.map((s) => s.id).toList(),
      );
      final recentLogs = recentLogsRes.getOrElse(
        (_) => <String, List<SetLog>>{},
      );

      final lastPerformances = await _fetchLastPerformances(exercises);

      await activeSessionService.save(
        sessionId: session.id,
        routineDayId: session.routineDayId,
        userId: event.userId,
        sessionDate: session.sessionDate,
        routineDayName: event.routineDayName,
      );

      await notifier.onStarted(
        dayName: event.routineDayName,
        sessionStartedAt: DateTime.now(),
        totalSets: _totalTargetSetsFor(exercises),
      );

      emit(
        state.copyWith(
          status: ActiveWorkoutStatus.running,
          session: session,
          exercises: exercises,
          setLogs: setLogs,
          lastPerformances: lastPerformances,
          recentSessions: recentSessions,
          recentSessionsLogs: recentLogs,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ActiveWorkoutStatus.failure,
          errorMessage: 'Error al iniciar sesión: $e',
        ),
      );
    }
  }

  Future<void> _onResume(
    ResumeActiveWorkout event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ActiveWorkoutStatus.starting,
        clearErrorMessage: true,
      ),
    );
    try {
      final logsRes = await repository.getSessionSetLogs(event.session.id);
      final setLogs = logsRes.getOrElse((_) => const []);
      await notifier.onStarted(
        dayName: _resumedDayName(event),
        sessionStartedAt: DateTime.now(),
        totalSets: _totalTargetSetsFor(event.exercises),
      );
      if (setLogs.isNotEmpty) {
        await notifier.onProgress(completedSets: setLogs.length);
      }
      emit(
        state.copyWith(
          status: ActiveWorkoutStatus.running,
          session: event.session,
          exercises: event.exercises,
          setLogs: setLogs,
          lastPerformances: event.lastPerformances,
          recentSessions: event.recentSessions,
          recentSessionsLogs: event.recentSessionsLogs,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ActiveWorkoutStatus.failure,
          errorMessage: 'Error al reanudar sesión: $e',
        ),
      );
    }
  }

  String _resumedDayName(ResumeActiveWorkout event) {
    // El evento `ResumeActiveWorkout` no trae el routineDayName explícito;
    // cae sobre el contexto persistido como fallback.
    return activeSessionService.getContext()?.routineDayName ?? 'Entrenamiento';
  }

  Future<void> _onSaveSet(
    SaveActiveSetLog event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    if (state.session == null) return;
    try {
      await repository.saveSetLog(event.setLog);
      final newLogs = List<SetLog>.from(state.setLogs);
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
      emit(state.copyWith(setLogs: newLogs));
      await notifier.onProgress(completedSets: newLogs.length);
    } catch (e) {
      emit(
        state.copyWith(
          status: ActiveWorkoutStatus.failure,
          errorMessage: 'Error al guardar serie: $e',
        ),
      );
    }
  }

  Future<void> _onUnsaveSet(
    UnsaveActiveSetLog event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    if (state.session == null) return;
    final result = await repository.deleteSetLog(
      sessionId: event.sessionId,
      exerciseId: event.exerciseId,
      setIndex: event.setIndex,
    );
    if (result.isLeft()) {
      final failure = result.swap().getOrElse((_) => throw StateError(''));
      emit(
        state.copyWith(
          status: ActiveWorkoutStatus.failure,
          errorMessage: 'Error al desmarcar serie: ${failure.message}',
        ),
      );
      return;
    }
    final newLogs = state.setLogs
        .where(
          (l) =>
              !(l.exerciseId == event.exerciseId &&
                  l.setIndex == event.setIndex),
        )
        .toList();
    emit(state.copyWith(setLogs: newLogs));
    await notifier.onProgress(completedSets: newLogs.length);
  }

  Future<void> _onUpdateTarget(
    UpdateActiveExerciseTarget event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    final session = state.session;
    if (session == null) return;
    try {
      final newExercises = state.exercises.map((e) {
        if (e.id == event.exerciseId) {
          return e.copyWith(
            targetWeight: event.targetWeight,
            targetReps: event.targetReps,
          );
        }
        return e;
      }).toList();
      await repository.updateExerciseTarget(
        session.routineDayId,
        event.exerciseId,
        event.targetWeight,
        event.targetReps,
      );
      emit(state.copyWith(exercises: newExercises));
    } catch (e) {
      emit(
        state.copyWith(
          status: ActiveWorkoutStatus.failure,
          errorMessage: 'Error al actualizar objetivo: $e',
        ),
      );
    }
  }

  Future<void> _onFinish(
    FinishActiveWorkout event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ActiveWorkoutStatus.finishing,
        clearErrorMessage: true,
      ),
    );
    try {
      final result = await repository.finishWorkoutSession(
        event.sessionId,
        coachingAnalysis: event.coachingAnalysis,
      );
      if (result.isLeft()) {
        emit(
          state.copyWith(
            status: ActiveWorkoutStatus.failure,
            errorMessage: result.fold((f) => f.message, (_) => 'Error'),
          ),
        );
        return;
      }
      await activeSessionService.clear();
      await notifier.onEnded();
      emit(state.copyWith(status: ActiveWorkoutStatus.finished));
    } catch (e) {
      emit(
        state.copyWith(
          status: ActiveWorkoutStatus.failure,
          errorMessage: 'Error al finalizar sesión: $e',
        ),
      );
    }
  }

  Future<Map<String, SetLog?>> _fetchLastPerformances(
    List<Exercise> exercises,
  ) async {
    if (exercises.isEmpty) return const {};
    final ids = exercises.map((e) => e.id).toList();
    final result = await repository.getLastExercisePerformances(ids);
    final perf = Map<String, SetLog?>.from(
      result.getOrElse((_) => const <String, SetLog?>{}),
    );
    for (final id in ids) {
      perf.putIfAbsent(id, () => null);
    }
    return perf;
  }
}
