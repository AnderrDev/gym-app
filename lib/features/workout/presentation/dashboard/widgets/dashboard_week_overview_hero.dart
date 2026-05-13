import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Hero pasivo que sustituye al hero "Focus Today" cuando el usuario navega
/// a una semana que no contiene el día actual.
class DashboardWeekOverviewHero extends StatelessWidget {
  const DashboardWeekOverviewHero({
    super.key,
    required this.weekStart,
    required this.weekEnd,
    required this.plannedDays,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final int plannedDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEMANA · ${weekStart.day}–${weekEnd.day}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            plannedDays == 0
                ? 'Sin entrenamientos'
                : '$plannedDays días planificados',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Estás viendo otra semana. Toca un día para ver detalles.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
