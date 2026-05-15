import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Cabecera de la vista semanal: navegación entre semanas + rango +
/// identificador de rutina. El progress ring de "X/Y DÍAS" se removió por
/// ser redundante con el "Resumen de la semana" tile que vive más abajo.
class DashboardWeekHeader extends StatelessWidget {
  const DashboardWeekHeader({
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
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          _ArrowButton(
            icon: Icons.chevron_left_rounded,
            onTap: onPreviousWeek,
            tooltip: 'Semana anterior',
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: _AnimatedRangeLabel(
                        weekStart: weekStart,
                        weekEnd: weekEnd,
                        isCurrentWeek: isCurrentWeek,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (isCurrentWeek) ...[
                      const SizedBox(width: 6),
                      const _TodayDot(),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                if (routineName != null)
                  _RoutinePill(name: routineName!, onTap: onOpenStats)
                else
                  Text(
                    'Sin rutina seleccionada',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.md),
          _ArrowButton(
            icon: Icons.chevron_right_rounded,
            onTap: onNextWeek,
            tooltip: 'Semana siguiente',
          ),
        ],
      ),
    );
  }
}

class _AnimatedRangeLabel extends StatelessWidget {
  const _AnimatedRangeLabel({
    required this.weekStart,
    required this.weekEnd,
    required this.isCurrentWeek,
    required this.style,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final bool isCurrentWeek;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final label = _rangeLabel(weekStart, weekEnd);
    final baseStyle = style;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: Text(
        label,
        key: ValueKey(label),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle?.copyWith(
          color: isCurrentWeek ? baseStyle.color : AppColors.textSecondary,
        ),
      ),
    );
  }

  static String _rangeLabel(DateTime start, DateTime end) {
    final sameMonth = start.month == end.month;
    if (sameMonth) {
      return '${start.day} – ${end.day} ${_monthShort(start.month)}';
    }
    return '${start.day} ${_monthShort(start.month)} – '
        '${end.day} ${_monthShort(end.month)}';
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

class _TodayDot extends StatelessWidget {
  const _TodayDot();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Radii.sm),
            border: Border.all(color: AppColors.divider),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
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
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
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
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.analytics_rounded,
              size: 13,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
