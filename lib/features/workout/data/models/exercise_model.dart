import 'package:gym_flutter/core/observability/app_logger.dart';

import '../../domain/entities/exercise.dart';

class ExerciseModel extends Exercise {
  const ExerciseModel({
    required super.id,
    required super.routineDayId,
    required super.name,
    required super.targetMuscle,
    required super.targetWeight,
    required super.targetReps,
    super.targetSets,
    super.restTimerSeconds,
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
    };
  }
}
