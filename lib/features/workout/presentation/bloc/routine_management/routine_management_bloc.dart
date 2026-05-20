import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/services/routine_assignment_bus.dart';
import 'package:gym_flutter/injection_container.dart' show sl;

import 'package:gym_flutter/features/workout/domain/entities/routine.dart'
    as ent;
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

part 'routine_management_bloc_catalog_handlers.dart';
part 'routine_management_bloc_day_handlers.dart';
part 'routine_management_bloc_routine_handlers.dart';

/// Bloc del subdominio "gestión de rutinas": catálogo + edición + CRUD.
///
/// Inyecta use cases (no el repo directamente) para alinear con la
/// arquitectura limpia. Mantiene `feedbackMessage` para snackbars; la página
/// debe disparar `AcknowledgeFeedback` después de mostrarlo.
///
/// Los handlers viven en 3 archivos `part`/`part of` (catalog / routine /
/// day) para mantener este archivo bajo control de tamaño sin romper la API
/// pública (consumers y mocks siguen viendo un único [RoutineManagementBloc]).
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
    on<LoadAllRoutines>(handleLoadAllRoutines);
    on<LoadRoutineForEditing>(handleLoadRoutineForEditing);
    on<AssignRoutineToUser>(handleAssign);
    on<SaveRoutine>(handleSaveRoutine);
    on<DeleteRoutine>(handleDeleteRoutine);
    on<SaveDay>(handleSaveDay);
    on<DeleteDay>(handleDeleteDay);
    on<LoadExerciseCatalog>(handleLoadExerciseCatalog);
    on<AddExerciseToDayEvent>(handleAddExerciseToDay);
    on<AddExercisesToDayEvent>(handleAddExercisesToDay);
    on<RemoveExerciseFromDayEvent>(handleRemoveExerciseFromDay);
    on<ReorderExercises>(handleReorderExercises);
    on<UpdateExerciseTargetEvent>(handleUpdateExerciseTarget);
    on<MarkRoutineDirty>(handleMarkDirty);
    on<ClearEditingContext>(handleClearEditingContext);
    on<AcknowledgeFeedback>(handleAcknowledgeFeedback);
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

  static DateTime normalizeWeekStart(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
  }
}
