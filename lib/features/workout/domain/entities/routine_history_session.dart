import 'package:equatable/equatable.dart';

class RoutineHistorySession extends Equatable {
  final String sessionId;
  final DateTime sessionDate;
  final String routineDayId;
  final String routineDayName;
  final double totalVolume;
  final int totalReps;

  /// Series registradas en la sesión (filas de `set_logs`).
  final int setCount;

  const RoutineHistorySession({
    this.sessionId = '',
    required this.sessionDate,
    required this.routineDayId,
    required this.routineDayName,
    required this.totalVolume,
    required this.totalReps,
    required this.setCount,
  });

  @override
  List<Object?> get props => [
    sessionId,
    sessionDate,
    routineDayId,
    routineDayName,
    totalVolume,
    totalReps,
    setCount,
  ];
}
