import 'package:equatable/equatable.dart';

abstract class ExerciseStatsEvent extends Equatable {
  const ExerciseStatsEvent();

  @override
  List<Object> get props => [];
}

class LoadExerciseStats extends ExerciseStatsEvent {
  final String userId;
  final String exerciseId;

  const LoadExerciseStats({required this.userId, required this.exerciseId});

  @override
  List<Object> get props => [userId, exerciseId];
}
