import 'package:equatable/equatable.dart';

import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';

/// Estados granulares del dashboard, modelados como Status enum + data
/// (en lugar de sealed class por subestado) para evitar la explosión que
/// tiene `WorkoutState`.
enum DashboardStatus {
  /// Estado de bootstrap: aún no se disparó ninguna carga.
  initial,

  /// Cargando rutinas (la primera carga).
  loadingRoutines,

  /// Cargando el plan semanal de la rutina seleccionada.
  loadingWeeklyPlan,

  /// Estado estable, datos disponibles (puede haber rutinas sin plan).
  ready,

  /// Falla durante la carga.
  failure,
}

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.routines = const [],
    this.selectedRoutine,
    this.weeklyDays = const [],
    this.weekStart,
    this.insights,
    this.insightsError,
    this.errorMessage,
  });

  final DashboardStatus status;
  final List<Routine> routines;
  final Routine? selectedRoutine;
  final List<RoutineDay> weeklyDays;
  final DateTime? weekStart;
  final WeeklyInsights? insights;
  final String? insightsError;
  final String? errorMessage;

  bool get isLoading =>
      status == DashboardStatus.loadingRoutines ||
      status == DashboardStatus.loadingWeeklyPlan;

  bool get hasWeeklyPlan =>
      selectedRoutine != null && weekStart != null && weeklyDays.isNotEmpty;

  DashboardState copyWith({
    DashboardStatus? status,
    List<Routine>? routines,
    Routine? selectedRoutine,
    bool clearSelectedRoutine = false,
    List<RoutineDay>? weeklyDays,
    DateTime? weekStart,
    WeeklyInsights? insights,
    bool clearInsights = false,
    String? insightsError,
    bool clearInsightsError = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      routines: routines ?? this.routines,
      selectedRoutine: clearSelectedRoutine
          ? null
          : (selectedRoutine ?? this.selectedRoutine),
      weeklyDays: weeklyDays ?? this.weeklyDays,
      weekStart: weekStart ?? this.weekStart,
      insights: clearInsights ? null : (insights ?? this.insights),
      insightsError: clearInsightsError
          ? null
          : (insightsError ?? this.insightsError),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    routines,
    selectedRoutine,
    weeklyDays,
    weekStart,
    insights,
    insightsError,
    errorMessage,
  ];
}
