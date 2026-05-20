import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/ui/adaptive/adaptive_sheet.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_catalog_item.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_state.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_catalog_sheet.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/edit_exercise_target_sheet.dart';

/// Helpers de presentación para el `DayEditorPage`: muestran los bottom-sheets
/// (catálogo de ejercicios + edición de objetivos) y despachan el evento al
/// `RoutineManagementBloc`.
class DayEditorDialogs {
  DayEditorDialogs._();

  static String _userId(BuildContext context) {
    final s = context.read<AuthBloc>().state;
    return s is Authenticated ? s.user.id : '';
  }

  static Future<void> showExerciseCatalog(
    BuildContext context, {
    required String routineId,
    required RoutineDay day,
    required List<Exercise> currentExercises,
  }) async {
    final userId = _userId(context);
    final bloc = context.read<RoutineManagementBloc>();
    unawaited(HapticFeedback.mediumImpact());

    if (bloc.state.catalogStatus != ExerciseCatalogStatus.ready) {
      bloc.add(const LoadExerciseCatalog());
    }

    final result = await AdaptiveSheet.showRaw<List<ExerciseCatalogItem>>(
      context,
      builder: (_) =>
          BlocBuilder<RoutineManagementBloc, RoutineManagementState>(
        bloc: bloc,
        builder: (_, state) {
          if (state.catalogStatus == ExerciseCatalogStatus.loading &&
              state.exerciseCatalog.isEmpty) {
            return const SizedBox(
              height: 200,
              child: Center(child: AppSpinner.large()),
            );
          }
          return ExerciseCatalogSheet(
            catalog: state.exerciseCatalog,
            alreadySelectedIds: currentExercises.map((e) => e.id).toSet(),
          );
        },
      ),
    );

    if (!context.mounted || result == null || result.isEmpty) return;

    if (day.id.isEmpty) {
      AppSnackBar.error(context, 'Guarda el día primero');
      return;
    }

    bloc.add(
      AddExercisesToDayEvent(
        userId: userId,
        routineId: routineId,
        dayId: day.id,
        items: result
            .map((e) => AddExerciseToDayPayload(exerciseId: e.id))
            .toList(),
      ),
    );
    unawaited(HapticFeedback.mediumImpact());
  }

  static Future<void> openEditTargetSheet(
    BuildContext context, {
    required String routineId,
    required RoutineDay day,
    required Exercise exercise,
  }) async {
    final userId = _userId(context);
    final bloc = context.read<RoutineManagementBloc>();
    unawaited(HapticFeedback.selectionClick());
    final result = await AdaptiveSheet.show<EditExerciseTargetResult>(
      context,
      title: 'Editar objetivos',
      child: EditExerciseTargetSheet(exercise: exercise),
    );
    if (result == null) return;
    bloc.add(
      UpdateExerciseTargetEvent(
        userId: userId,
        routineId: routineId,
        dayId: day.id,
        exerciseId: exercise.id,
        targetWeight: result.targetWeight,
        targetReps: result.targetReps,
        targetSets: result.targetSets,
        restSeconds: result.restSeconds,
      ),
    );
  }
}
