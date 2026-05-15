import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_catalog_item.dart';

/// Fila individual del catálogo de ejercicios: leading con icono según
/// estado (lock / check / dumbell), título coloreado por estado y trailing
/// con check verde cuando está seleccionado.
class ExerciseCatalogTile extends StatelessWidget {
  const ExerciseCatalogTile({
    super.key,
    required this.exercise,
    required this.isSelected,
    required this.isAlreadyInDay,
    required this.onTap,
  });

  final ExerciseCatalogItem exercise;
  final bool isSelected;
  final bool isAlreadyInDay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: BoxDecoration(
        color: isAlreadyInDay
            ? AppColors.textDisabled.withValues(alpha: 0.1)
            : (isSelected
                ? AppColors.primary.withValues(alpha: 0.05)
                : Colors.transparent),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        enabled: !isAlreadyInDay,
        onTap: isAlreadyInDay ? null : onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isAlreadyInDay
                ? AppColors.surfaceHighlight
                : (isSelected ? AppColors.primary : AppColors.surface),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isAlreadyInDay
                ? Icons.lock_outline_rounded
                : (isSelected ? Icons.check_rounded : Icons.local_fire_department_rounded),
            color: isSelected && !isAlreadyInDay
                ? AppColors.onPrimary
                : AppColors.textDisabled,
            size: 18,
          ),
        ),
        title: Text(
          exercise.name,
          style: AppTextStyles.bodyLarge.copyWith(
            color: isAlreadyInDay
                ? AppColors.textDisabled
                : (isSelected ? AppColors.primary : AppColors.textPrimary),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          isAlreadyInDay ? 'Ya en tu rutina' : exercise.muscleGroup,
          style: AppTextStyles.label.copyWith(color: AppColors.textDisabled),
        ),
        trailing: isAlreadyInDay
            ? null
            : (isSelected
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 20,
                  )
                : null),
      ),
    );
  }
}
