import '../../domain/entities/routine.dart';

class RoutineModel extends Routine {
  const RoutineModel({
    required super.id,
    required super.name,
    required super.exerciseCount,
  });

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    return RoutineModel(
      id: json['id'] as String,
      name: json['name'] as String,
      exerciseCount: json['exercise_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'exercise_count': exerciseCount};
  }
}
