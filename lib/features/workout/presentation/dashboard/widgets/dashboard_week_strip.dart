import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';

/// Strip horizontal de 7 días. Cada columna muestra inicial del día, número
/// del mes y un glyph del estado (completado, parcial, en progreso, pendiente,
/// descanso). El día actual se realza con borde y fill en el color primario.
///
/// Tap en un día con rutina → [onTapDay].
class DashboardWeekStrip extends StatelessWidget {
  const DashboardWeekStrip({
    super.key,
    required this.weekStart,
    required this.daysByDayOfWeek,
    required this.today,
    required this.onTapDay,
  });

  final DateTime weekStart;
  final Map<int, RoutineDay> daysByDayOfWeek;
  final DateTime today;
  final void Function(RoutineDay routineDay, DateTime date) onTapDay;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _DayColumn(
                date: weekStart.add(Duration(days: i)),
                dayOfWeek: i + 1,
                routineDay: daysByDayOfWeek[i + 1],
                isToday: _isSameDay(weekStart.add(Duration(days: i)), today),
                onTap: () {
                  final routineDay = daysByDayOfWeek[i + 1];
                  if (routineDay == null) return;
                  onTapDay(routineDay, weekStart.add(Duration(days: i)));
                },
              ),
            ),
          ),
      ],
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.date,
    required this.dayOfWeek,
    required this.routineDay,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final int dayOfWeek;
  final RoutineDay? routineDay;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = routineDay?.status ?? WorkoutDayStatus.rest;
    final glyph = _glyphFor(status);
    final hasWorkout = routineDay != null;
    final statusAccent = _accentFor(status);

    final borderColor =
        statusAccent ?? (isToday ? AppColors.primary : Colors.transparent);
    final fillColor = statusAccent != null
        ? statusAccent.withValues(alpha: 0.12)
        : (isToday
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent);
    final initialColor = isToday
        ? AppColors.primary
        : (statusAccent ?? AppColors.textSecondary);
    final dateColor = isToday
        ? AppColors.primary
        : (statusAccent ?? AppColors.textPrimary);

    return InkWell(
      onTap: hasWorkout ? onTap : null,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: Spacing.sm,
          horizontal: Spacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: borderColor, width: 1.5),
          color: fillColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _dayInitial(dayOfWeek),
              style: theme.textTheme.labelSmall?.copyWith(
                color: initialColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: dateColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            if (statusAccent != null)
              _StatusBadge(
                color: statusAccent,
                icon: _badgeIconFor(status),
              )
            else
              Icon(glyph.icon, color: glyph.color, size: 14),
          ],
        ),
      ),
    );
  }

  static Color? _accentFor(WorkoutDayStatus status) {
    switch (status) {
      case WorkoutDayStatus.completed:
        return AppColors.success;
      case WorkoutDayStatus.completedPartial:
        return AppColors.warning;
      case WorkoutDayStatus.inProgress:
        return AppColors.primary;
      case WorkoutDayStatus.pending:
      case WorkoutDayStatus.rest:
        return null;
    }
  }

  static IconData _badgeIconFor(WorkoutDayStatus status) {
    switch (status) {
      case WorkoutDayStatus.completed:
        return Icons.check_rounded;
      case WorkoutDayStatus.completedPartial:
        return Icons.priority_high_rounded;
      case WorkoutDayStatus.inProgress:
        return Icons.play_arrow_rounded;
      case WorkoutDayStatus.pending:
      case WorkoutDayStatus.rest:
        return Icons.remove_rounded;
    }
  }

  static String _dayInitial(int dayOfWeek) {
    const initials = ['', 'L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return initials[dayOfWeek];
  }

  static _Glyph _glyphFor(WorkoutDayStatus status) {
    switch (status) {
      case WorkoutDayStatus.completed:
        return const _Glyph(Icons.check_circle, AppColors.success);
      case WorkoutDayStatus.completedPartial:
        return const _Glyph(Icons.adjust, AppColors.warning);
      case WorkoutDayStatus.inProgress:
        return const _Glyph(Icons.play_circle_fill, AppColors.primary);
      case WorkoutDayStatus.pending:
        return const _Glyph(Icons.circle_outlined, AppColors.textSecondary);
      case WorkoutDayStatus.rest:
        return const _Glyph(Icons.remove, AppColors.textDisabled);
    }
  }
}

class _Glyph {
  const _Glyph(this.icon, this.color);
  final IconData icon;
  final Color color;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: AppColors.background, size: 12),
    );
  }
}
