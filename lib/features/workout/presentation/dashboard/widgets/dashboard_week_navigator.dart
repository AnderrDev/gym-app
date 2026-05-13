import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Barra superior con navegación entre semanas. El nombre de la rutina, si
/// está presente, actúa como link a las stats de esa rutina.
class DashboardWeekNavigator extends StatelessWidget {
  const DashboardWeekNavigator({
    super.key,
    required this.weekStart,
    required this.weekEnd,
    required this.isCurrentWeek,
    required this.routineName,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onOpenStats,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final bool isCurrentWeek;
  final String? routineName;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onOpenStats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.primary),
            onPressed: onPreviousWeek,
          ),
          Expanded(
            child: Column(
              children: [
                if (routineName != null)
                  InkWell(
                    onTap: onOpenStats,
                    borderRadius: BorderRadius.circular(Radii.xs),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.xs,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            routineName!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.analytics_outlined,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                Text(
                  '${_formatDate(weekStart)} – ${_formatDate(weekEnd)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isCurrentWeek
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
            onPressed: onNextWeek,
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month]}';
  }
}
