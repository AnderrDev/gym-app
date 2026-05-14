import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Barra superior con navegación entre semanas. Single-line compact:
/// `< [rutina ↗]  13 – 19 May  >`.
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
      padding: const EdgeInsets.fromLTRB(
        Spacing.xs,
        Spacing.xs,
        Spacing.xs,
        Spacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          _ArrowButton(icon: Icons.chevron_left, onTap: onPreviousWeek),
          if (routineName != null) ...[
            const SizedBox(width: 4),
            _RoutinePill(name: routineName!, onTap: onOpenStats),
          ],
          Expanded(
            child: Center(
              child: Text(
                _rangeLabel(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isCurrentWeek
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _ArrowButton(icon: Icons.chevron_right, onTap: onNextWeek),
        ],
      ),
    );
  }

  String _rangeLabel() {
    final sameMonth = weekStart.month == weekEnd.month;
    if (sameMonth) {
      return '${weekStart.day} – ${weekEnd.day} ${_monthShort(weekStart.month)}';
    }
    return '${weekStart.day} ${_monthShort(weekStart.month)} – '
        '${weekEnd.day} ${_monthShort(weekEnd.month)}';
  }

  static String _monthShort(int m) => const [
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
  ][m];
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }
}

class _RoutinePill extends StatelessWidget {
  const _RoutinePill({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.pill),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.analytics_outlined,
              size: 12,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
