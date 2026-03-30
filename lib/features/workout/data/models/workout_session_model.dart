import '../../domain/entities/workout_session.dart';

class WorkoutSessionModel extends WorkoutSession {
  const WorkoutSessionModel({
    required super.id,
    required super.userId,
    required super.routineId,
    required super.startedAt,
    super.completedAt,
    super.totalVolume,
  });

  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      routineId: json['routine_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'routine_id': routineId,
      'started_at': startedAt.toIso8601String(),
      'total_volume': totalVolume,
    };
    if (completedAt != null) {
      data['completed_at'] = completedAt!.toIso8601String();
    }
    return data;
  }
}
