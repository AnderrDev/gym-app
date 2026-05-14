import 'package:equatable/equatable.dart';

import 'package:gym_flutter/features/workout/domain/entities/exercise_catalog_item.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';

enum RoutineManagementStatus { initial, loading, ready, failure }

enum RoutineManagementSubmissionStatus { idle, submitting, success, failure }

enum ExerciseCatalogStatus { initial, loading, ready, failure }

/// Identifica qué acción produjo el último `submissionStatus`. Permite a las
/// pages reaccionar selectivamente (ej.: `routine_list_page` solo navega al
/// dashboard cuando la acción fue `assignRoutine`, no en cualquier success).
enum RoutineManagementAction {
  none,
  assignRoutine,
  saveRoutine,
  deleteRoutine,
  saveDay,
  deleteDay,
  addExercise,
  addExercises,
  removeExercise,
  reorderExercises,
  updateExerciseTarget,
}

/// Estado del subdominio "gestión de rutinas". Cubre tres escenarios:
/// (a) catálogo de rutinas: lista de rutinas;
/// (b) edición: una rutina y su plan;
/// (c) catálogo de ejercicios (para añadir al día).
class RoutineManagementState extends Equatable {
  const RoutineManagementState({
    this.status = RoutineManagementStatus.initial,
    this.submissionStatus = RoutineManagementSubmissionStatus.idle,
    this.lastAction = RoutineManagementAction.none,
    this.routines = const [],
    this.activeRoutineId,
    this.editingRoutine,
    this.editingDays = const [],
    this.exerciseCatalog = const [],
    this.catalogStatus = ExerciseCatalogStatus.initial,
    this.isDirty = false,
    this.errorMessage,
    this.feedbackMessage,
  });

  final RoutineManagementStatus status;
  final RoutineManagementSubmissionStatus submissionStatus;
  final RoutineManagementAction lastAction;
  final List<Routine> routines;

  /// Id de la rutina actualmente asignada al usuario (única por la constraint
  /// `user_routines.user_id`). `null` si todavía no se cargó o el usuario no
  /// tiene rutina activa.
  final String? activeRoutineId;
  final Routine? editingRoutine;
  final List<RoutineDay> editingDays;
  final List<ExerciseCatalogItem> exerciseCatalog;
  final ExerciseCatalogStatus catalogStatus;
  final bool isDirty;
  final String? errorMessage;
  final String? feedbackMessage;

  bool get isLoading => status == RoutineManagementStatus.loading;
  bool get isSubmitting =>
      submissionStatus == RoutineManagementSubmissionStatus.submitting;

  RoutineManagementState copyWith({
    RoutineManagementStatus? status,
    RoutineManagementSubmissionStatus? submissionStatus,
    RoutineManagementAction? lastAction,
    List<Routine>? routines,
    String? activeRoutineId,
    bool clearActiveRoutineId = false,
    Routine? editingRoutine,
    bool clearEditingRoutine = false,
    List<RoutineDay>? editingDays,
    bool clearEditingDays = false,
    List<ExerciseCatalogItem>? exerciseCatalog,
    ExerciseCatalogStatus? catalogStatus,
    bool? isDirty,
    bool markClean = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return RoutineManagementState(
      status: status ?? this.status,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      lastAction: lastAction ?? this.lastAction,
      routines: routines ?? this.routines,
      activeRoutineId: clearActiveRoutineId
          ? null
          : (activeRoutineId ?? this.activeRoutineId),
      editingRoutine: clearEditingRoutine
          ? null
          : (editingRoutine ?? this.editingRoutine),
      editingDays: clearEditingDays ? const [] : (editingDays ?? this.editingDays),
      exerciseCatalog: exerciseCatalog ?? this.exerciseCatalog,
      catalogStatus: catalogStatus ?? this.catalogStatus,
      isDirty: markClean ? false : (isDirty ?? this.isDirty),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    submissionStatus,
    lastAction,
    routines,
    activeRoutineId,
    editingRoutine,
    editingDays,
    exerciseCatalog,
    catalogStatus,
    isDirty,
    errorMessage,
    feedbackMessage,
  ];
}
