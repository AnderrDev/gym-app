import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';

/// Tag con icono direccional + delta en kg (o "Igualar" cuando no hay
/// diferencia significativa).
class VersusDeltaTag extends StatelessWidget {
  const VersusDeltaTag({
    super.key,
    required this.delta,
    required this.isUp,
    required this.isDown,
  });

  final double delta;
  final bool isUp;
  final bool isDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDown
        ? AppColors.error
        : (isUp ? AppColors.primary : AppColors.success);
    final sign = isUp ? '+' : (isDown ? '' : '=');
    final label = isUp || isDown
        ? '$sign${delta.toStringAsFixed(1)} kg'
        : 'Igualar';
    final icon = isUp
        ? Icons.arrow_upward_rounded
        : (isDown ? Icons.arrow_downward_rounded : Icons.check_rounded);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Variante de la fila inferior cuando el ejercicio no tiene peso objetivo
/// (calistenia / AMRAP). Muestra reps objetivo y reps de la última sesión.
class VersusNoTargetWeightRow extends StatelessWidget {
  const VersusNoTargetWeightRow({
    super.key,
    required this.targetReps,
    required this.prevReps,
  });

  final int targetReps;
  final double? prevReps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPrev = prevReps != null;
    return Row(
      children: [
        Text(
          'OBJETIVO $targetReps reps',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (hasPrev)
          Text(
            'Última ${prevReps!.toStringAsFixed(0)} reps',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
            ),
          )
        else
          Text(
            'Sin historial',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textDisabled,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}
