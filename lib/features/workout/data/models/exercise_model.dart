import '../../domain/entities/exercise.dart';

class ExerciseModel extends Exercise {
  const ExerciseModel({
    required super.id,
    required super.routineId,
    required super.name,
    required super.targetWeight,
    required super.targetReps,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String,
      routineId: json['routine_id'] as String,
      name: json['name'] as String,
      targetWeight: (json['target_weight'] as num).toDouble(),
      targetReps: json['target_reps'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routine_id': routineId,
      'name': name,
      'target_weight': targetWeight,
      'target_reps': targetReps,
    };
  }
}
