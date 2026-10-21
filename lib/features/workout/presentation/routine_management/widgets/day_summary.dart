import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/utils/routine_color.dart';

/// Resumen visual del día: chip de músculos trabajados (derivado de los
/// `targetMuscle` únicos de los ejercicios del día) y conteo total de sets.
class DaySummary extends StatelessWidget {
  const DaySummary({super.key, required this.exercises});

  final List<Exercise> exercises;

  @override
  Widget build(BuildContext context) {
    final muscles = exercises
        .map((e) => e.targetMuscle)
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList();
    final totalSets = exercises.fold<int>(0, (acc, e) => acc + e.targetSets);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lgPlus,
        0,
        Spacing.lgPlus,
        Spacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.md,
          Spacing.lg,
          Spacing.md,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colors.divider.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SummaryStat(
                  icon: Icons.fitness_center_rounded,
                  label:
                      '${exercises.length} ${exercises.length == 1 ? 'ejercicio' : 'ejercicios'}',
                ),
                const SizedBox(width: Spacing.lg),
                _SummaryStat(
                  icon: Icons.repeat_rounded,
                  label: '$totalSets ${totalSets == 1 ? 'serie' : 'series'}',
                ),
              ],
            ),
            if (muscles.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: muscles
                    .map(
                      (m) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: RoutineColor.tint(
                            context,
                            context.colors.primary,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          m,
                          style: context.text.labelMedium?.copyWith(
                            color: context.colors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: context.colors.textSecondary, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
