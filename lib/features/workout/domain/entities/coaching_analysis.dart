import 'package:equatable/equatable.dart';

class CoachingAnalysis extends Equatable {
  final String? exerciseId;
  final String exerciseName;
  final int? completedSets;
  final int? targetSets;
  final bool? weightMet;
  final bool? repsMet;
  final String recommendation;
  final String? feedback;
  final double? performanceScore;

  const CoachingAnalysis({
    this.exerciseId,
    required this.exerciseName,
    this.completedSets,
    this.targetSets,
    this.weightMet,
    this.repsMet,
    required this.recommendation,
    this.feedback,
    this.performanceScore,
  });

  factory CoachingAnalysis.fromJson(Map<String, dynamic> json) {
    return CoachingAnalysis(
      exerciseId: (json['exerciseId'] ?? json['exercise_id']) as String?,
      exerciseName: (json['exerciseName'] ?? json['exercise_name'] ?? 'Ejercicio') as String,
      completedSets: (json['completedSets'] ?? json['completed_sets']) as int?,
      targetSets: (json['targetSets'] ?? json['target_sets']) as int?,
      weightMet: (json['weightMet'] ?? json['weight_met']) as bool?,
      repsMet: (json['repsMet'] ?? json['reps_met']) as bool?,
      recommendation: (json['recommendation'] ?? '') as String,
      feedback: json['feedback'] as String?,
      performanceScore: (json['performanceScore'] ?? json['performance_score'])?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'completedSets': completedSets,
      'targetSets': targetSets,
      'weightMet': weightMet,
      'repsMet': repsMet,
      'recommendation': recommendation,
      'feedback': feedback,
      'performanceScore': performanceScore,
    };
  }

  @override
  List<Object?> get props => [
    exerciseId,
    exerciseName,
    completedSets,
    targetSets,
    weightMet,
    repsMet,
    recommendation,
    feedback,
    performanceScore,
  ];
}
