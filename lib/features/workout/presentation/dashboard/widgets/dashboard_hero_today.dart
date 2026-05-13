import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/atoms/app_button.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';

/// Hero card "Focus Today": muestra el plan del día actual prominente con un
/// CTA primario gigante. La etiqueta del CTA cambia según el estado del día
/// (empezar, reanudar, completado…). Si [today] es null se renderiza un
/// estado de descanso pasivo, sin CTA.
class DashboardHeroToday extends StatelessWidget {
  const DashboardHeroToday({
    super.key,
    required this.today,
    required this.todayDate,
    required this.onStart,
  });

  final RoutineDay? today;
  final DateTime todayDate;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final t = today;
    if (t == null) {
      return _RestHero(date: todayDate);
    }
    return _ActiveHero(day: t, date: todayDate, onStart: onStart);
  }
}

class _ActiveHero extends StatelessWidget {
  const _ActiveHero({
    required this.day,
    required this.date,
    required this.onStart,
  });

  final RoutineDay day;
  final DateTime date;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cta = _ctaForStatus(day.status);
    final accent = _accentForStatus(day.status);
    final isDone = day.status == WorkoutDayStatus.completed;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.28),
            accent.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  heroMicroLabel(date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isDone) _DoneBadge(),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            day.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            _subtitle(day),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          AppButton(
            label: cta.label,
            icon: cta.icon,
            onPressed: cta.actionable ? onStart : null,
          ),
        ],
      ),
    );
  }

  static Color _accentForStatus(WorkoutDayStatus status) {
    switch (status) {
      case WorkoutDayStatus.completed:
        return AppColors.success;
      case WorkoutDayStatus.completedPartial:
        return AppColors.warning;
      case WorkoutDayStatus.inProgress:
      case WorkoutDayStatus.pending:
      case WorkoutDayStatus.rest:
        return AppColors.primary;
    }
  }

  String _subtitle(RoutineDay d) {
    final exCount = d.exercises.length;
    final exLabel = exCount == 1 ? '1 ejercicio' : '$exCount ejercicios';
    if (d.targetSetsCount > 0) {
      return '$exLabel · ${d.targetSetsCount} series objetivo';
    }
    return exLabel;
  }

  static _CtaInfo _ctaForStatus(WorkoutDayStatus status) {
    switch (status) {
      case WorkoutDayStatus.completed:
        return const _CtaInfo(
          label: 'Entrenamiento completado',
          icon: Icons.check_circle,
          actionable: false,
        );
      case WorkoutDayStatus.completedPartial:
        return const _CtaInfo(
          label: 'Continuar sesión parcial',
          icon: Icons.replay_circle_filled,
          actionable: true,
        );
      case WorkoutDayStatus.inProgress:
        return const _CtaInfo(
          label: 'Reanudar entrenamiento',
          icon: Icons.play_arrow,
          actionable: true,
        );
      case WorkoutDayStatus.pending:
      case WorkoutDayStatus.rest:
        return const _CtaInfo(
          label: 'Empezar entrenamiento',
          icon: Icons.play_arrow,
          actionable: true,
        );
    }
  }
}

class _RestHero extends StatelessWidget {
  const _RestHero({required this.date});

  final DateTime date;

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
            heroMicroLabel(date),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Día de descanso',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Recupera. Mañana volvemos al gimnasio.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaInfo {
  const _CtaInfo({
    required this.label,
    required this.icon,
    required this.actionable,
  });

  final String label;
  final IconData icon;
  final bool actionable;
}

class _DoneBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_rounded,
            size: 14,
            color: AppColors.background,
          ),
          const SizedBox(width: 4),
          Text(
            'CUMPLIDO',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.background,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Microlabel del hero ("MIÉRCOLES · 4 MAY"). Expuesto a top-level del
/// archivo para que ambas variantes (active/rest) lo compartan sin reflejar
/// la implementación.
String heroMicroLabel(DateTime d) {
  const days = [
    '',
    'LUNES',
    'MARTES',
    'MIÉRCOLES',
    'JUEVES',
    'VIERNES',
    'SÁBADO',
    'DOMINGO',
  ];
  const months = [
    '',
    'ENE',
    'FEB',
    'MAR',
    'ABR',
    'MAY',
    'JUN',
    'JUL',
    'AGO',
    'SEP',
    'OCT',
    'NOV',
    'DIC',
  ];
  return '${days[d.weekday]} · ${d.day} ${months[d.month]}';
}
