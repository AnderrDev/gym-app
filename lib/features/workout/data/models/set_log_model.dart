import '../../domain/entities/set_log.dart';

/// Modelo de datos para `SetLog`. Clase hermana (no extiende la entity
/// freezed): (de)serializa el JSON de Supabase/SQLite y convierte hacia/desde
/// la entidad de dominio.
class SetLogModel {
  final String? id;
  final String sessionId;
  final String exerciseId;
  final double actualWeight;
  final int actualReps;
  final int setIndex;
  final DateTime? createdAt;

  const SetLogModel({
    this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.actualWeight,
    required this.actualReps,
    required this.setIndex,
    this.createdAt,
  });

  factory SetLogModel.fromJson(Map<String, dynamic> json) {
    // id puede ser: String (UUID de Supabase), int (rowid SQLite), o null
    final id = json['id']?.toString();

    return SetLogModel(
      id: id,
      sessionId: json['session_id'] as String,
      exerciseId: json['exercise_id'] as String,
      actualWeight: (json['actual_weight'] as num).toDouble(),
      actualReps: json['actual_reps'] as int,
      setIndex: json['set_index'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  factory SetLogModel.fromEntity(SetLog entity) {
    return SetLogModel(
      id: entity.id,
      sessionId: entity.sessionId,
      exerciseId: entity.exerciseId,
      actualWeight: entity.actualWeight,
      actualReps: entity.actualReps,
      setIndex: entity.setIndex,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'actual_weight': actualWeight,
      'actual_reps': actualReps,
      'set_index': setIndex,
    };
    if (id != null) {
      data['id'] = id;
    }
    // Let database handle created_at generally to guarantee server time
    return data;
  }

  SetLog toEntity() => SetLog(
        id: id,
        sessionId: sessionId,
        exerciseId: exerciseId,
        actualWeight: actualWeight,
        actualReps: actualReps,
        setIndex: setIndex,
        createdAt: createdAt,
      );
}
