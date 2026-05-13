import 'package:equatable/equatable.dart';
import 'coaching_analysis.dart';

class WorkoutSession extends Equatable {
  final String id;
  final String userId;
  final String routineDayId;
  final DateTime sessionDate;
  final DateTime? completedAt;
  final int completedSetsCount;
  final int totalTargetSets;
  final List<CoachingAnalysis>? coachingAnalysis;

  const WorkoutSession({
    required this.id,
    required this.userId,
    required this.routineDayId,
    required this.sessionDate,
    this.completedAt,
    this.completedSetsCount = 0,
    this.totalTargetSets = 0,
    this.coachingAnalysis,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    routineDayId,
    sessionDate,
    completedAt,
    completedSetsCount,
    totalTargetSets,
    coachingAnalysis,
  ];
}
