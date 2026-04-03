import 'package:equatable/equatable.dart';
import '../../../domain/entities/exercise_history_session.dart';

abstract class ExerciseStatsState extends Equatable {
  const ExerciseStatsState();

  @override
  List<Object> get props => [];
}

class ExerciseStatsInitial extends ExerciseStatsState {}

class ExerciseStatsLoading extends ExerciseStatsState {}

class ExerciseStatsLoaded extends ExerciseStatsState {
  final List<ExerciseHistorySession> history;

  const ExerciseStatsLoaded({required this.history});

  @override
  List<Object> get props => [history];
}

class ExerciseStatsError extends ExerciseStatsState {
  final String message;

  const ExerciseStatsError({required this.message});

  @override
  List<Object> get props => [message];
}
