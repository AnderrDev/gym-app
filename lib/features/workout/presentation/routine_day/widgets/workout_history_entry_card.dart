import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/workout_performance_analyzer.dart';

/// Tarjeta con el detalle de un ejercicio dentro del history sheet:
/// header con nombre + resumen, filas por serie destacando la TOP set,
/// y consejo del coach si aplica.
class WorkoutHistoryEntryCard extends StatelessWidget {
  final String exerciseName;
  final List<SetLog> logs;
  final CoachingAnalysis? coaching;

  const WorkoutHistoryEntryCard({
    super.key,
    required this.exerciseName,
    required this.logs,
    required this.coaching,
  });

  @override
  Widget build(BuildContext context) {
    // Serie más pesada del ejercicio — para destacarla como "top set".
    SetLog? topSet;
    var topW = -1.0;
    for (final l in logs) {
      if (l.actualWeight > topW) {
        topW = l.actualWeight;
        topSet = l;
      }
    }
    final exerciseVolume = logs.fold<double>(
      0,
      (s, l) => s + (l.actualWeight * l.actualReps),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.md,
              Spacing.lg,
              Spacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    exerciseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${logs.length} ${logs.length == 1 ? 'serie' : 'series'} · '
                  '${exerciseVolume.toStringAsFixed(0)} kg·reps',
                  style: context.text.labelMedium?.copyWith(
                    color: context.colors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.colors.divider),
          ...logs.map(
            (log) => _SetRow(log: log, isTopSet: identical(log, topSet)),
          ),
          if (coaching != null && coaching!.hasActionableAdvice) ...[
            Divider(height: 1, color: context.colors.divider),
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: _CoachingAdvice(coaching: coaching!),
            ),
          ],
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.log, required this.isTopSet});

  final SetLog log;
  final bool isTopSet;

  String _fmtWeight(double w) =>
      w % 1 == 0 ? w.toStringAsFixed(0) : w.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final accent = isTopSet ? context.colors.warning : context.colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          _Circle(label: '${log.setIndex}', accent: accent),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _fmtWeight(log.actualWeight),
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: ' kg × ',
                    style: context.text.labelMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: '${log.actualReps}',
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: ' reps',
                    style: context.text.labelMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isTopSet)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.colors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: context.colors.warning.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                'TOP',
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.warning,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: context.text.labelMedium?.copyWith(
            color: accent,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _CoachingAdvice extends StatelessWidget {
  const _CoachingAdvice({required this.coaching});
  final CoachingAnalysis coaching;

  @override
  Widget build(BuildContext context) {
    final score = coaching.performanceScore ?? 1.0;
    final isGreat = score >= 1.0;
    final accent = isGreat ? context.colors.success : context.colors.warning;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.psychology_rounded, size: 16, color: accent),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              WorkoutPerformanceAnalyzer.friendlyRecommendation(
                coaching.recommendation,
              ),
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
