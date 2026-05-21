import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';

class RoutineDayStatusStrip extends StatelessWidget {
  final bool isWorkoutStarted;
  final double totalVolume;
  final bool effectiveReadOnly;
  final bool isCompleted;

  const RoutineDayStatusStrip({
    super.key,
    required this.isWorkoutStarted,
    required this.totalVolume,
    required this.effectiveReadOnly,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lgPlus,
          0,
          Spacing.lgPlus,
          Spacing.xl,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isWorkoutStarted)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VOLUMEN ACTUAL',
                    style: context.text.labelMedium?.copyWith(
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${totalVolume.toStringAsFixed(0)} KG',
                    style: context.text.displayLarge,
                  ),
                ],
              ),
            if (effectiveReadOnly)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? context.colors.success.withValues(alpha: 0.1)
                      : context.colors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCompleted ? 'COMPLETADO' : 'LECTURA',
                  style: context.text.labelMedium?.copyWith(
                    color: isCompleted
                        ? context.colors.success
                        : context.colors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
