import 'package:equatable/equatable.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/set_log.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_session.dart';

abstract class WorkoutState extends Equatable {
  const WorkoutState();

  @override
  List<Object?> get props => [];
}

class WorkoutInitial extends WorkoutState {}

class WorkoutLoading extends WorkoutState {}

class RoutinesLoaded extends WorkoutState {
  final List<Routine> routines;

  const RoutinesLoaded(this.routines);

  @override
  List<Object?> get props => [routines];
}

class WorkoutError extends WorkoutState {
  final String message;

  const WorkoutError(this.message);

  @override
  List<Object?> get props => [message];
}

class ExercisePerformanceLoaded extends WorkoutState {
  final SetLog? lastSetLog;

  const ExercisePerformanceLoaded(this.lastSetLog);

  @override
  List<Object?> get props => [lastSetLog];
}

class SavingSetLog extends WorkoutState {}

class SetLogSuccess extends WorkoutState {}

class WorkoutFinishedSuccess extends WorkoutState {}

class WorkoutSessionStarted extends WorkoutState {
  final WorkoutSession session;
  final List<Exercise> exercises;

  const WorkoutSessionStarted(this.session, this.exercises);

  @override
  List<Object?> get props => [session, exercises];
}
