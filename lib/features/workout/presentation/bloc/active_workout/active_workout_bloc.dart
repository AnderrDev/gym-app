import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/notifications/active_workout_notifier.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/core/services/active_session_service.dart';
import 'package:gym_flutter/core/services/workout_draft_service.dart';
import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:gym_flutter/core/utils/clock.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/usecases/adapt_session_exercise.dart';
import 'package:gym_flutter/features/workout/domain/workout_completion.dart';
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
    this.draftService,
    Clock clock = const SystemClock(),
  }) : _clock = clock,
       super(const ActiveWorkoutState()) {
    // Una sola cola evita que guardar/desmarcar/finalizar se pisen mientras
    // esperamos almacenamiento local o backend.
    on<ActiveWorkoutEvent>(
      _handleEvent,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  final WorkoutRepository repository;
  final ActiveSessionService activeSessionService;
  final ActiveWorkoutNotifier notifier;
  final WorkoutDraftService? draftService;
  final Clock _clock;

  Future<void> _handleEvent(
    ActiveWorkoutEvent event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    switch (event) {
      case StartActiveWorkout():
        await _onStart(event, emit);
      case ResumeActiveWorkout():
        await _onResume(event, emit);
      case SaveActiveSetLog():
        await _onSaveSet(event, emit);
      case UnsaveActiveSetLog():
        await _onUnsaveSet(event, emit);
      case UpdateActiveExerciseTarget():
        await _onUpdateTarget(event, emit);
      case AdaptActiveWorkoutExercise():
        await _onAdaptExercise(event, emit);
      case FinishActiveWorkout():
        await _onFinish(event, emit);
      case ResetActiveWorkout():
        emit(const ActiveWorkoutState());
        await notifier.onEnded();
    }
  }

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
      final today = _today();
      final session = (await repository.startWorkoutForDay(
        event.userId,
        event.routineDayId,
        today,
      )).getOrElse((failure) => throw failure);

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

      final actualDate = session.sessionDate;
      if (DateTime(actualDate.year, actualDate.month, actualDate.day) !=
          today) {
        emit(
          state.copyWith(
            status: ActiveWorkoutStatus.failure,
            errorMessage:
                'Hay una sesión anterior pendiente. Vuelve y continúa esa sesión para finalizarla antes de entrenar hoy.',
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
          setDrafts: draftService?.load(session.userId, session.id) ?? const [],
          lastPerformances: ctx.lastPerformances,
          recentSessions: ctx.recentSessions,
          recentSessionsLogs: ctx.recentSessionsLogs,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ActiveWorkoutStatus.failure,
          errorMessage: _describe('No se pudo iniciar el entrenamiento', e),
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
      final exercises = (await repository.getSessionExercises(
        event.session.id,
        routineDayId: event.session.routineDayId,
      )).getOrElse((failure) => throw failure);
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
        totalSets: _totalTargetSetsFor(exercises),
      );
      if (setLogs.isNotEmpty) {
        await notifier.onProgress(completedSets: setLogs.length);
      }
      emit(
        state.copyWith(
          status: ActiveWorkoutStatus.running,
          session: event.session,
          exercises: exercises,
          setLogs: setLogs,
          setDrafts:
              draftService?.load(event.session.userId, event.session.id) ??
              const [],
          lastPerformances: await fetchLastPerformances(repository, exercises),
          recentSessions: event.recentSessions,
          recentSessionsLogs: event.recentSessionsLogs,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ActiveWorkoutStatus.failure,
          errorMessage: _describe('No se pudo reanudar el entrenamiento', e),
        ),
      );
    }
  }

  Future<void> _onSaveSet(
    SaveActiveSetLog event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    if (state.session == null || event.setLog.sessionId != state.session!.id) {
      return;
    }
    await _rememberDraft(event.setLog, emit);
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
    if (state.session == null || event.sessionId != state.session!.id) return;
    final previousLogs = state.setLogs;
    final removed = previousLogs
        .where(
          (l) =>
              l.exerciseId == event.exerciseId && l.setIndex == event.setIndex,
        )
        .firstOrNull;
    if (removed == null) return;
    if (!await _rememberDraft(removed, emit)) {
      emit(
        state.copyWith(
          setLogs: List<SetLog>.from(previousLogs),
          actionError:
              'No se pudo conservar el peso editado. Intenta desmarcar de nuevo.',
        ),
      );
      return;
    }
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

  Future<bool> _rememberDraft(
    SetLog log,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    final drafts = List<SetLog>.from(state.setDrafts)
      ..removeWhere(
        (l) => l.exerciseId == log.exerciseId && l.setIndex == log.setIndex,
      )
      ..add(log);
    emit(state.copyWith(setDrafts: drafts));
    try {
      await draftService?.save(state.session!.userId, log);
      return true;
    } catch (e) {
      AppLogger.instance.warning(
        'No se pudo conservar el borrador de serie: $e',
      );
      return false;
    }
  }

  Future<void> _onUpdateTarget(
    UpdateActiveExerciseTarget event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    final session = state.session;
    if (session == null) return;
    if (session.completedAt != null) return;
    final result = await repository.updateSessionExerciseTarget(
      session.id,
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
      (exercises) => emit(state.copyWith(exercises: exercises)),
    );
  }

  Future<void> _onAdaptExercise(
    AdaptActiveWorkoutExercise event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    final session = state.session;
    if (!state.isRunning || session == null || session.completedAt != null) {
      return;
    }
    emit(state.copyWith(isAdapting: true));
    final result = await AdaptSessionExercise(repository)(
      session.id,
      event.exerciseId,
      targetSets: event.targetSets,
      targetReps: event.targetReps,
      targetWeight: event.targetWeight,
      replaceExerciseId: event.replaceExerciseId,
    );
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          isAdapting: false,
          actionError:
              'No se pudo adaptar el entrenamiento: ${failure.message}',
        ),
      ),
      (exercises) async {
        final performances = await fetchLastPerformances(repository, exercises);
        emit(
          state.copyWith(
            exercises: exercises,
            lastPerformances: performances,
            isAdapting: false,
          ),
        );
        await notifier.onPlanChanged(
          totalSets: totalTargetSets(exercises),
          completedSets: completedTargetSets(exercises, state.setLogs),
        );
      },
    );
  }

  Future<void> _onFinish(
    FinishActiveWorkout event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    final current = state.session;
    if (!state.isRunning ||
        current == null ||
        current.id != event.sessionId ||
        current.completedAt != null) {
      return;
    }
    emit(
      state.copyWith(
        status: ActiveWorkoutStatus.finishing,
        clearErrorMessage: true,
      ),
    );
    try {
      final result = await repository.finishWorkoutSession(
        event.sessionId,
        // El servidor consulta los logs ya guardados y el historial del mismo
        // ejercicio, aunque antes se entrenara en otro día de la rutina.
        coachingAnalysis: null,
      );
      if (result.isLeft()) {
        // La sesión sigue abierta y con sus series: se vuelve al entreno y
        // se avisa, en vez de una pantalla de error sin salida.
        emit(
          state.copyWith(
            status: ActiveWorkoutStatus.running,
            actionError: _describe(
              'No se pudo finalizar',
              result.fold((f) => f, (_) => null),
            ),
          ),
        );
        return;
      }
      await activeSessionService.clear();
      final session = state.session;
      if (session != null) {
        try {
          await draftService?.clear(session.userId, session.id);
        } catch (e) {
          AppLogger.instance.warning(
            'No se pudieron limpiar los borradores: $e',
          );
        }
      }
      await notifier.onEnded();
      // Best-effort: el coaching ya está guardado en la sesión. Sin él la
      // pantalla cierra igual (p. ej. el cierre quedó en el outbox).
      final coaching = (await repository.getSessionCoaching(
        event.sessionId,
      )).getOrElse((_) => const []);
      emit(
        state.copyWith(
          status: ActiveWorkoutStatus.finished,
          setDrafts: const [],
          finalCoaching: coaching,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ActiveWorkoutStatus.running,
          actionError: _describe('No se pudo finalizar', e),
        ),
      );
    }
  }

  /// Mensaje para el usuario: los `Failure` ya traen texto legible; otras
  /// excepciones no se muestran en crudo ("Exception: …").
  String _describe(String action, Object? error) {
    if (error is Failure && error.message.isNotEmpty) {
      return '$action: ${error.message}';
    }
    AppLogger.instance.warning('$action: $error');
    return '$action. Revisa tu conexión e inténtalo de nuevo.';
  }
}
