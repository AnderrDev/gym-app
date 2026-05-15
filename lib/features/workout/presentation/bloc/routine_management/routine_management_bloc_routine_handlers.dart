part of 'routine_management_bloc.dart';

/// Handlers de edición de rutinas: load para editar, save, delete y
/// limpieza del contexto. La gestión de días vive en `_day_handlers.dart`.
extension RoutineEditHandlers on RoutineManagementBloc {
  Future<void> handleLoadRoutineForEditing(
    LoadRoutineForEditing event,
    Emitter<RoutineManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RoutineManagementStatus.loading,
        clearErrorMessage: true,
      ),
    );
    final routineRes = await getRoutineById(event.routineId);
    final ent.Routine? routine = routineRes.fold((_) => null, (r) => r);
    if (routine == null) {
      emit(
        state.copyWith(
          status: RoutineManagementStatus.failure,
          errorMessage: routineRes.fold((f) => f.message, (_) => 'Error'),
        ),
      );
      return;
    }

    final monday = RoutineManagementBloc.normalizeWeekStart(DateTime.now());
    final daysRes = await getWeeklyPlan(
      userId: event.userId,
      routineId: event.routineId,
      weekStart: monday,
    );
    final days = daysRes.fold<List<RoutineDay>>((_) => const [], (d) => d);

    emit(
      state.copyWith(
        status: RoutineManagementStatus.ready,
        editingRoutine: routine,
        editingDays: days,
        markClean: true,
      ),
    );
  }

  Future<void> handleSaveRoutine(
    SaveRoutine event,
    Emitter<RoutineManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        submissionStatus: RoutineManagementSubmissionStatus.submitting,
        clearErrorMessage: true,
      ),
    );
    final routine = ent.Routine(
      id: event.id ?? '',
      name: event.name,
      exerciseCount: state.editingRoutine?.exerciseCount ?? 0,
      isPublic: event.isPublic,
      creatorId: state.editingRoutine?.creatorId,
      creatorName: state.editingRoutine?.creatorName,
    );
    final result = await saveRoutine(routine);
    result.fold(
      (failure) => emit(
        state.copyWith(
          submissionStatus: RoutineManagementSubmissionStatus.failure,
          lastAction: RoutineManagementAction.saveRoutine,
          errorMessage: failure.message,
        ),
      ),
      (saved) => emit(
        state.copyWith(
          submissionStatus: RoutineManagementSubmissionStatus.success,
          lastAction: RoutineManagementAction.saveRoutine,
          feedbackMessage: 'Rutina guardada correctamente',
          editingRoutine: saved,
          markClean: true,
        ),
      ),
    );
  }

  Future<void> handleDeleteRoutine(
    DeleteRoutine event,
    Emitter<RoutineManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        submissionStatus: RoutineManagementSubmissionStatus.submitting,
        clearErrorMessage: true,
      ),
    );
    final result = await deleteRoutine(event.routineId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          submissionStatus: RoutineManagementSubmissionStatus.failure,
          lastAction: RoutineManagementAction.deleteRoutine,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          submissionStatus: RoutineManagementSubmissionStatus.success,
          lastAction: RoutineManagementAction.deleteRoutine,
          feedbackMessage: 'Rutina eliminada correctamente',
          routines:
              state.routines.where((r) => r.id != event.routineId).toList(),
        ),
      ),
    );
  }

  void handleMarkDirty(
    MarkRoutineDirty event,
    Emitter<RoutineManagementState> emit,
  ) {
    if (!state.isDirty) {
      emit(state.copyWith(isDirty: true));
    }
  }

  void handleClearEditingContext(
    ClearEditingContext event,
    Emitter<RoutineManagementState> emit,
  ) {
    emit(
      state.copyWith(
        clearEditingRoutine: true,
        clearEditingDays: true,
        markClean: true,
      ),
    );
  }

  void handleAcknowledgeFeedback(
    AcknowledgeFeedback event,
    Emitter<RoutineManagementState> emit,
  ) {
    emit(
      state.copyWith(
        submissionStatus: RoutineManagementSubmissionStatus.idle,
        lastAction: RoutineManagementAction.none,
        clearFeedbackMessage: true,
        clearErrorMessage: true,
      ),
    );
  }
}
