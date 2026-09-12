import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/notifications/active_workout_notifier.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/core/services/active_session_service.dart';
import 'package:gym_flutter/core/utils/clock.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/_active_workout_loader.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_state.dart';

/// Bloc del subdominio "sesión activa". Maneja el ciclo de vida de una
/// `WorkoutSession`: start, save sets, update target, finish.
class ActiveWorkoutBloc extends Bloc<ActiveWorkoutEvent, ActiveWorkoutState> {
  ActiveWorkoutBloc({
    required this.repository,
    required this.activeSessionService,
    required this.notifier,
    Clock clock = const SystemClock(),
  }) : _clock = clock,
       super(const ActiveWorkoutState()) {
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
  final Clock _clock;

  DateTime _today() {
    final now = _clock.now();
    return DateTime(now.year, now.month, now.day);
  }

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
      // Siempre hoy: iniciar desde un día pasado del calendario no debe
      // registrar el entrenamiento con esa fecha.
      final session = (await repository.startWorkoutForDay(
        event.userId,
        event.routineDayId,
        _today(),
      )).getOrElse((_) => throw Exception('No se pudo iniciar la sesión'));

      // El backend puede devolver una sesión existente cuyo `routineDayId`
      // difiera del solicitado (sesión activa pendiente). Emitimos `failure`
      // con un mensaje claro — la página decide si redirigir.
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

      final ctx = await loadActiveWorkoutContext(
        repository,
        event.userId,
        session,
      );

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
        totalSets: _totalTargetSetsFor(ctx.exercises),
      );

      emit(
        state.copyWith(
          status: ActiveWorkoutStatus.running,
          session: session,
          exercises: ctx.exercises,
          setLogs: ctx.setLogs,
          lastPerformances: ctx.lastPerformances,
          recentSessions: ctx.recentSessions,
          recentSessionsLogs: ctx.recentSessionsLogs,
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
      final setLogs = (await repository.getSessionSetLogs(
        event.session.id,
      )).getOrElse((_) => const []);
      // El evento `ResumeActiveWorkout` no trae el routineDayName explícito;
      // cae sobre el contexto persistido como fallback.
      final dayName =
          activeSessionService.getContext()?.routineDayName ?? 'Entrenamiento';
      await notifier.onStarted(
        dayName: dayName,
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

  Future<void> _onSaveSet(
    SaveActiveSetLog event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    if (state.session == null) return;
    // Optimista: la serie aparece marcada ya mismo y se revierte si el
    // guardado falla. Antes el resultado del repo se ignoraba y una serie
    // podía quedar marcada en pantalla sin haberse guardado en ningún lado.
    final previousLogs = state.setLogs;
    final newLogs = List<SetLog>.from(previousLogs);
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

    final result = await repository.saveSetLog(event.setLog);
    if (result.isLeft()) {
      final failure = result.swap().getOrElse((_) => const ServerFailure());
      emit(
        state.copyWith(
          setLogs: previousLogs,
          actionError:
              'No se pudo guardar la serie ${event.setLog.setIndex}: '
              '${failure.message}',
        ),
      );
      return;
    }
    await notifier.onProgress(completedSets: newLogs.length);
  }

  Future<void> _onUnsaveSet(
    UnsaveActiveSetLog event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    if (state.session == null) return;
    final previousLogs = state.setLogs;
    final newLogs = previousLogs
        .where(
          (l) =>
              !(l.exerciseId == event.exerciseId &&
                  l.setIndex == event.setIndex),
        )
        .toList();
    emit(state.copyWith(setLogs: newLogs));

    final result = await repository.deleteSetLog(
      sessionId: event.sessionId,
      exerciseId: event.exerciseId,
      setIndex: event.setIndex,
    );
    if (result.isLeft()) {
      final failure = result.swap().getOrElse((_) => const ServerFailure());
      // Error puntual: restauramos la serie y avisamos, sin tumbar la
      // sesión entera a `failure` (antes desmarcar sin red mataba la vista).
      emit(
        state.copyWith(
          setLogs: previousLogs,
          actionError:
              'No se pudo desmarcar la serie ${event.setIndex}: '
              '${failure.message}',
        ),
      );
      return;
    }
    await notifier.onProgress(completedSets: newLogs.length);
  }

  Future<void> _onUpdateTarget(
    UpdateActiveExerciseTarget event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    final session = state.session;
    if (session == null) return;
    final newExercises = state.exercises.map((e) {
      if (e.id == event.exerciseId) {
        return e.copyWith(
          targetWeight: event.targetWeight,
          targetReps: event.targetReps,
        );
      }
      return e;
    }).toList();

    final result = await repository.updateExerciseTarget(
      session.routineDayId,
      event.exerciseId,
      event.targetWeight,
      event.targetReps,
    );
    result.fold(
      // Si la rutina no es del usuario, RLS rechaza el update: antes la UI
      // decía "objetivo actualizado" igual.
      (failure) => emit(
        state.copyWith(
          actionError: 'No se pudo actualizar el objetivo: ${failure.message}',
        ),
      ),
      (_) => emit(state.copyWith(exercises: newExercises)),
    );
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
}
