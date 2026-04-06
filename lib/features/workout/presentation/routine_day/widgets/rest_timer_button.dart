import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';

class RestTimerButton extends StatelessWidget {
  final bool isResting;
  final int secondsRemaining;
  final int totalRestSeconds;
  final VoidCallback onTap;
  final String Function(int seconds) formatTime;

  const RestTimerButton({
    super.key,
    required this.isResting,
    required this.secondsRemaining,
    required this.totalRestSeconds,
    required this.onTap,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalRestSeconds > 0
        ? secondsRemaining / totalRestSeconds
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: CircularProgressIndicator(
              value: isResting ? progress : 0,
              strokeWidth: 3,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              color: AppColors.primary,
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isResting ? AppColors.primary : AppColors.surfaceHighlight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isResting ? Icons.timer_rounded : Icons.play_arrow_rounded,
              color: isResting ? Colors.black : AppColors.textPrimary,
              size: 20,
            ),
          ),
          if (isResting)
            Positioned(
              bottom: -15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  formatTime(secondsRemaining),
                  style: AppTextStyles.label.copyWith(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
