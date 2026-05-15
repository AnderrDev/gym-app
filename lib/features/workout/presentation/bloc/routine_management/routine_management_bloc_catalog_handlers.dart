part of 'routine_management_bloc.dart';

/// Handlers del subdominio "catálogo de rutinas y ejercicios":
/// carga del listado global, asignación a usuario y consulta del catálogo
/// de ejercicios. Conviven con [RoutineManagementBloc] vía `part of`.
extension RoutineCatalogHandlers on RoutineManagementBloc {
  Future<void> handleLoadAllRoutines(
    LoadAllRoutines event,
    Emitter<RoutineManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RoutineManagementStatus.loading,
        clearErrorMessage: true,
      ),
    );
    // Catálogo + assigned en paralelo. La asignada es opcional (depende del
    // userId); si falla, no rompemos el listado — simplemente no pintamos
    // badge "ACTIVA".
    final routinesFuture = getAllRoutines();
    final assignedFuture =
        event.userId != null ? getAssignedRoutines(event.userId!) : null;
    final routinesResult = await routinesFuture;
    final assignedResult =
        assignedFuture == null ? null : await assignedFuture;

    routinesResult.fold(
      (failure) => emit(
        state.copyWith(
          status: RoutineManagementStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (routines) {
        final activeId = assignedResult?.fold<String?>(
          (_) => null,
          (assigned) => assigned.isNotEmpty ? assigned.first.id : null,
        );
        emit(
          state.copyWith(
            status: RoutineManagementStatus.ready,
            routines: routines,
            activeRoutineId: activeId,
            clearActiveRoutineId: activeId == null,
          ),
        );
      },
    );
  }

  Future<void> handleAssign(
    AssignRoutineToUser event,
    Emitter<RoutineManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        submissionStatus: RoutineManagementSubmissionStatus.submitting,
        clearErrorMessage: true,
      ),
    );
    final result = await assignRoutine(event.userId, event.routineId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          submissionStatus: RoutineManagementSubmissionStatus.failure,
          lastAction: RoutineManagementAction.assignRoutine,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          submissionStatus: RoutineManagementSubmissionStatus.success,
          lastAction: RoutineManagementAction.assignRoutine,
          feedbackMessage: 'Rutina activada correctamente',
          activeRoutineId: event.routineId,
        ),
      ),
    );
  }

  Future<void> handleLoadExerciseCatalog(
    LoadExerciseCatalog event,
    Emitter<RoutineManagementState> emit,
  ) async {
    emit(
      state.copyWith(
        catalogStatus: ExerciseCatalogStatus.loading,
        clearErrorMessage: true,
      ),
    );
    final result = await getExercisesCatalog(
      muscleGroup: event.muscleGroup,
      search: event.search,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          catalogStatus: ExerciseCatalogStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (items) => emit(
        state.copyWith(
          catalogStatus: ExerciseCatalogStatus.ready,
          exerciseCatalog: items,
        ),
      ),
    );
  }
}
