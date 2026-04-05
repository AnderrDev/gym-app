import '../../domain/entities/routine.dart';

class RoutineModel extends Routine {
  const RoutineModel({
    required super.id,
    required super.name,
    required super.exerciseCount,
    super.isPublic = false,
    super.creatorId,
    super.creatorName,
  });

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    // Ahora leemos directamente de la vista routines_view
    return RoutineModel(
      id: json['id'] as String,
      name: json['name'] as String,
      exerciseCount: json['exercise_count'] as int? ?? 0,
      isPublic: json['is_public'] as bool? ?? false,
      creatorId: json['creator_id'] as String?,
      creatorName: json['creator_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercise_count': exerciseCount,
      'is_public': isPublic,
      'creator_id': creatorId,
      'creator_name': creatorName,
    };
  }
}
