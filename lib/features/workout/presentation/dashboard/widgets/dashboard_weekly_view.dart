import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_weekly_cards.dart';

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
    final isCurrentWeek = _isSameWeek(weekStart, DateTime.now());
    final weekEnd = weekStart.add(const Duration(days: 6));
    final dayMap = <int, RoutineDay>{for (final d in days) d.dayOfWeek: d};

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.surfaceHighlight),
            ),
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
                    if (selectedRoutine != null)
                      InkWell(
                        onTap: onOpenSelectedRoutineStats,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selectedRoutine!.name,
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
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
                      style: AppTextStyles.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (isCurrentWeek)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Esta semana',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                          ),
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
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 8,
            itemBuilder: (context, index) {
              if (index == 0) {
                return DashboardWeeklyInsightsCard(
                  insights: insights,
                  insightsError: insightsError,
                );
              }

              final dayIndex = index - 1;
              final normalizedDayOfWeek = dayIndex + 1;
              final date = weekStart.add(Duration(days: dayIndex));
              final routineDay = dayMap[normalizedDayOfWeek];

              return DashboardDayCard(
                dayOfWeek: normalizedDayOfWeek,
                date: date,
                routineDay: routineDay,
                isToday: _isToday(date),
                onOpenDay: onOpenDay,
              );
            },
          ),
        ),
      ],
    );
  }

  static bool _isSameWeek(DateTime a, DateTime b) {
    final startA = a.subtract(Duration(days: a.weekday - 1));
    final startB = b.subtract(Duration(days: b.weekday - 1));
    return startA.year == startB.year &&
        startA.month == startB.month &&
        startA.day == startB.day;
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
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
