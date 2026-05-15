import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_empty_state.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_skeleton.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_routine_selector.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_weekly_view.dart';

/// Renderiza el contenido del Dashboard según el `DashboardState`.
///
/// Mantiene un patrón explícito de estados (loading/failure/empty/data) sin
/// los `WorkoutState` legacy que mezclaban subdominios.
class DashboardStateContent extends StatelessWidget {
  const DashboardStateContent({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onExploreCatalog,
    required this.onCreateRoutine,
    required this.onSelectRoutine,
    required this.onOpenRoutineStats,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onOpenSelectedRoutineStats,
    required this.onOpenDay,
  });

  final DashboardState state;
  final VoidCallback onRetry;
  final VoidCallback onExploreCatalog;
  final VoidCallback onCreateRoutine;
  final ValueChanged<Routine> onSelectRoutine;
  final ValueChanged<Routine> onOpenRoutineStats;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onOpenSelectedRoutineStats;
  final void Function(RoutineDay routineDay, DateTime date) onOpenDay;

  @override
  Widget build(BuildContext context) {
    // Plan semanal disponible: pintarlo siempre que tengamos rutina + days.
    if (state.hasWeeklyPlan) {
      return DashboardWeeklyView(
        days: state.weeklyDays,
        weekStart: state.weekStart!,
        selectedRoutine: state.selectedRoutine,
        insights: state.insights,
        insightsError: state.insightsError,
        onPreviousWeek: onPreviousWeek,
        onNextWeek: onNextWeek,
        onOpenSelectedRoutineStats: onOpenSelectedRoutineStats,
        onOpenDay: onOpenDay,
      );
    }

    switch (state.status) {
      case DashboardStatus.initial:
      case DashboardStatus.loadingRoutines:
      case DashboardStatus.loadingWeeklyPlan:
        return const DashboardSkeleton();
      case DashboardStatus.failure:
        return _ErrorView(
          message: state.errorMessage ?? 'Error desconocido',
          onRetry: onRetry,
        );
      case DashboardStatus.ready:
        if (state.routines.isEmpty) {
          return DashboardEmptyState(
            onExploreCatalog: onExploreCatalog,
            onCreateRoutine: onCreateRoutine,
          );
        }
        if (state.routines.length == 1) {
          // El bloc dispara LoadWeeklyPlan automáticamente; mostramos
          // el skeleton hasta que llegue el plan.
          return const DashboardSkeleton();
        }
        return DashboardRoutineSelector(
          routines: state.routines,
          onSelectRoutine: onSelectRoutine,
          onOpenRoutineStats: onOpenRoutineStats,
        );
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: Spacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: Spacing.lg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
