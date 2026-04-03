import '../../domain/entities/coaching_analysis.dart';
import '../../domain/entities/workout_session.dart';

class WorkoutSessionModel extends WorkoutSession {
  const WorkoutSessionModel({
    required super.id,
    required super.userId,
    required super.routineDayId,
    required super.sessionDate,
    super.completedAt,
    super.completedSetsCount = 0,
    super.totalTargetSets = 0,
    super.coachingAnalysis,
  });

  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json) {
    // Handle Supabase count relation: set_logs: [{count: X}]
    int setsCount = 0;
    if (json['set_logs'] != null && json['set_logs'] is List) {
      final list = json['set_logs'] as List;
      if (list.isNotEmpty && list[0]['count'] != null) {
        setsCount = list[0]['count'] as int;
      }
    } else if (json['total_completed_sets'] != null) {
      setsCount = json['total_completed_sets'] as int;
    } else if (json['completed_sets_count'] != null) {
      setsCount = json['completed_sets_count'] as int;
    }

    final coachingJson = json['coaching_analysis'] as List?;
    final coaching = coachingJson?.map((e) => CoachingAnalysis.fromJson(e as Map<String, dynamic>)).toList();

    return WorkoutSessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      routineDayId: (json['routine_day_id'] ?? '') as String,
      sessionDate: DateTime.parse(
        (json['session_date'] ?? json['created_at'] as String).toString().substring(0, 10),
      ),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      completedSetsCount: setsCount,
      totalTargetSets: json['total_target_sets'] as int? ?? 0,
      coachingAnalysis: coaching,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'routine_day_id': routineDayId,
      'session_date': '${sessionDate.year.toString().padLeft(4, '0')}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}',
      'completed_at': completedAt?.toIso8601String(),
      'completed_sets_count': completedSetsCount,
      'total_target_sets': totalTargetSets,
      'coaching_analysis': coachingAnalysis?.map((e) => e.toJson()).toList(),
    };
  }
}
