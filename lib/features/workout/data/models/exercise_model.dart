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
    return ExerciseModel(
      id: json['id'] as String,
      routineDayId: (json['routine_day_id'] ?? '') as String,
      name: json['name'] as String,
      targetMuscle: json['target_muscle'] as String? ?? 'Desconocido',
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
      'target_muscle': targetMuscle,
      'target_weight': targetWeight,
      'target_reps': targetReps,
      'target_sets': targetSets,
      'rest_timer_seconds': restTimerSeconds,
    };
  }
}
