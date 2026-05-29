import '../../domain/entities/routine.dart';

/// Modelo de datos para `Routine`. Clase hermana (no extiende la entity
/// freezed): (de)serializa el JSON de `routines_view` y convierte
/// hacia/desde la entidad en el boundary del repositorio.
class RoutineModel {
  final String id;
  final String name;
  final int exerciseCount;
  final bool isPublic;
  final String? creatorId;
  final String? creatorName;

  const RoutineModel({
    required this.id,
    required this.name,
    required this.exerciseCount,
    this.isPublic = false,
    this.creatorId,
    this.creatorName,
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

  factory RoutineModel.fromEntity(Routine entity) => RoutineModel(
        id: entity.id,
        name: entity.name,
        exerciseCount: entity.exerciseCount,
        isPublic: entity.isPublic,
        creatorId: entity.creatorId,
        creatorName: entity.creatorName,
      );

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

  Routine toEntity() => Routine(
        id: id,
        name: name,
        exerciseCount: exerciseCount,
        isPublic: isPublic,
        creatorId: creatorId,
        creatorName: creatorName,
      );
}
