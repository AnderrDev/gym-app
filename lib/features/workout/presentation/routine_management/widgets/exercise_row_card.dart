import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/presentation/widgets/glass_container.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';

/// Fila de ejercicio en el editor de un día. Swipe-to-delete dispara
/// `onRemove`; el handle indica que se puede reordenar (la lógica del reorder
/// está en el padre `SliverReorderableList`).
class ExerciseRowCard extends StatelessWidget {
  const ExerciseRowCard({
    super.key,
    required this.exercise,
    required this.index,
    required this.onRemove,
  });

  final Exercise exercise;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${exercise.id}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.vibrate();
        onRemove();
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: Spacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        child: const Icon(Icons.delete_sweep, color: AppColors.onPrimary, size: 28),
      ),
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: Spacing.md),
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(22),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            exercise.name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.heading2.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          subtitle: Row(
            children: [
              Flexible(
                child: Text(
                  exercise.targetMuscle.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: AppColors.textDisabled)),
              const SizedBox(width: 8),
              Text(
                '${exercise.targetSets} X ${exercise.targetReps}',
                style: AppTextStyles.label.copyWith(fontSize: 10),
              ),
            ],
          ),
          trailing: const Icon(
            Icons.drag_indicator_rounded,
            color: AppColors.textDisabled,
            size: 20,
          ),
        ),
      ),
    );
  }
}
