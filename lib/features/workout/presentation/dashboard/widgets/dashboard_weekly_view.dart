import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_hero_today.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_insights_compact.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_week_navigator.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_week_overview_hero.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_week_strip.dart';

/// Vista "Focus Today": el día actual ocupa la parte superior con un CTA
/// prominente. Debajo, strip semanal compacto + métricas. Si la semana
/// visible no contiene "hoy" (el usuario navegó a otra semana), el hero se
/// reemplaza por un encabezado pasivo.
class DashboardWeeklyView extends StatelessWidget {
  final List<RoutineDay> days;
  final DateTime weekStart;
  final Routine? selectedRoutine;
  final WeeklyInsights? insights;
  final String? insightsError;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onOpenSelectedRoutineStats;
  final void Function(RoutineDay routineDay, DateTime date) onOpenDay;

  const DashboardWeeklyView({
    super.key,
    required this.days,
    required this.weekStart,
    required this.selectedRoutine,
    required this.insights,
    required this.insightsError,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onOpenSelectedRoutineStats,
    required this.onOpenDay,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekEnd = weekStart.add(const Duration(days: 6));
    final dayMap = <int, RoutineDay>{for (final d in days) d.dayOfWeek: d};
    final containsToday =
        !today.isBefore(weekStart) &&
        today.isBefore(weekStart.add(const Duration(days: 7)));
    final todayRoutineDay = containsToday ? dayMap[today.weekday] : null;
    final todayDate = containsToday
        ? DateTime(today.year, today.month, today.day)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardWeekNavigator(
          weekStart: weekStart,
          weekEnd: weekEnd,
          isCurrentWeek: containsToday,
          routineName: selectedRoutine?.name,
          onPreviousWeek: onPreviousWeek,
          onNextWeek: onNextWeek,
          onOpenStats: onOpenSelectedRoutineStats,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Spacing.lg),
            children: [
              if (containsToday)
                DashboardHeroToday(
                  today: todayRoutineDay,
                  todayDate: todayDate!,
                  onStart: () {
                    if (todayRoutineDay != null) {
                      onOpenDay(todayRoutineDay, todayDate);
                    }
                  },
                )
              else
                DashboardWeekOverviewHero(
                  weekStart: weekStart,
                  weekEnd: weekEnd,
                  plannedDays: days.length,
                ),
              const SizedBox(height: Spacing.xl),
              const _SectionLabel(text: 'Plan de la semana'),
              const SizedBox(height: Spacing.sm),
              DashboardWeekStrip(
                weekStart: weekStart,
                daysByDayOfWeek: dayMap,
                today: today,
                onTapDay: onOpenDay,
              ),
              if (insights != null || insightsError != null) ...[
                const SizedBox(height: Spacing.xl),
                const _SectionLabel(text: 'Insights'),
                const SizedBox(height: Spacing.sm),
                DashboardInsightsCompact(
                  insights: insights,
                  error: insightsError,
                ),
              ],
              const SizedBox(height: Spacing.xl),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
