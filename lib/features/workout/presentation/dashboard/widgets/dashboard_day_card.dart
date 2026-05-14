import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';

/// Card vertical de un día de la semana. Densidad y jerarquía pensadas
/// para un listado donde cada día es una fila escaneable: bloque de fecha
/// a la izquierda, contenido (nombre de rutina + métrica + estado) al
/// centro, y CTA/chevron a la derecha.
///
/// Cubre 5 casos visuales: hoy con workout, hoy en progreso, día pasado
/// completado/parcial/pendiente, día futuro planeado, y día de descanso.
class DashboardDayCard extends StatelessWidget {
  const DashboardDayCard({
    super.key,
    required this.date,
    required this.dayOfWeek,
    required this.routineDay,
    required this.isToday,
    required this.isPast,
    required this.onTap,
  });

  final DateTime date;
  final int dayOfWeek;
  final RoutineDay? routineDay;
  final bool isToday;
  final bool isPast;
  final VoidCallback? onTap;

  static const _initials = ['', 'L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final isRest = routineDay == null;
    final status = routineDay?.status ?? WorkoutDayStatus.rest;
    final accent = _accentFor(status, isToday: isToday, isPast: isPast);
    final bgFill = isToday
        ? AppColors.primary.withValues(alpha: 0.07)
        : AppColors.surface;
    final borderColor = isToday
        ? AppColors.primary.withValues(alpha: 0.6)
        : AppColors.divider;

    return Material(
      color: bgFill,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        onTap: isRest ? null : onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
              color: borderColor,
              width: isToday ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _DateBlock(
                initial: _initials[dayOfWeek],
                dayNumber: date.day,
                accent: accent,
                isToday: isToday,
                muted: isRest || (isPast && status == WorkoutDayStatus.pending),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: isRest
                    ? const _RestContent()
                    : _WorkoutContent(
                        routineDay: routineDay!,
                        status: status,
                        accent: accent,
                        isToday: isToday,
                        isPast: isPast,
                      ),
              ),
              const SizedBox(width: Spacing.sm),
              if (!isRest)
                _TrailingIndicator(status: status, isToday: isToday),
            ],
          ),
        ),
      ),
    );
  }

  static Color _accentFor(
    WorkoutDayStatus status, {
    required bool isToday,
    required bool isPast,
  }) {
    switch (status) {
      case WorkoutDayStatus.completed:
        return AppColors.success;
      case WorkoutDayStatus.completedPartial:
        return AppColors.warning;
      case WorkoutDayStatus.inProgress:
        return AppColors.primary;
      case WorkoutDayStatus.pending:
        // Pendiente en el pasado: dimmed. Hoy/futuro: primary (afordancia).
        if (isPast) return AppColors.textSecondary;
        return isToday ? AppColors.primary : AppColors.textPrimary;
      case WorkoutDayStatus.rest:
        return AppColors.textDisabled;
    }
  }
}

class _DateBlock extends StatelessWidget {
  const _DateBlock({
    required this.initial,
    required this.dayNumber,
    required this.accent,
    required this.isToday,
    required this.muted,
  });

  final String initial;
  final int dayNumber;
  final Color accent;
  final bool isToday;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final initialColor = muted ? AppColors.textSecondary : accent;
    final numberColor = muted
        ? AppColors.textSecondary
        : (isToday ? AppColors.primary : AppColors.textPrimary);
    return SizedBox(
      width: 36,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            initial,
            style: AppTextStyles.label.copyWith(
              color: initialColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$dayNumber',
            style: AppTextStyles.bodyLarge.copyWith(
              color: numberColor,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestContent extends StatelessWidget {
  const _RestContent();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Descanso',
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textSecondary,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _WorkoutContent extends StatelessWidget {
  const _WorkoutContent({
    required this.routineDay,
    required this.status,
    required this.accent,
    required this.isToday,
    required this.isPast,
  });

  final RoutineDay routineDay;
  final WorkoutDayStatus status;
  final Color accent;
  final bool isToday;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final exCount = routineDay.exercises.length;
    final setsCount = routineDay.targetSetsCount;
    final subtitle = setsCount > 0
        ? '$exCount ej · $setsCount series'
        : '$exCount ${exCount == 1 ? 'ejercicio' : 'ejercicios'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (isToday) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'HOY',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                routineDay.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        // Subtítulo + status inline en una sola línea, separados por `·`.
        // Bajamos altura ~16px por card y mantenemos jerarquía: nombre
        // pesado arriba, contexto+estado abajo.
        _InlineMeta(
          subtitle: subtitle,
          status: status,
          accent: accent,
          isPast: isPast,
        ),
      ],
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({
    required this.subtitle,
    required this.status,
    required this.accent,
    required this.isPast,
  });

  final String subtitle;
  final WorkoutDayStatus status;
  final Color accent;
  final bool isPast;

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
            ),
          ),
        ),
        Text(
          '  ·  ',
          style: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
        Icon(icon, size: 11, color: accent),
        const SizedBox(width: 3),
        Text(
          statusLabel,
          style: AppTextStyles.label.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
            fontSize: 11,
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
        if (isPast) return (Icons.cancel_outlined, 'Saltado');
        return (Icons.circle_outlined, 'Planeado');
      case WorkoutDayStatus.rest:
        return (Icons.remove_rounded, 'Descanso');
    }
  }
}

class _TrailingIndicator extends StatelessWidget {
  const _TrailingIndicator({required this.status, required this.isToday});

  final WorkoutDayStatus status;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    // Para hoy con sesión actionable usamos un CTA visual (botón redondo
    // con flecha play). Para los demás casos, chevron sutil.
    final isActionable =
        isToday &&
        (status == WorkoutDayStatus.pending ||
            status == WorkoutDayStatus.inProgress ||
            status == WorkoutDayStatus.completedPartial);
    if (isActionable) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: AppColors.onPrimary,
          size: 22,
        ),
      );
    }
    return Icon(
      Icons.chevron_right_rounded,
      color: AppColors.textSecondary.withValues(alpha: 0.6),
      size: 22,
    );
  }
}
