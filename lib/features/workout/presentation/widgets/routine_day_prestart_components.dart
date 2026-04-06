import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/coaching_analysis.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/set_log.dart';
import '../../domain/entities/workout_session.dart';

class RoutineDayPreviousSessionCard extends StatelessWidget {
  final WorkoutSession session;
  final List<SetLog> logs;

  const RoutineDayPreviousSessionCard({
    super.key,
    required this.session,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    const months = [
      '',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final d = session.sessionDate;
    final dateLabel = '${d.day} ${months[d.month]} ${d.year}';
    final totalVolume = logs.fold(
      0.0,
      (s, l) => s + (l.actualWeight * l.actualReps),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SESIÓN ANTERIOR',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      dateLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (session.completedAt != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'COMPLETADO',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.success,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatPill(label: 'SERIES', value: '${logs.length}'),
              const SizedBox(width: 12),
              _StatPill(
                label: 'VOLUMEN',
                value: '${totalVolume.toStringAsFixed(0)} kg',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RoutineDayExercisePreviewCard extends StatelessWidget {
  final Exercise exercise;
  final SetLog? lastRecord;
  final double? prevAvgWeight;
  final double? prevAvgReps;

  const RoutineDayExercisePreviewCard({
    super.key,
    required this.exercise,
    required this.lastRecord,
    required this.prevAvgWeight,
    required this.prevAvgReps,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrev = prevAvgWeight != null && prevAvgReps != null;
    final targetLabel =
        '${exercise.targetSets}x${exercise.targetReps}${exercise.targetWeight > 0 ? " — ${exercise.targetWeight.toStringAsFixed(0)} kg" : ""}';

    String? deltaLabel;
    Color? deltaColor;
    if (hasPrev && exercise.targetWeight > 0) {
      final diff = prevAvgWeight! - exercise.targetWeight;
      if (diff > 0) {
        deltaLabel = '+${diff.toStringAsFixed(1)} kg';
        deltaColor = AppColors.success;
      } else if (diff < -0.5) {
        deltaLabel = '${diff.toStringAsFixed(1)} kg';
        deltaColor = AppColors.error;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'OBJETIVO: $targetLabel',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                if (hasPrev) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ANTERIOR: ${prevAvgWeight!.toStringAsFixed(1)} kg × ${prevAvgReps!.toStringAsFixed(0)} reps',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ],
                if (lastRecord != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'RECORD: ${lastRecord!.actualWeight.toStringAsFixed(1)} kg × ${lastRecord!.actualReps} reps',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (deltaLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: deltaColor!.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                deltaLabel,
                style: AppTextStyles.label.copyWith(
                  color: deltaColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RoutineDayPreviousCoachingCard extends StatelessWidget {
  final List<CoachingAnalysis> coaching;

  const RoutineDayPreviousCoachingCard({super.key, required this.coaching});

  @override
  Widget build(BuildContext context) {
    final relevant = coaching
        .where((c) => c.recommendation.isNotEmpty)
        .toList();
    if (relevant.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_outlined,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'COACHING DE LA SESIÓN ANTERIOR',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...relevant.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.arrow_right_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.exerciseName,
                          style: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          c.recommendation,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 9,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
