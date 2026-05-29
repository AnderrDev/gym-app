import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_versus_card_parts.dart';

/// Card "versus history" por ejercicio. Renderiza una barra horizontal que
/// compara el peso objetivo con el promedio del último entrenamiento, con
/// un delta a la derecha indicando dirección (superar / mantener / bajar).
///
/// Casos visuales:
/// - Sin historial: estado pasivo "Sin historial — Pelea por la marca".
/// - Sin peso objetivo (calistenia/AMRAP): muestra reps objetivo en lugar
///   de la barra.
class RoutineDayVersusCard extends StatelessWidget {
  const RoutineDayVersusCard({
    super.key,
    required this.exercise,
    required this.prevAvgWeight,
    required this.prevAvgReps,
  });

  final Exercise exercise;
  final double? prevAvgWeight;
  final double? prevAvgReps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _SetsChip(
                sets: exercise.targetSets,
                reps: exercise.targetReps,
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          if (exercise.targetWeight > 0)
            _WeightVersusBar(
              targetWeight: exercise.targetWeight,
              prevWeight: prevAvgWeight,
            )
          else
            VersusNoTargetWeightRow(
              targetReps: exercise.targetReps,
              prevReps: prevAvgReps,
            ),
        ],
      ),
    );
  }
}

class _SetsChip extends StatelessWidget {
  const _SetsChip({required this.sets, required this.reps});

  final int sets;
  final int reps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceHighlight,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Text(
        '$sets×$reps',
        style: theme.textTheme.labelSmall?.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _WeightVersusBar extends StatelessWidget {
  const _WeightVersusBar({required this.targetWeight, required this.prevWeight});

  final double targetWeight;
  final double? prevWeight;

  static const double _barHeight = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPrev = prevWeight != null;
    final maxScale = hasPrev
        ? (prevWeight! > targetWeight ? prevWeight! : targetWeight)
        : targetWeight;
    final targetRatio = (targetWeight / maxScale).clamp(0.0, 1.0);
    final prevRatio = hasPrev
        ? (prevWeight! / maxScale).clamp(0.0, 1.0)
        : 0.0;

    final delta = hasPrev ? targetWeight - prevWeight! : 0.0;
    final isUp = delta > 0;
    final isDown = delta < -0.1;
    final fillColor = !hasPrev
        ? context.colors.textDisabled
        : (isDown
            ? context.colors.error
            : (isUp ? context.colors.primary : context.colors.success));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'OBJETIVO ${targetWeight.toStringAsFixed(0)} kg',
              style: theme.textTheme.labelSmall?.copyWith(
                color: context.colors.textSecondary,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (!hasPrev)
              Text(
                'Sin historial',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.colors.textDisabled,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              VersusDeltaTag(delta: delta, isUp: isUp, isDown: isDown),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: _barHeight + 8,
              child: Stack(
                children: [
                  // Track de fondo hasta target
                  Positioned(
                    top: (8 / 2),
                    child: Container(
                      width: width * targetRatio,
                      height: _barHeight,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceHighlight,
                        borderRadius: BorderRadius.circular(Radii.sm),
                        border: Border.all(
                          color: context.colors.primary.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  // Fill hasta prev
                  if (hasPrev)
                    Positioned(
                      top: (8 / 2),
                      child: Container(
                        width: width * prevRatio,
                        height: _barHeight,
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                      ),
                    ),
                  // Marker en target
                  Positioned(
                    left: (width * targetRatio).clamp(0, width - 2),
                    top: 0,
                    child: Container(
                      width: 2,
                      height: _barHeight + 8,
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (hasPrev) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            'Última vez ${prevWeight!.toStringAsFixed(1)} kg',
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
