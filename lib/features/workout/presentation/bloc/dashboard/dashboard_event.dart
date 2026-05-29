import 'package:equatable/equatable.dart';

import 'package:gym_flutter/features/workout/domain/entities/routine.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => const [];
}

/// Carga las rutinas asignadas. Si el usuario tiene exactamente una, el bloc
/// dispara `LoadWeeklyPlan` automáticamente para evitar UI vacía.
class LoadAssignedRoutines extends DashboardEvent {
  const LoadAssignedRoutines(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Carga el plan semanal de la rutina seleccionada para una semana puntual.
class LoadWeeklyPlan extends DashboardEvent {
  const LoadWeeklyPlan({
    required this.userId,
    required this.routine,
    required this.weekStart,
  });

  final String userId;
  final Routine routine;
  final DateTime weekStart;

  @override
  List<Object?> get props => [userId, routine.id, weekStart];
}

/// El usuario seleccionó una rutina del listado y quiere ver su plan semanal.
class SelectRoutine extends DashboardEvent {
  const SelectRoutine({
    required this.userId,
    required this.routine,
    required this.weekStart,
  });

  final String userId;
  final Routine routine;
  final DateTime weekStart;

  @override
  List<Object?> get props => [userId, routine.id, weekStart];
}

/// Cambio de semana (next/prev). El bloc usa la rutina actual del estado.
class ChangeWeek extends DashboardEvent {
  const ChangeWeek({required this.userId, required this.weekStart});

  final String userId;
  final DateTime weekStart;

  @override
  List<Object?> get props => [userId, weekStart];
}
