import '../../domain/entities/set_log.dart';

class SetLogModel extends SetLog {
  const SetLogModel({
    super.id,
    required super.sessionId,
    required super.exerciseId,
    required super.actualWeight,
    required super.actualReps,
    required super.setIndex,
    super.createdAt,
  });

  factory SetLogModel.fromJson(Map<String, dynamic> json) {
    return SetLogModel(
      id: json['id'] as String?,
      sessionId: json['session_id'] as String,
      exerciseId: json['exercise_id'] as String,
      actualWeight: (json['actual_weight'] as num).toDouble(),
      actualReps: json['actual_reps'] as int,
      setIndex: json['set_index'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
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
}
