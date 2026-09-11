part of 'routine_management_bloc.dart';

/// Handlers de edición de días dentro de una rutina: save/delete day,
/// add/remove/reorder/update de ejercicios. Tras cada mutación de
/// ejercicios refrescamos `editingDays` desde el backend para mantener
/// la UI consistente sin reinventar localmente la lógica de orden.
extension RoutineDayHandlers on RoutineManagementBloc {
  Future<void> handleSaveDay(
    SaveDay event,
    Emitter<RoutineManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        submissionStatus: RoutineManagementSubmissionStatus.submitting,
        clearErrorMessage: true,
      ),
    );
    final result = await saveRoutineDay(event.day);
    result.fold(
      (failure) => emit(
        state.copyWith(
          submissionStatus: RoutineManagementSubmissionStatus.failure,
          lastAction: RoutineManagementAction.saveDay,
          errorMessage: failure.message,
        ),
      ),
      (saved) {
        final wasUpdate =
            event.day.id.isNotEmpty && !event.day.id.startsWith('new_');
        final updatedDays = List<RoutineDay>.from(state.editingDays);
        if (wasUpdate) {
          final idx = updatedDays.indexWhere((d) => d.id == saved.id);
          if (idx >= 0) {
            updatedDays[idx] = saved;
          } else {
            updatedDays.add(saved);
          }
        } else {
          updatedDays.add(saved);
        }
        updatedDays.sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
        emit(
          state.copyWith(
            submissionStatus: RoutineManagementSubmissionStatus.success,
            lastAction: RoutineManagementAction.saveDay,
            feedbackMessage: 'Día guardado correctamente',
            editingDays: updatedDays,
            markClean: true,
          ),
        );
      },
    );
  }

  Future<void> handleDeleteDay(
    DeleteDay event,
    Emitter<RoutineManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        submissionStatus: RoutineManagementSubmissionStatus.submitting,
        clearErrorMessage: true,
      ),
    );
    final result = await deleteRoutineDay(event.dayId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          submissionStatus: RoutineManagementSubmissionStatus.failure,
          lastAction: RoutineManagementAction.deleteDay,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          submissionStatus: RoutineManagementSubmissionStatus.success,
          lastAction: RoutineManagementAction.deleteDay,
          feedbackMessage: 'Día eliminado correctamente',
          editingDays: state.editingDays
              .where((d) => d.id != event.dayId)
              .toList(),
        ),
      ),
    );
  }

  Future<void> handleAddExerciseToDay(
    AddExerciseToDayEvent event,
    Emitter<RoutineManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        submissionStatus: RoutineManagementSubmissionStatus.submitting,
        clearErrorMessage: true,
      ),
    );
    final result = await addExerciseToDay(
      event.dayId,
      event.exerciseId,
      targetSets: event.targetSets,
      targetReps: event.targetReps,
      targetWeight: event.targetWeight,
      restSeconds: event.restSeconds,
    );
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          submissionStatus: RoutineManagementSubmissionStatus.failure,
          lastAction: RoutineManagementAction.addExercise,
          errorMessage: failure.message,
        ),
      ),
      (_) async {
        await reloadEditingDays(event.userId, event.routineId, emit);
        emit(
          state.copyWith(
            submissionStatus: RoutineManagementSubmissionStatus.success,
            lastAction: RoutineManagementAction.addExercise,
            feedbackMessage: 'Ejercicio añadido',
            isDirty: true,
          ),
        );
      },
    );
  }

  Future<void> handleAddExercisesToDay(
    AddExercisesToDayEvent event,
    Emitter<RoutineManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        submissionStatus: RoutineManagementSubmissionStatus.submitting,
        clearErrorMessage: true,
      ),
    );
    final result = await addExercisesToDay(event.dayId, event.items);
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          submissionStatus: RoutineManagementSubmissionStatus.failure,
          lastAction: RoutineManagementAction.addExercises,
          errorMessage: failure.message,
        ),
      ),
      (_) async {
        await reloadEditingDays(event.userId, event.routineId, emit);
        emit(
          state.copyWith(
            submissionStatus: RoutineManagementSubmissionStatus.success,
            lastAction: RoutineManagementAction.addExercises,
            feedbackMessage: 'Ejercicios añadidos',
            isDirty: true,
          ),
        );
      },
    );
  }

  Future<void> handleRemoveExerciseFromDay(
    RemoveExerciseFromDayEvent event,
    Emitter<RoutineManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        submissionStatus: RoutineManagementSubmissionStatus.submitting,
        clearErrorMessage: true,
      ),
    );
    final result = await removeExerciseFromDay(event.dayId, event.exerciseId);
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          submissionStatus: RoutineManagementSubmissionStatus.failure,
          lastAction: RoutineManagementAction.removeExercise,
          errorMessage: failure.message,
        ),
      ),
      (_) async {
        await reloadEditingDays(event.userId, event.routineId, emit);
        emit(
          state.copyWith(
            submissionStatus: RoutineManagementSubmissionStatus.success,
            lastAction: RoutineManagementAction.removeExercise,
            feedbackMessage: 'Ejercicio eliminado',
            isDirty: true,
          ),
        );
      },
    );
  }

  Future<void> handleReorderExercises(
    ReorderExercises event,
    Emitter<RoutineManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        submissionStatus: RoutineManagementSubmissionStatus.submitting,
        clearErrorMessage: true,
      ),
    );
    final result = await reorderExercises(event.dayId, event.exerciseIds);
    result.fold(
      (failure) => emit(
        state.copyWith(
          submissionStatus: RoutineManagementSubmissionStatus.failure,
          lastAction: RoutineManagementAction.reorderExercises,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          submissionStatus: RoutineManagementSubmissionStatus.success,
          lastAction: RoutineManagementAction.reorderExercises,
          feedbackMessage: 'Orden actualizado',
          isDirty: true,
        ),
      ),
    );
  }

  Future<void> handleUpdateExerciseTarget(
    UpdateExerciseTargetEvent event,
    Emitter<RoutineManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        submissionStatus: RoutineManagementSubmissionStatus.submitting,
        clearErrorMessage: true,
      ),
    );
    final result = await updateExerciseTarget(
      event.dayId,
      event.exerciseId,
      event.targetWeight,
      event.targetReps,
      targetSets: event.targetSets,
      restSeconds: event.restSeconds,
    );
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          submissionStatus: RoutineManagementSubmissionStatus.failure,
          lastAction: RoutineManagementAction.updateExerciseTarget,
          errorMessage: failure.message,
        ),
      ),
      (_) async {
        await reloadEditingDays(event.userId, event.routineId, emit);
        emit(
          state.copyWith(
            submissionStatus: RoutineManagementSubmissionStatus.success,
            lastAction: RoutineManagementAction.updateExerciseTarget,
            feedbackMessage: 'Ejercicio actualizado',
            isDirty: true,
          ),
        );
      },
    );
  }

  /// Refresca `editingDays` desde el backend tras una mutación de ejercicios.
  Future<void> reloadEditingDays(
    String userId,
    String routineId,
    Emitter<RoutineManagementState> emit,
  ) async {
    final monday = RoutineManagementBloc.normalizeWeekStart(DateTime.now());
    final daysRes = await getWeeklyPlan(
      userId: userId,
      routineId: routineId,
      weekStart: monday,
    );
    daysRes.fold((_) => null, (days) {
      emit(state.copyWith(editingDays: days));
    });
  }
}
