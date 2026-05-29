import 'package:equatable/equatable.dart';

abstract class ExerciseDetailEvent extends Equatable {
  const ExerciseDetailEvent();

  @override
  List<Object?> get props => const [];
}

class LoadExerciseDetail extends ExerciseDetailEvent {
  const LoadExerciseDetail(this.exerciseId);

  final String exerciseId;

  @override
  List<Object?> get props => [exerciseId];
}
