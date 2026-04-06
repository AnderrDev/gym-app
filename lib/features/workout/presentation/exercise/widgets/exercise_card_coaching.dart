import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';

class ExerciseCardCoachingBadge extends StatelessWidget {
  final CoachingAnalysis coaching;
  final Animation<double> pulseAnimation;

  const ExerciseCardCoachingBadge({
    super.key,
    required this.coaching,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final score = coaching.performanceScore ?? 1.0;
    final isGood = score >= 0.85;
    final isGreat = score >= 1.0;

    final color = isGreat
        ? const Color(0xFF4CAF50)
        : (isGood ? Colors.amber[400]! : Colors.orange[400]!);

    IconData trendIcon = Icons.psychology;
    switch (coaching.recommendation) {
      case 'INCREASE_WEIGHT':
        trendIcon = Icons.trending_up;
        break;
      case 'DECREASE_WEIGHT':
        trendIcon = Icons.trending_down;
        break;
      case 'MAINTAIN':
        trendIcon = Icons.trending_flat;
        break;
    }

    return ScaleTransition(
      scale: pulseAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(trendIcon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              'COACH',
              style: AppTextStyles.label.copyWith(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseCardCoachingAdvice extends StatelessWidget {
  final CoachingAnalysis coaching;
  final bool compact;
  final String Function(String) recommendationText;

  const ExerciseCardCoachingAdvice({
    super.key,
    required this.coaching,
    required this.compact,
    required this.recommendationText,
  });

  @override
  Widget build(BuildContext context) {
    final score = coaching.performanceScore ?? 1.0;
    final isGood = score >= 0.85;
    final isGreat = score >= 1.0;

    final accentColor = isGreat
        ? const Color(0xFF4CAF50)
        : (isGood ? Colors.amber[400]! : Colors.orange[400]!);

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 14, color: accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                coaching.recommendation.isEmpty
                    ? (coaching.feedback ?? '')
                    : recommendationText(coaching.recommendation),
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, size: 14, color: AppColors.textDisabled),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'CONSEJO DEL COACH',
                style: AppTextStyles.label.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (coaching.feedback != null && coaching.feedback!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                coaching.feedback ?? '',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          Text(
            recommendationText(coaching.recommendation),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseCardLiveAdvice extends StatelessWidget {
  final String text;

  const ExerciseCardLiveAdvice({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
