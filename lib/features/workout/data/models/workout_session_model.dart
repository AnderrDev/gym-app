import 'package:gym_flutter/core/observability/app_logger.dart';

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

  /// La fuente canónica es la vista `view_workout_sessions_summary` (provee
  /// `total_completed_sets` y `total_target_sets`). Cuando la query se hace
  /// directo a `workout_sessions` esos campos son null y los conteos quedan
  /// en 0 — el caller decide si necesita pedir la vista en su lugar.
  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json) {
    final dateRaw = (json['session_date'] ?? json['created_at']) as String?;
    if (dateRaw == null) {
      throw const FormatException(
        'WorkoutSessionModel.fromJson: falta session_date/created_at',
      );
    }

    final coachingJson = json['coaching_analysis'] as List?;
    final coaching = coachingJson
        ?.map((e) => CoachingAnalysis.fromJson(e as Map<String, dynamic>))
        .toList();

    final hasTotalCompleted = json.containsKey('total_completed_sets');
    final hasTotalTarget = json.containsKey('total_target_sets');
    if (!hasTotalCompleted || !hasTotalTarget) {
      AppLogger.instance.warning(
        'WorkoutSessionModel.fromJson: payload sin total_completed_sets/'
        'total_target_sets (id=${json['id']}). '
        'Consulta view_workout_sessions_summary si necesitas conteos.',
      );
    }

    return WorkoutSessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      routineDayId: (json['routine_day_id'] ?? '') as String,
      sessionDate: DateTime.parse(dateRaw.substring(0, 10)),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      completedSetsCount:
          (json['total_completed_sets'] as num?)?.toInt() ?? 0,
      totalTargetSets: (json['total_target_sets'] as num?)?.toInt() ?? 0,
      coachingAnalysis: coaching,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'routine_day_id': routineDayId,
      'session_date':
          '${sessionDate.year.toString().padLeft(4, '0')}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}',
      'completed_at': completedAt?.toIso8601String(),
      'completed_sets_count': completedSetsCount,
      'total_target_sets': totalTargetSets,
      'coaching_analysis': coachingAnalysis?.map((e) => e.toJson()).toList(),
    };
  }
}
