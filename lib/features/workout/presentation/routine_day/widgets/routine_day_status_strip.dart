import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';

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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isWorkoutStarted)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VOLUMEN ACTUAL',
                    style: AppTextStyles.label.copyWith(
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${totalVolume.toStringAsFixed(0)} KG',
                    style: AppTextStyles.displayNumber,
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
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCompleted ? 'COMPLETADO' : 'LECTURA',
                  style: AppTextStyles.label.copyWith(
                    color: isCompleted
                        ? AppColors.success
                        : AppColors.textSecondary,
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
