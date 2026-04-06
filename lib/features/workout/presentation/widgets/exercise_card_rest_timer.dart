import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class ExerciseCardRestTimer extends StatelessWidget {
  final int secondsLeft;
  final int totalSeconds;
  final String formattedTime;
  final VoidCallback onSkip;

  const ExerciseCardRestTimer({
    super.key,
    required this.secondsLeft,
    required this.totalSeconds,
    required this.formattedTime,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = totalSeconds > 0 ? secondsLeft / totalSeconds : 0.0;
    final isDanger = secondsLeft <= 10;

    return Container(
      key: const ValueKey('rest_timer'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDanger ? AppColors.error : AppColors.primary).withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDanger ? AppColors.error : AppColors.primary).withValues(
            alpha: 0.25,
          ),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'DESCANSO',
            style: AppTextStyles.label.copyWith(
              color: isDanger ? AppColors.error : AppColors.primary,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: fraction.clamp(0.0, 1.0),
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.background,
                  color: isDanger ? AppColors.error : AppColors.primary,
                ),
                Text(
                  formattedTime,
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 24,
                    color: isDanger ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onSkip,
            icon: const Icon(Icons.skip_next, size: 20),
            label: const Text('Saltar descanso'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
