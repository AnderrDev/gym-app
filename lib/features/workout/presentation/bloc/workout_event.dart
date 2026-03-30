import 'package:equatable/equatable.dart';
import '../../domain/entities/set_log.dart';

sealed class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

final class FetchAssignedRoutines extends WorkoutEvent {
  final String userId;

  const FetchAssignedRoutines(this.userId);

  @override
  List<Object?> get props => [userId];
}

final class FetchLastExercisePerformance extends WorkoutEvent {
  final String exerciseId;

  const FetchLastExercisePerformance(this.exerciseId);

  @override
  List<Object?> get props => [exerciseId];
}

final class AddSetLogEvent extends WorkoutEvent {
  final SetLog setLog;

  const AddSetLogEvent(this.setLog);

  @override
  List<Object?> get props => [setLog];
}

final class FinishSessionEvent extends WorkoutEvent {
  final String sessionId;
  final double totalVolume;

  const FinishSessionEvent(this.sessionId, this.totalVolume);

  @override
  List<Object?> get props => [sessionId, totalVolume];
}

final class StartWorkoutEvent extends WorkoutEvent {
  final String userId;
  final String routineId;

  const StartWorkoutEvent(this.userId, this.routineId);

  @override
  List<Object?> get props => [userId, routineId];
}
