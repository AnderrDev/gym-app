import 'package:equatable/equatable.dart';

import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';

/// Estados del hub `/progress`.
///
/// Sealed con 4 subestados explícitos — el bloc orquesta dos fetches en
/// paralelo (insights + routines), así que un único `status` enum era más
/// confuso que cuatro clases concretas.
sealed class ProgressState extends Equatable {
  const ProgressState();

  @override
  List<Object?> get props => const [];
}

/// Bootstrap — todavía no se disparó ningún `LoadProgress`.
class ProgressInitial extends ProgressState {
  const ProgressInitial();
}

/// Loading inicial. Reservado para `LoadProgress`; los refresh NO lo emiten.
class ProgressLoading extends ProgressState {
  const ProgressLoading();
}

/// Datos listos. `insights` puede ser `null` si el usuario no tiene rutinas
/// asignadas (no hay `routineId` contra el que consultar insights) — la UI
/// lo trata como "sin datos esta semana".
class ProgressReady extends ProgressState {
  const ProgressReady({
    required this.weekStart,
    required this.weekEnd,
    required this.routines,
    this.insights,
    this.insightsError,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final List<Routine> routines;
  final WeeklyInsights? insights;

  /// Si el fetch de insights falló pero el de rutinas no, mostramos el hub
  /// con un microerror inline en la sección "Esta semana".
  final String? insightsError;

  @override
  List<Object?> get props => [
    weekStart,
    weekEnd,
    routines,
    insights,
    insightsError,
  ];
}

/// Falla terminal — el fetch de rutinas falló y no hay nada que pintar.
class ProgressFailure extends ProgressState {
  const ProgressFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
