import 'package:equatable/equatable.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_history_session.dart';

sealed class RoutineStatsState extends Equatable {
  const RoutineStatsState();

  @override
  List<Object?> get props => [];
}

class RoutineStatsInitial extends RoutineStatsState {}

class RoutineStatsLoading extends RoutineStatsState {}

class RoutineStatsLoaded extends RoutineStatsState {
  final List<RoutineHistorySession> stats;

  const RoutineStatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

class RoutineStatsError extends RoutineStatsState {
  final String message;

  const RoutineStatsError(this.message);

  @override
  List<Object?> get props => [message];
}
