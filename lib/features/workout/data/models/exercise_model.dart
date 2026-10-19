import 'package:gym_flutter/core/observability/app_logger.dart';

import '../../domain/entities/exercise.dart';

/// Modelo de datos para `Exercise`. Clase hermana (no extiende la entity
/// freezed): (de)serializa el JSON de la DB y convierte hacia/desde la entidad.
class ExerciseModel {
  final String id;
  final String routineDayId;
  final String name;
  final String targetMuscle;
  final double targetWeight;
  final int targetReps;
  final int targetSets;
  final int restTimerSeconds;
  final bool isExtra;
  final String? replacesExerciseName;
  final String? replacedByExerciseName;

  const ExerciseModel({
    required this.id,
    required this.routineDayId,
    required this.name,
    required this.targetMuscle,
    required this.targetWeight,
    required this.targetReps,
    this.targetSets = 3,
    this.restTimerSeconds = 90,
    this.isExtra = false,
    this.replacesExerciseName,
    this.replacedByExerciseName,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    // `exercises.muscle_group` es el campo canónico en la DB. El alias
    // `target_muscle` se aceptaba como legacy y ya no existe en SQL; si
    // aparece, logueamos un warn para detectar payloads viejos en lugar de
    // mapearlo silenciosamente. Cuando falta, dejamos cadena vacía y un warn
    // explícito en lugar del 'Desconocido' fantasma que ocultaba drift.
    if (json.containsKey('target_muscle')) {
      AppLogger.instance.warning(
        'ExerciseModel.fromJson: payload con `target_muscle` legacy '
        '(id=${json['id']}). Use `muscle_group`.',
      );
    }
    final muscleRaw = json['muscle_group'] as String?;
    if (muscleRaw == null || muscleRaw.isEmpty) {
      AppLogger.instance.warning(
        'ExerciseModel.fromJson: `muscle_group` vacío para id=${json['id']}.',
      );
    }
    return ExerciseModel(
      id: json['id'] as String,
      routineDayId: (json['routine_day_id'] ?? '') as String,
      name: json['name'] as String,
      targetMuscle: muscleRaw ?? '',
      targetWeight: (json['target_weight'] as num? ?? 0).toDouble(),
      targetReps: json['target_reps'] as int? ?? 10,
      targetSets: json['target_sets'] as int? ?? 3,
      restTimerSeconds: json['rest_timer_seconds'] as int? ?? 90,
      isExtra: json['is_extra'] as bool? ?? false,
      replacesExerciseName: json['replaces_exercise_name'] as String?,
      replacedByExerciseName: json['replaced_by_exercise_name'] as String?,
    );
  }

  factory ExerciseModel.fromEntity(Exercise entity) {
    return ExerciseModel(
      id: entity.id,
      routineDayId: entity.routineDayId,
      name: entity.name,
      targetMuscle: entity.targetMuscle,
      targetWeight: entity.targetWeight,
      targetReps: entity.targetReps,
      targetSets: entity.targetSets,
      restTimerSeconds: entity.restTimerSeconds,
      isExtra: entity.isExtra,
      replacesExerciseName: entity.replacesExerciseName,
      replacedByExerciseName: entity.replacedByExerciseName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routine_day_id': routineDayId,
      'name': name,
      'muscle_group': targetMuscle,
      'target_weight': targetWeight,
      'target_reps': targetReps,
      'target_sets': targetSets,
      'rest_timer_seconds': restTimerSeconds,
      'is_extra': isExtra,
      'replaces_exercise_name': replacesExerciseName,
      'replaced_by_exercise_name': replacedByExerciseName,
    };
  }

  Exercise toEntity() => Exercise(
    id: id,
    routineDayId: routineDayId,
    name: name,
    targetMuscle: targetMuscle,
    targetWeight: targetWeight,
    targetReps: targetReps,
    targetSets: targetSets,
    restTimerSeconds: restTimerSeconds,
    isExtra: isExtra,
    replacesExerciseName: replacesExerciseName,
    replacedByExerciseName: replacedByExerciseName,
  );
}
