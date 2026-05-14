import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/features/workout/domain/entities/routine.dart' as ent;
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/usecases/add_exercise_to_day.dart'
    as uc_add_one;
import 'package:gym_flutter/features/workout/domain/usecases/add_exercises_to_day.dart'
    as uc_add_many;
import 'package:gym_flutter/features/workout/domain/usecases/assign_routine.dart';
import 'package:gym_flutter/features/workout/domain/usecases/delete_routine.dart'
    as uc_del_routine;
import 'package:gym_flutter/features/workout/domain/usecases/delete_routine_day.dart'
    as uc_del_day;
import 'package:gym_flutter/features/workout/domain/usecases/get_all_routines.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_assigned_routines.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_exercises_catalog.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_routine_by_id.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_weekly_plan.dart';
import 'package:gym_flutter/features/workout/domain/usecases/remove_exercise_from_day.dart'
    as uc_remove_ex;
import 'package:gym_flutter/features/workout/domain/usecases/reorder_exercises.dart'
    as uc_reorder;
import 'package:gym_flutter/features/workout/domain/usecases/save_routine.dart'
    as uc_save_routine;
import 'package:gym_flutter/features/workout/domain/usecases/save_routine_day.dart'
    as uc_save_day;
import 'package:gym_flutter/features/workout/domain/usecases/update_exercise_target.dart'
    as uc_update_target;
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_state.dart';

/// Bloc del subdominio "gestión de rutinas": catálogo + edición + CRUD.
///
/// Inyecta use cases (no el repo directamente) para alinear con la
/// arquitectura limpia. Mantiene `feedbackMessage` para snackbars; la página
/// debe disparar `AcknowledgeFeedback` después de mostrarlo.
class RoutineManagementBloc
    extends Bloc<RoutineManagementEvent, RoutineManagementState> {
  RoutineManagementBloc({
    required this.assignRoutine,
    required this.getAllRoutines,
    required this.getAssignedRoutines,
    required this.getWeeklyPlan,
    required this.getRoutineById,
    required this.saveRoutine,
    required this.deleteRoutine,
    required this.saveRoutineDay,
    required this.deleteRoutineDay,
    required this.addExerciseToDay,
    required this.addExercisesToDay,
    required this.removeExerciseFromDay,
    required this.reorderExercises,
    required this.updateExerciseTarget,
    required this.getExercisesCatalog,
  }) : super(const RoutineManagementState()) {
    on<LoadAllRoutines>(_onLoadAllRoutines);
    on<LoadRoutineForEditing>(_onLoadRoutineForEditing);
    on<AssignRoutineToUser>(_onAssign);
    on<SaveRoutine>(_onSaveRoutine);
    on<DeleteRoutine>(_onDeleteRoutine);
    on<SaveDay>(_onSaveDay);
    on<DeleteDay>(_onDeleteDay);
    on<LoadExerciseCatalog>(_onLoadExerciseCatalog);
    on<AddExerciseToDayEvent>(_onAddExerciseToDay);
    on<AddExercisesToDayEvent>(_onAddExercisesToDay);
    on<RemoveExerciseFromDayEvent>(_onRemoveExerciseFromDay);
    on<ReorderExercises>(_onReorderExercises);
    on<UpdateExerciseTargetEvent>(_onUpdateExerciseTarget);
    on<MarkRoutineDirty>(_onMarkDirty);
    on<ClearEditingContext>(_onClearEditingContext);
    on<AcknowledgeFeedback>(_onAcknowledgeFeedback);
  }

  final AssignRoutine assignRoutine;
  final GetAllRoutines getAllRoutines;
  final GetAssignedRoutines getAssignedRoutines;
  final GetWeeklyPlan getWeeklyPlan;
  final GetRoutineById getRoutineById;
  final uc_save_routine.SaveRoutine saveRoutine;
  final uc_del_routine.DeleteRoutine deleteRoutine;
  final uc_save_day.SaveRoutineDay saveRoutineDay;
  final uc_del_day.DeleteRoutineDay deleteRoutineDay;
  final uc_add_one.AddExerciseToDay addExerciseToDay;
  final uc_add_many.AddExercisesToDay addExercisesToDay;
  final uc_remove_ex.RemoveExerciseFromDay removeExerciseFromDay;
  final uc_reorder.ReorderExercises reorderExercises;
  final uc_update_target.UpdateExerciseTarget updateExerciseTarget;
  final GetExercisesCatalog getExercisesCatalog;

  Future<void> _onLoadAllRoutines(
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
    final assignedFuture = event.userId != null
        ? getAssignedRoutines(event.userId!)
        : null;
    final routinesResult = await routinesFuture;
    final assignedResult = assignedFuture == null
        ? null
        : await assignedFuture;

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

  Future<void> _onLoadRoutineForEditing(
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

    final monday = _normalizeWeekStart(DateTime.now());
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

  Future<void> _onAssign(
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

  Future<void> _onSaveRoutine(
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

  Future<void> _onDeleteRoutine(
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
          routines: state.routines
              .where((r) => r.id != event.routineId)
              .toList(),
        ),
      ),
    );
  }

  Future<void> _onSaveDay(
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
        final wasUpdate = event.day.id.isNotEmpty &&
            !event.day.id.startsWith('new_');
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

  Future<void> _onDeleteDay(
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
          editingDays:
              state.editingDays.where((d) => d.id != event.dayId).toList(),
        ),
      ),
    );
  }

  Future<void> _onLoadExerciseCatalog(
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

  Future<void> _onAddExerciseToDay(
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
        await _reloadEditingDays(event.userId, event.routineId, emit);
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

  Future<void> _onAddExercisesToDay(
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
        await _reloadEditingDays(event.userId, event.routineId, emit);
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

  Future<void> _onRemoveExerciseFromDay(
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
        await _reloadEditingDays(event.userId, event.routineId, emit);
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

  Future<void> _onReorderExercises(
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

  Future<void> _onUpdateExerciseTarget(
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
        await _reloadEditingDays(event.userId, event.routineId, emit);
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

  void _onMarkDirty(
    MarkRoutineDirty event,
    Emitter<RoutineManagementState> emit,
  ) {
    if (!state.isDirty) {
      emit(state.copyWith(isDirty: true));
    }
  }

  void _onClearEditingContext(
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

  void _onAcknowledgeFeedback(
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

  /// Refresca `editingDays` desde el backend tras una mutación de ejercicios.
  Future<void> _reloadEditingDays(
    String userId,
    String routineId,
    Emitter<RoutineManagementState> emit,
  ) async {
    final monday = _normalizeWeekStart(DateTime.now());
    final daysRes = await getWeeklyPlan(
      userId: userId,
      routineId: routineId,
      weekStart: monday,
    );
    daysRes.fold((_) => null, (days) {
      emit(state.copyWith(editingDays: days));
    });
  }

  static DateTime _normalizeWeekStart(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
  }
}
