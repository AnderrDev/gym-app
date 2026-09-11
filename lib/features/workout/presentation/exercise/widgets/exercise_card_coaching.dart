import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/i18n/coaching_messages.dart';
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
    final isGreat = score >= 1.0;

    final color = isGreat ? context.colors.success : context.colors.warning;

    IconData trendIcon = Icons.psychology_rounded;
    switch (coaching.recommendation) {
      case CoachingRecommendation.increaseWeight:
        trendIcon = Icons.trending_up_rounded;
        break;
      case CoachingRecommendation.decreaseWeight:
        trendIcon = Icons.trending_down_rounded;
        break;
      case CoachingRecommendation.maintain:
        trendIcon = Icons.trending_flat_rounded;
        break;
    }

    return RepaintBoundary(
      child: ScaleTransition(
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
                style: context.text.labelMedium?.copyWith(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
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
    final isGreat = score >= 1.0;

    final accentColor = isGreat ? context.colors.success : context.colors.warning;

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(Spacing.sm),
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
            Icon(Icons.lightbulb_outline_rounded, size: 14, color: accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                coaching.recommendation.isEmpty
                    ? (coaching.feedback ?? '')
                    : recommendationText(coaching.recommendation),
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: context.colors.textDisabled,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.psychology_rounded, size: 16, color: accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              recommendationText(coaching.recommendation),
              style: context.text.bodySmall?.copyWith(
                color: context.colors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
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
        color: context.colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.flash_on_rounded, color: context.colors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.textPrimary,
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
