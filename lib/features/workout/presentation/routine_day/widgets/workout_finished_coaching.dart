import 'package:flutter/material.dart';

import 'package:gym_flutter/core/i18n/coaching_messages.dart';
import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';

/// Coaching del servidor justo al finalizar. Antes se guardaba en la sesión
/// pero la pantalla se cerraba sin enseñarlo.
class WorkoutFinishedCoaching extends StatelessWidget {
  const WorkoutFinishedCoaching({
    super.key,
    required this.coaching,
    required this.onDone,
  });

  final List<CoachingAnalysis> coaching;
  final VoidCallback onDone;

  IconData _iconFor(String code) => switch (code) {
    CoachingRecommendation.increaseWeight => Icons.trending_up_rounded,
    CoachingRecommendation.decreaseWeight => Icons.trending_down_rounded,
    CoachingRecommendation.increaseReps => Icons.add_circle_outline_rounded,
    _ => Icons.check_circle_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¡Entrenamiento guardado!',
          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          'Para la próxima sesión:',
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.md),
        for (final item in coaching)
          Container(
            margin: const EdgeInsets.only(bottom: Spacing.sm),
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: context.colors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _iconFor(item.recommendation),
                  color: context.colors.primary,
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.exerciseName,
                        style: context.text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CoachingMessages.short(item.recommendation),
                        style: context.text.bodyMedium,
                      ),
                      if (item.feedback?.trim().isNotEmpty ?? false) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.feedback!,
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: Spacing.sm),
        FilledButton(onPressed: onDone, child: const Text('Listo')),
      ],
    );
  }
}
