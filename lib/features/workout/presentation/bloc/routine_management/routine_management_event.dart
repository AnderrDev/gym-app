import 'package:equatable/equatable.dart';

import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

abstract class RoutineManagementEvent extends Equatable {
  const RoutineManagementEvent();

  @override
  List<Object?> get props => const [];
}

/// Catálogo: carga todas las rutinas (propias + públicas).
class LoadAllRoutines extends RoutineManagementEvent {
  const LoadAllRoutines();
}

/// Carga el detalle de una rutina (metadatos + plan semanal) para editar.
class LoadRoutineForEditing extends RoutineManagementEvent {
  const LoadRoutineForEditing({required this.userId, required this.routineId});

  final String userId;
  final String routineId;

  @override
  List<Object?> get props => [userId, routineId];
}

/// Asigna una rutina como la activa para el usuario.
class AssignRoutineToUser extends RoutineManagementEvent {
  const AssignRoutineToUser({required this.userId, required this.routineId});

  final String userId;
  final String routineId;

  @override
  List<Object?> get props => [userId, routineId];
}

/// Crea o actualiza una rutina.
class SaveRoutine extends RoutineManagementEvent {
  const SaveRoutine({
    required this.userId,
    this.id,
    required this.name,
    this.isPublic = false,
  });

  final String userId;
  final String? id;
  final String name;
  final bool isPublic;

  @override
  List<Object?> get props => [userId, id, name, isPublic];
}

/// Elimina una rutina del catálogo.
class DeleteRoutine extends RoutineManagementEvent {
  const DeleteRoutine({required this.userId, required this.routineId});

  final String userId;
  final String routineId;

  @override
  List<Object?> get props => [userId, routineId];
}

/// Persiste un día (creación o actualización completa).
class SaveDay extends RoutineManagementEvent {
  const SaveDay({
    required this.userId,
    required this.routineId,
    required this.day,
  });

  final String userId;
  final String routineId;
  final RoutineDay day;

  @override
  List<Object?> get props => [userId, routineId, day];
}

/// Elimina un día específico.
class DeleteDay extends RoutineManagementEvent {
  const DeleteDay({
    required this.userId,
    required this.routineId,
    required this.dayId,
  });

  final String userId;
  final String routineId;
  final String dayId;

  @override
  List<Object?> get props => [userId, routineId, dayId];
}

/// Carga el catálogo global de ejercicios (con filtros opcionales).
class LoadExerciseCatalog extends RoutineManagementEvent {
  const LoadExerciseCatalog({this.muscleGroup, this.search});

  final String? muscleGroup;
  final String? search;

  @override
  List<Object?> get props => [muscleGroup, search];
}

/// Añade un único ejercicio al día.
class AddExerciseToDayEvent extends RoutineManagementEvent {
  const AddExerciseToDayEvent({
    required this.userId,
    required this.routineId,
    required this.dayId,
    required this.exerciseId,
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetWeight = 0,
    this.restSeconds = 90,
  });

  final String userId;
  final String routineId;
  final String dayId;
  final String exerciseId;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final int restSeconds;

  @override
  List<Object?> get props => [
    userId,
    routineId,
    dayId,
    exerciseId,
    targetSets,
    targetReps,
    targetWeight,
    restSeconds,
  ];
}

/// Añade un lote de ejercicios al día (insert bulk).
class AddExercisesToDayEvent extends RoutineManagementEvent {
  const AddExercisesToDayEvent({
    required this.userId,
    required this.routineId,
    required this.dayId,
    required this.items,
  });

  final String userId;
  final String routineId;
  final String dayId;
  final List<AddExerciseToDayPayload> items;

  @override
  List<Object?> get props => [userId, routineId, dayId, items];
}

/// Quita un ejercicio del día.
class RemoveExerciseFromDayEvent extends RoutineManagementEvent {
  const RemoveExerciseFromDayEvent({
    required this.userId,
    required this.routineId,
    required this.dayId,
    required this.exerciseId,
  });

  final String userId;
  final String routineId;
  final String dayId;
  final String exerciseId;

  @override
  List<Object?> get props => [userId, routineId, dayId, exerciseId];
}

/// Reordena los ejercicios de un día.
class ReorderExercises extends RoutineManagementEvent {
  const ReorderExercises({
    required this.userId,
    required this.routineId,
    required this.dayId,
    required this.exerciseIds,
  });

  final String userId;
  final String routineId;
  final String dayId;
  final List<String> exerciseIds;

  @override
  List<Object?> get props => [userId, routineId, dayId, exerciseIds];
}

/// Marca el estado como "tiene cambios sin guardar" (para PopScope/confirm).
class MarkRoutineDirty extends RoutineManagementEvent {
  const MarkRoutineDirty();
}

/// Limpia el contexto de edición (al salir del editor).
class ClearEditingContext extends RoutineManagementEvent {
  const ClearEditingContext();
}

/// Resetea el `submissionStatus` y `feedbackMessage` después de mostrar
/// un toast/snackbar para que la siguiente acción no herede el estado.
class AcknowledgeFeedback extends RoutineManagementEvent {
  const AcknowledgeFeedback();
}
