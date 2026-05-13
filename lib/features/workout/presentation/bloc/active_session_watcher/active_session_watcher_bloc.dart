import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/services/active_session_service.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_state.dart';

/// Bloc cross-cutting que detecta si el usuario tiene una sesión activa en
/// backend al arrancar la app. El dashboard lo consume para mostrar el banner
/// de "reanudar" y disparar la navegación.
class ActiveSessionWatcherBloc
    extends Bloc<ActiveSessionWatcherEvent, ActiveSessionWatcherState> {
  ActiveSessionWatcherBloc({
    required this.repository,
    required this.activeSessionService,
  }) : super(const ActiveSessionWatcherState()) {
    on<CheckActiveSession>(_onCheck);
    on<ClearActiveSession>(_onClear);
  }

  final WorkoutRepository repository;
  final ActiveSessionService activeSessionService;

  Future<void> _onCheck(
    CheckActiveSession event,
    Emitter<ActiveSessionWatcherState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ActiveSessionWatcherStatus.checking,
        clearErrorMessage: true,
      ),
    );
    try {
      final ctx = activeSessionService.getContext();
      final result = await repository.getActiveSessionForUser(event.userId);
      final session = result.getOrElse((_) => null);

      if (session == null || session.completedAt != null) {
        await activeSessionService.clear();
        emit(
          state.copyWith(
            status: ActiveSessionWatcherStatus.none,
            clearSession: true,
          ),
        );
        return;
      }

      String routineDayName = 'Sesion en curso';
      if (ctx != null && ctx.sessionId == session.id) {
        routineDayName = ctx.routineDayName;
      } else {
        final nameRes = await repository.getRoutineDayNameById(
          session.routineDayId,
        );
        routineDayName = nameRes.getOrElse((_) => null) ?? routineDayName;
        await activeSessionService.save(
          sessionId: session.id,
          routineDayId: session.routineDayId,
          userId: session.userId,
          sessionDate: session.sessionDate,
          routineDayName: routineDayName,
        );
      }

      emit(
        state.copyWith(
          status: ActiveSessionWatcherStatus.detected,
          session: ActiveSessionInfo(
            sessionId: session.id,
            userId: session.userId,
            routineDayId: session.routineDayId,
            routineDayName: routineDayName,
            sessionDate: session.sessionDate,
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ActiveSessionWatcherStatus.failure,
          errorMessage: 'No pudimos verificar la sesión activa: $e',
        ),
      );
    }
  }

  Future<void> _onClear(
    ClearActiveSession event,
    Emitter<ActiveSessionWatcherState> emit,
  ) async {
    await activeSessionService.clear();
    emit(
      const ActiveSessionWatcherState(status: ActiveSessionWatcherStatus.none),
    );
  }
}
