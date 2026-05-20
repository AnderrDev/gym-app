import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
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
    this.onLongPress,
  });

  final ExerciseCatalogItem exercise;
  final bool isSelected;
  final bool isAlreadyInDay;
  final VoidCallback onTap;

  /// Long-press abre el detalle del ejercicio (media + instrucciones). Lo
  /// inyecta el padre porque la tile no conoce de navegación.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: BoxDecoration(
        color: isAlreadyInDay
            ? context.colors.textDisabled.withValues(alpha: 0.1)
            : (isSelected
                ? context.colors.primary.withValues(alpha: 0.05)
                : Colors.transparent),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        enabled: !isAlreadyInDay,
        onTap: isAlreadyInDay ? null : onTap,
        onLongPress: onLongPress,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isAlreadyInDay
                ? context.colors.surfaceHighlight
                : (isSelected ? context.colors.primary : context.colors.surface),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isAlreadyInDay
                ? Icons.lock_outline_rounded
                : (isSelected ? Icons.check_rounded : Icons.local_fire_department_rounded),
            color: isSelected && !isAlreadyInDay
                ? context.colors.onPrimary
                : context.colors.textDisabled,
            size: 18,
          ),
        ),
        title: Text(
          exercise.name,
          style: AppTextStyles.bodyLarge.copyWith(
            color: isAlreadyInDay
                ? context.colors.textDisabled
                : (isSelected ? context.colors.primary : context.colors.textPrimary),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          isAlreadyInDay ? 'Ya en tu rutina' : exercise.muscleGroup,
          style: AppTextStyles.label.copyWith(color: context.colors.textDisabled),
        ),
        trailing: isAlreadyInDay
            ? null
            : (isSelected
                ? Icon(
                    Icons.check_circle_rounded,
                    color: context.colors.primary,
                    size: 20,
                  )
                : null),
      ),
    );
  }
}
