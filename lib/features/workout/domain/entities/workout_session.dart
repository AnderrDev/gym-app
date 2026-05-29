import 'package:freezed_annotation/freezed_annotation.dart';
import 'coaching_analysis.dart';

part 'workout_session.freezed.dart';

@freezed
abstract class WorkoutSession with _$WorkoutSession {
  const factory WorkoutSession({
    required String id,
    required String userId,
    required String routineDayId,
    required DateTime sessionDate,
    DateTime? completedAt,
    @Default(0) int completedSetsCount,
    @Default(0) int totalTargetSets,
    List<CoachingAnalysis>? coachingAnalysis,
  }) = _WorkoutSession;
}
