import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/utils/routine_color.dart';

/// Fila de ejercicio en el editor de un día.
///
/// - Tap → abre el sheet de edición de targets (`onTap`).
/// - Long-press → inicia el drag de reorder (lo consume `ReorderableDelayed
///   DragStartListener` del padre).
/// - Swipe izquierdo → `onRemove` con confirmación implícita del Dismissible.
class ExerciseRowCard extends StatelessWidget {
  const ExerciseRowCard({
    super.key,
    required this.exercise,
    required this.index,
    required this.onRemove,
    this.onTap,
  });

  final Exercise exercise;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  static String _formatWeight(double w) {
    if (w == 0) return 'BW'; // bodyweight
    if (w == w.roundToDouble()) return '${w.toStringAsFixed(0)}kg';
    return '${w.toStringAsFixed(1)}kg';
  }

  static String _formatRest(int secs) {
    if (secs <= 0) return '—';
    if (secs < 60) return '${secs}s';
    final m = secs ~/ 60;
    final s = secs % 60;
    return s == 0 ? '${m}min' : '${m}m${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final accent = RoutineColor.byIndex(index);

    return Dismissible(
      key: ValueKey('dismiss_${exercise.id}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.heavyImpact();
        onRemove();
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: Spacing.sm),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        child: const Icon(
          Icons.delete_sweep_rounded,
          color: AppColors.onPrimary,
          size: 26,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.4),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: AppTextStyles.displayNumber.copyWith(
                        fontSize: 18,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name.toUpperCase(),
                          style: AppTextStyles.heading2.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _StatTag(
                              icon: Icons.repeat_rounded,
                              label:
                                  '${exercise.targetSets}×${exercise.targetReps}',
                            ),
                            _StatTag(
                              icon: Icons.local_fire_department_rounded,
                              label: _formatWeight(exercise.targetWeight),
                            ),
                            _StatTag(
                              icon: Icons.timer_rounded,
                              label: _formatRest(exercise.restTimerSeconds),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  const Icon(
                    Icons.drag_indicator_rounded,
                    color: AppColors.textDisabled,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTag extends StatelessWidget {
  const _StatTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 10.5,
              color: AppColors.textPrimary.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
