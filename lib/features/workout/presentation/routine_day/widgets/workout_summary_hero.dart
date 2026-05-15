import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Encabezado central del [WorkoutSummaryBottomSheet]: icono circular,
/// título y subtítulo de estado (completada vs. parcial).
class WorkoutSummaryHero extends StatelessWidget {
  const WorkoutSummaryHero({
    super.key,
    required this.isStrictlyCompleted,
    required this.missingSets,
  });

  final bool isStrictlyCompleted;
  final int missingSets;

  @override
  Widget build(BuildContext context) {
    final color = isStrictlyCompleted ? AppColors.success : AppColors.primary;
    final icon = isStrictlyCompleted
        ? Icons.check_circle_rounded
        : Icons.pending_actions_rounded;
    final title =
        isStrictlyCompleted ? '¡Rutina completada!' : 'Sesión finalizada';
    final subtitle = isStrictlyCompleted
        ? 'Cumpliste todo el volumen programado'
        : 'Faltan $missingSets series para el objetivo completo';
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
          ),
          child: Icon(icon, color: color, size: 38),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          title,
          style: AppTextStyles.heading1.copyWith(fontSize: 22),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
