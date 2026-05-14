import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_day_card.dart';

/// Lista vertical de los 7 días de la semana. Cada día renderiza un
/// `DashboardDayCard` con toda la info (rutina, status, CTA si es hoy).
///
/// Reemplaza al strip horizontal: gana legibilidad y densidad a costa de
/// un poco más de scroll. Tap en un día con rutina → `onTapDay`.
class DashboardWeekList extends StatelessWidget {
  const DashboardWeekList({
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
    final todayDate = DateTime(today.year, today.month, today.day);
    return Column(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(height: Spacing.sm),
          _buildDay(i, todayDate),
        ],
      ],
    );
  }

  Widget _buildDay(int i, DateTime todayDate) {
    final date = weekStart.add(Duration(days: i));
    final dayOnly = DateTime(date.year, date.month, date.day);
    final dayOfWeek = i + 1;
    final routineDay = daysByDayOfWeek[dayOfWeek];
    final isToday = dayOnly == todayDate;
    final isPast = dayOnly.isBefore(todayDate);
    return DashboardDayCard(
      date: date,
      dayOfWeek: dayOfWeek,
      routineDay: routineDay,
      isToday: isToday,
      isPast: isPast,
      onTap: routineDay == null ? null : () => onTapDay(routineDay, date),
    );
  }
}
