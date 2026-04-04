import 'package:equatable/equatable.dart';

sealed class RoutineStatsEvent extends Equatable {
  const RoutineStatsEvent();

  @override
  List<Object?> get props => [];
}

class FetchRoutineStats extends RoutineStatsEvent {
  final String userId;
  final String routineId;

  const FetchRoutineStats({required this.userId, required this.routineId});

  @override
  List<Object?> get props => [userId, routineId];
}
