import 'package:equatable/equatable.dart';

abstract class RoutineDayEvent extends Equatable {
  const RoutineDayEvent();

  @override
  List<Object?> get props => const [];
}

/// Carga ejercicios + sesiones recientes + última performance del día,
/// **sin** crear una sesión nueva. Detecta si hay una sesión activa de otro
/// día.
class LoadRoutineDay extends RoutineDayEvent {
  const LoadRoutineDay({
    required this.userId,
    required this.routineDayId,
    required this.sessionDate,
  });

  final String userId;
  final String routineDayId;
  final DateTime sessionDate;

  @override
  List<Object?> get props => [userId, routineDayId, sessionDate];
}

/// Resetea el estado al inicial (cuando salimos de la pantalla).
class ResetRoutineDay extends RoutineDayEvent {
  const ResetRoutineDay();
}
