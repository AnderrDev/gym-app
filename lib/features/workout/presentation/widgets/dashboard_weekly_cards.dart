import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../domain/entities/routine_day.dart';
import '../../domain/entities/weekly_insights.dart';

class DashboardWeeklyInsightsCard extends StatelessWidget {
  final WeeklyInsights? insights;
  final String? insightsError;

  const DashboardWeeklyInsightsCard({
    super.key,
    required this.insights,
    required this.insightsError,
  });

  @override
  Widget build(BuildContext context) {
    if (insightsError != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceHighlight),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No se pudieron cargar insights esta semana. El plan sigue disponible.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (insights == null) return const SizedBox.shrink();

    final trendColor = insights!.volumeTrendPercent >= 0
        ? AppColors.success
        : AppColors.error;
    final trendLabel = insights!.volumeTrendPercent >= 0
        ? '+${insights!.volumeTrendPercent.toStringAsFixed(1)}%'
        : '${insights!.volumeTrendPercent.toStringAsFixed(1)}%';

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: BorderRadius.circular(12),
      opacity: 0.08,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text('Insights semanales', style: AppTextStyles.bodyLarge),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: 'Adherencia',
                  value: '${insights!.adherenceRate.toStringAsFixed(0)}%',
                ),
                _MetricChip(
                  label: 'Sesiones',
                  value: '${insights!.completedSessions}',
                ),
                _MetricChip(
                  label: 'Volumen',
                  value: '${insights!.totalVolume.toStringAsFixed(0)} kg',
                ),
                _MetricChip(
                  label: 'Tendencia',
                  value: trendLabel,
                  valueColor: trendColor,
                ),
                _MetricChip(
                  label: 'PRs',
                  value: '${insights!.personalRecords}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardDayCard extends StatelessWidget {
  final int dayOfWeek;
  final DateTime date;
  final RoutineDay? routineDay;
  final bool isToday;
  final void Function(RoutineDay routineDay, DateTime date) onOpenDay;

  const DashboardDayCard({
    super.key,
    required this.dayOfWeek,
    required this.date,
    required this.routineDay,
    required this.isToday,
    required this.onOpenDay,
  });

  @override
  Widget build(BuildContext context) {
    final hasWorkout = routineDay != null;
    final status = routineDay?.status ?? WorkoutDayStatus.rest;

    final (statusColor, statusIcon, statusLabel) = switch (status) {
      WorkoutDayStatus.completed => (
        const Color(0xFF4CAF50),
        Icons.check_circle,
        'Completado',
      ),
      WorkoutDayStatus.completedPartial => (
        const Color(0xFFFF9800),
        Icons.check_circle_outline,
        'Completado parcial',
      ),
      WorkoutDayStatus.inProgress => (
        AppColors.primary,
        Icons.play_circle,
        'En progreso',
      ),
      WorkoutDayStatus.pending => (
        AppColors.textSecondary,
        Icons.radio_button_unchecked,
        'Pendiente',
      ),
      WorkoutDayStatus.rest => (
        AppColors.surfaceHighlight,
        Icons.hotel,
        'Descanso',
      ),
    };

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 10),
      borderRadius: BorderRadius.circular(12),
      opacity: isToday ? 0.2 : 0.05,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday ? AppColors.primary : Colors.transparent,
            width: isToday ? 1.5 : 0,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _dayShortName(dayOfWeek),
                style: AppTextStyles.label.copyWith(
                  color: isToday ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${date.day}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isToday ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          title: hasWorkout
              ? Text(routineDay!.name, style: AppTextStyles.bodyLarge)
              : Text(
                  'Descanso',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
          subtitle: hasWorkout && routineDay!.exercises.isNotEmpty
              ? Text(
                  '${routineDay!.exercises.length} ejercicios',
                  style: AppTextStyles.label,
                )
              : null,
          trailing: hasWorkout
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 24),
                    const SizedBox(height: 2),
                    Text(
                      statusLabel,
                      style: AppTextStyles.label.copyWith(
                        color: statusColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                )
              : null,
          onTap: hasWorkout ? () => onOpenDay(routineDay!, date) : null,
        ),
      ),
    );
  }

  static String _dayShortName(int dayOfWeek) {
    const days = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[dayOfWeek];
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricChip({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
