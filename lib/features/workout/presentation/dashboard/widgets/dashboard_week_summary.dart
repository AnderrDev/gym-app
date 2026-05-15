import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';

/// Tile de "Resumen semanal" que llena la parte baja del dashboard cuando
/// no hay insights remotos. Computa todo localmente desde la lista de
/// `RoutineDay` que ya está cargada — no hace nuevas requests.
///
/// Reemplaza al placeholder "Insights no disponibles esta semana" que dejaba
/// el final de la pantalla en blanco.
class DashboardWeekSummary extends StatelessWidget {
  const DashboardWeekSummary({
    super.key,
    required this.days,
    required this.weekStart,
    this.onTapNext,
  });

  final List<RoutineDay> days;
  final DateTime weekStart;

  /// Si la semana tiene un próximo día pendiente, se llama con ese día
  /// para que el caller dispare la navegación.
  final void Function(RoutineDay day, DateTime date)? onTapNext;

  @override
  Widget build(BuildContext context) {
    final planned = days.where((d) => d.status != WorkoutDayStatus.rest).toList();
    final completed = planned
        .where(
          (d) =>
              d.status == WorkoutDayStatus.completed ||
              d.status == WorkoutDayStatus.completedPartial,
        )
        .length;
    final inProgress = planned
        .where((d) => d.status == WorkoutDayStatus.inProgress)
        .length;
    final remaining = planned.length - completed - inProgress;
    final totalSetsPlanned =
        planned.fold<int>(0, (sum, d) => sum + d.targetSetsCount);
    final ratio = planned.isEmpty ? 0.0 : completed / planned.length;

    final accent = ratio >= 1.0
        ? AppColors.success
        : ratio >= 0.5
            ? AppColors.primary
            : AppColors.warning;

    // Próximo día con workout pendiente (hoy o futuro dentro de la semana).
    final next = _findNextWorkout();

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'RESUMEN DE LA SEMANA',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              _BigStat(
                value: '$completed',
                suffix: '/${planned.length}',
                label: 'Completados',
                accent: accent,
              ),
              const SizedBox(width: Spacing.md),
              _BigStat(
                value: '$remaining',
                label: 'Restantes',
                accent: AppColors.textSecondary,
              ),
              const SizedBox(width: Spacing.md),
              _BigStat(
                value: '$totalSetsPlanned',
                label: 'Series totales',
                accent: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.divider.withValues(alpha: 0.3),
              color: accent,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            _statusMessage(completed, planned.length, inProgress),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (next != null && onTapNext != null) ...[
            const SizedBox(height: Spacing.md),
            _NextWorkoutButton(
              day: next.day,
              relativeLabel: next.relativeLabel,
              accent: accent,
              onTap: () => onTapNext!(next.day, next.date),
            ),
          ],
        ],
      ),
    );
  }

  _NextWorkout? _findNextWorkout() {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    for (var i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      if (dateOnly.isBefore(todayDateOnly)) continue;
      // dayOfWeek: 1..7 (Lun..Dom). Buscamos el día en la lista que matchea.
      final candidate = days.firstWhere(
        (d) => d.dayOfWeek == date.weekday,
        orElse: () => const RoutineDay(
          id: '',
          routineId: '',
          dayOfWeek: 0,
          name: '',
        ),
      );
      if (candidate.id.isEmpty) continue;
      if (candidate.status == WorkoutDayStatus.rest) continue;
      if (candidate.status == WorkoutDayStatus.completed) continue;
      final label = dateOnly == todayDateOnly
          ? 'HOY'
          : dateOnly == todayDateOnly.add(const Duration(days: 1))
              ? 'MAÑANA'
              : _shortDayLabel(date);
      return _NextWorkout(day: candidate, date: date, relativeLabel: label);
    }
    return null;
  }

  String _shortDayLabel(DateTime d) {
    const initials = ['', 'LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
    return '${initials[d.weekday]} ${d.day}';
  }

  String _statusMessage(int completed, int total, int inProgress) {
    if (total == 0) return 'Esta semana no hay días planificados.';
    if (completed >= total) {
      return '¡Semana completa! 💪 Excelente trabajo.';
    }
    if (inProgress > 0) {
      return 'Tenés una sesión en curso. Vamos por más.';
    }
    final left = total - completed;
    return left == 1
        ? 'Te queda 1 día por entrenar esta semana.'
        : 'Te quedan $left días por entrenar esta semana.';
  }
}

class _NextWorkout {
  const _NextWorkout({
    required this.day,
    required this.date,
    required this.relativeLabel,
  });

  final RoutineDay day;
  final DateTime date;
  final String relativeLabel;
}

class _NextWorkoutButton extends StatelessWidget {
  const _NextWorkoutButton({
    required this.day,
    required this.relativeLabel,
    required this.accent,
    required this.onTap,
  });

  final RoutineDay day;
  final String relativeLabel;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.md),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.18),
              accent.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Icon(Icons.play_circle_fill_rounded, color: accent, size: 24),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PRÓXIMO · $relativeLabel',
                    style: AppTextStyles.label.copyWith(
                      color: accent,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    day.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: accent,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({
    required this.value,
    required this.label,
    required this.accent,
    this.suffix,
  });

  final String value;
  final String? suffix;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
                if (suffix != null)
                  TextSpan(
                    text: suffix,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
