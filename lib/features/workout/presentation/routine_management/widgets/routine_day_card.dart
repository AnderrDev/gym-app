import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/presentation/widgets/glass_container.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';

/// Card que representa un día dentro del editor de rutina. Tap para editar.
class RoutineDayCard extends StatelessWidget {
  const RoutineDayCard({
    super.key,
    required this.index,
    required this.day,
    required this.onTap,
  });

  final int index;
  final RoutineDay day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(24),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.lgPlus,
            vertical: Spacing.sm,
          ),
          onTap: onTap,
          leading: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${index + 1}',
              style: AppTextStyles.displayNumber.copyWith(
                fontSize: 18,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          title: Text(
            day.name.toUpperCase(),
            style: AppTextStyles.heading2.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: Spacing.xs),
            child: Text(
              '${day.exercises.length} EJERCICIOS',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          trailing: const Icon(
            Icons.drag_handle_rounded,
            color: AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}
