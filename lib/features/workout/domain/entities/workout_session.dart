import 'package:equatable/equatable.dart';

class WorkoutSession extends Equatable {
  final String id;
  final String userId;
  final String routineId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final double totalVolume;

  const WorkoutSession({
    required this.id,
    required this.userId,
    required this.routineId,
    required this.startedAt,
    this.completedAt,
    this.totalVolume = 0.0,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    routineId,
    startedAt,
    completedAt,
    totalVolume,
  ];
}
