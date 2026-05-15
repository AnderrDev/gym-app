import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_day_card_parts.dart';

/// Contenido textual del día (nombre + meta inline). Se separó del set
/// principal de parts para mantener cada archivo bajo 300 líneas.
class DayCardWorkoutContent extends StatelessWidget {
  const DayCardWorkoutContent({
    super.key,
    required this.routineDay,
    required this.status,
    required this.accent,
    required this.variant,
    required this.isPast,
  });

  final RoutineDay routineDay;
  final WorkoutDayStatus status;
  final Color accent;
  final DayCardVariant variant;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final isToday = variant == DayCardVariant.today;
    // Mostramos sólo las series planificadas (más útil que el conteo de
    // ejercicios para el user). El conteo de ejercicios del dashboard
    // venía 0 porque la lista no carga el detalle — la información real
    // de ejercicios la ve al entrar al día.
    final exCount = routineDay.exercises.length;
    final setsCount = routineDay.targetSetsCount;
    final subtitle = setsCount > 0
        ? '$setsCount series'
        : '$exCount ${exCount == 1 ? 'ejercicio' : 'ejercicios'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          routineDay.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            fontSize: isToday ? 16 : 14.5,
            letterSpacing: -0.1,
          ),
        ),
        SizedBox(height: isToday ? 4 : 2),
        DayCardInlineMeta(
          subtitle: subtitle,
          status: status,
          accent: accent,
          isPast: isPast,
          emphasize: isToday,
        ),
      ],
    );
  }
}

class DayCardInlineMeta extends StatelessWidget {
  const DayCardInlineMeta({
    super.key,
    required this.subtitle,
    required this.status,
    required this.accent,
    required this.isPast,
    required this.emphasize,
  });

  final String subtitle;
  final WorkoutDayStatus status;
  final Color accent;
  final bool isPast;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final (icon, statusLabel) = _statusFor(status, isPast);
    return Row(
      children: [
        Flexible(
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              fontSize: emphasize ? 12 : 11,
            ),
          ),
        ),
        Text(
          '  ·  ',
          style: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
        Icon(icon, size: emphasize ? 13 : 11, color: accent),
        const SizedBox(width: 4),
        Text(
          statusLabel,
          style: AppTextStyles.label.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
            fontSize: emphasize ? 12 : 11,
          ),
        ),
      ],
    );
  }

  (IconData, String) _statusFor(WorkoutDayStatus status, bool isPast) {
    switch (status) {
      case WorkoutDayStatus.completed:
        return (Icons.check_circle_rounded, 'Completado');
      case WorkoutDayStatus.completedPartial:
        return (Icons.priority_high_rounded, 'Parcial');
      case WorkoutDayStatus.inProgress:
        return (Icons.play_circle_rounded, 'En progreso');
      case WorkoutDayStatus.pending:
        if (isPast) return (Icons.cancel_rounded, 'Saltado');
        return (Icons.radio_button_unchecked_rounded, 'Planeado');
      case WorkoutDayStatus.rest:
        return (Icons.remove_rounded, 'Descanso');
    }
  }
}

class DayCardTrailingIndicator extends StatelessWidget {
  const DayCardTrailingIndicator({
    super.key,
    required this.status,
    required this.isToday,
    required this.accent,
  });

  final WorkoutDayStatus status;
  final bool isToday;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    // Hoy + sesión actionable → CTA play prominente con sombra.
    final isActionable = isToday &&
        (status == WorkoutDayStatus.pending ||
            status == WorkoutDayStatus.inProgress ||
            status == WorkoutDayStatus.completedPartial);

    if (isActionable) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Container(
          key: ValueKey(status),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(Radii.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: AppColors.onPrimary,
            size: 26,
          ),
        ),
      );
    }

    // Día completado en el pasado → check verde inline.
    if (status == WorkoutDayStatus.completed) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: AppColors.success,
          size: 18,
        ),
      );
    }

    return Icon(
      Icons.chevron_right_rounded,
      color: AppColors.textSecondary.withValues(alpha: 0.55),
      size: 22,
    );
  }
}
