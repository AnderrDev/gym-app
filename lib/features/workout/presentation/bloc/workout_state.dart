import 'package:equatable/equatable.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/set_log.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_session.dart';

sealed class WorkoutState extends Equatable {
  const WorkoutState();

  @override
  List<Object?> get props => [];
}

final class WorkoutInitial extends WorkoutState {}

final class WorkoutLoading extends WorkoutState {}

final class RoutinesLoaded extends WorkoutState {
  final List<Routine> routines;

  const RoutinesLoaded(this.routines);

  @override
  List<Object?> get props => [routines];
}

final class WorkoutError extends WorkoutState {
  final String message;

  const WorkoutError(this.message);

  @override
  List<Object?> get props => [message];
}

final class ExercisePerformanceLoaded extends WorkoutState {
  final SetLog? lastSetLog;

  const ExercisePerformanceLoaded(this.lastSetLog);

  @override
  List<Object?> get props => [lastSetLog];
}

final class SavingSetLog extends WorkoutState {}

final class SetLogSuccess extends WorkoutState {}

final class WorkoutFinishedSuccess extends WorkoutState {}

final class WorkoutSessionStarted extends WorkoutState {
  final WorkoutSession session;
  final List<Exercise> exercises;

  const WorkoutSessionStarted(this.session, this.exercises);

  @override
  List<Object?> get props => [session, exercises];
}
