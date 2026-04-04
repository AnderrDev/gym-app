import 'package:equatable/equatable.dart';

class RoutineHistorySession extends Equatable {
  final DateTime sessionDate;
  final String routineDayId;
  final String routineDayName;
  final double totalVolume;
  final int totalReps;
  final int exerciseCount;

  const RoutineHistorySession({
    required this.sessionDate,
    required this.routineDayId,
    required this.routineDayName,
    required this.totalVolume,
    required this.totalReps,
    required this.exerciseCount,
  });

  @override
  List<Object?> get props => [
        sessionDate,
        routineDayId,
        routineDayName,
        totalVolume,
        totalReps,
        exerciseCount,
      ];
}
