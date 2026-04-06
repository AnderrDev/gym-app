import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/routine_day.dart';
import '../bloc/workout_state.dart';
import 'dashboard_empty_state.dart';
import 'dashboard_routine_selector.dart';
import 'dashboard_weekly_view.dart';

class DashboardStateContent extends StatelessWidget {
  final WorkoutState effectiveState;
  final Routine? selectedRoutine;
  final WeeklyPlanLoaded? cachedWeeklyPlan;
  final VoidCallback onRetryFetchAssignedRoutines;
  final VoidCallback onExploreCatalog;
  final VoidCallback onCreateRoutine;
  final ValueChanged<Routine> onSelectRoutine;
  final ValueChanged<Routine> onOpenRoutineStats;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onOpenSelectedRoutineStats;
  final void Function(RoutineDay routineDay, DateTime date) onOpenDay;

  const DashboardStateContent({
    super.key,
    required this.effectiveState,
    required this.selectedRoutine,
    required this.cachedWeeklyPlan,
    required this.onRetryFetchAssignedRoutines,
    required this.onExploreCatalog,
    required this.onCreateRoutine,
    required this.onSelectRoutine,
    required this.onOpenRoutineStats,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onOpenSelectedRoutineStats,
    required this.onOpenDay,
  });

  @override
  Widget build(BuildContext context) {
    return switch (effectiveState) {
      WorkoutInitial() || WorkoutLoading() || SavingSetLog() => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      ActiveSessionDetected() => Center(
        child: Text(
          'Sesión activa detectada, cargando tablero...',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
      DayInfoLoaded() || DayWorkoutStarted() => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      WorkoutError(message: final msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetryFetchAssignedRoutines,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
      ManagementSuccess() ||
      WorkoutFinishedSuccess() ||
      SetLogSuccess() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 48,
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
      AllRoutinesLoaded() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Sincronizando tus rutinas...',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
      RoutinesLoaded(routines: final routines) =>
        routines.isEmpty
            ? DashboardEmptyState(
                onExploreCatalog: onExploreCatalog,
                onCreateRoutine: onCreateRoutine,
              )
            : routines.length == 1
            ? (cachedWeeklyPlan != null &&
                      cachedWeeklyPlan!.routine?.id == routines.first.id
                  ? DashboardWeeklyView(
                      days: cachedWeeklyPlan!.days,
                      weekStart: cachedWeeklyPlan!.weekStart,
                      selectedRoutine: selectedRoutine,
                      insights: cachedWeeklyPlan!.insights,
                      insightsError: cachedWeeklyPlan!.insightsError,
                      onPreviousWeek: onPreviousWeek,
                      onNextWeek: onNextWeek,
                      onOpenSelectedRoutineStats: onOpenSelectedRoutineStats,
                      onOpenDay: onOpenDay,
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Cargando tu rutina...',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ))
            : DashboardRoutineSelector(
                routines: routines,
                onSelectRoutine: onSelectRoutine,
                onOpenRoutineStats: onOpenRoutineStats,
              ),
      WeeklyPlanLoaded(
        days: final days,
        weekStart: final weekStart,
        insights: final insights,
        insightsError: final insightsError,
      ) =>
        DashboardWeeklyView(
          days: days,
          weekStart: weekStart,
          selectedRoutine: selectedRoutine,
          insights: insights,
          insightsError: insightsError,
          onPreviousWeek: onPreviousWeek,
          onNextWeek: onNextWeek,
          onOpenSelectedRoutineStats: onOpenSelectedRoutineStats,
          onOpenDay: onOpenDay,
        ),
      _ => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    };
  }
}
