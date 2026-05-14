import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';

/// Bottom sheet de cierre de sesión. Rediseñado con jerarquía clara:
/// hero centrado, métricas en grilla, sección de PRs, comparación vs
/// anterior y coaching para la próxima. Cierra con un par de CTAs;
/// `FINALIZAR Y GUARDAR` dispara el commit al backend (el loader vive
/// en el page padre vía `RoutineDayLoadingPhase`).
class WorkoutSummaryBottomSheet extends StatelessWidget {
  final int totalTargetSets;
  final int totalCompletedSets;
  final double totalVolume;
  final List<Exercise> exercises;
  final List<SetLog> currentLogs;
  final List<SetLog> lastLogs;
  final List<CoachingAnalysis> analysis;
  final VoidCallback onContinue;
  final VoidCallback onFinishAndSave;

  const WorkoutSummaryBottomSheet({
    super.key,
    required this.totalTargetSets,
    required this.totalCompletedSets,
    required this.totalVolume,
    required this.exercises,
    required this.currentLogs,
    required this.lastLogs,
    required this.analysis,
    required this.onContinue,
    required this.onFinishAndSave,
  });

  @override
  Widget build(BuildContext context) {
    final isStrictlyCompleted =
        totalTargetSets > 0 && totalCompletedSets >= totalTargetSets;
    final prs = _computePrs();
    final comparisons = _computeComparisons();
    final coaching =
        analysis.where((a) => a.recommendation.isNotEmpty).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            _Handle(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  Spacing.xl,
                  Spacing.sm,
                  Spacing.xl,
                  Spacing.xxxl,
                ),
                children: [
                  _Hero(
                    isStrictlyCompleted: isStrictlyCompleted,
                    missingSets: totalTargetSets - totalCompletedSets,
                  ),
                  const SizedBox(height: Spacing.lg),
                  _MetricGrid(
                    completedSets: totalCompletedSets,
                    targetSets: totalTargetSets,
                    volume: totalVolume,
                    prCount: prs.length,
                  ),
                  if (prs.isNotEmpty) ...[
                    const SizedBox(height: Spacing.xl),
                    const _SectionLabel(
                      text: 'Nuevos récords',
                      icon: Icons.emoji_events_rounded,
                      iconColor: AppColors.warning,
                    ),
                    const SizedBox(height: Spacing.sm),
                    ...prs.map((pr) => _PrRow(pr: pr)),
                  ],
                  if (comparisons.isNotEmpty) ...[
                    const SizedBox(height: Spacing.xl),
                    const _SectionLabel(
                      text: 'Vs sesión anterior',
                      icon: Icons.compare_arrows_rounded,
                      iconColor: AppColors.primary,
                    ),
                    const SizedBox(height: Spacing.sm),
                    ...comparisons.map((c) => _ComparisonRow(data: c)),
                  ],
                  if (coaching.isNotEmpty) ...[
                    const SizedBox(height: Spacing.xl),
                    const _SectionLabel(
                      text: 'Para la próxima',
                      icon: Icons.psychology_outlined,
                      iconColor: AppColors.info,
                    ),
                    const SizedBox(height: Spacing.sm),
                    ...coaching.map((c) => _CoachingRow(item: c)),
                  ],
                  const SizedBox(height: Spacing.xl),
                  _ActionRow(
                    onContinue: onContinue,
                    onFinishAndSave: onFinishAndSave,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_PrInfo> _computePrs() {
    final out = <_PrInfo>[];
    for (final ex in exercises) {
      final curr = currentLogs.where((l) => l.exerciseId == ex.id);
      if (curr.isEmpty) continue;
      final currMax = curr.fold<double>(
        0,
        (m, l) => l.actualWeight > m ? l.actualWeight : m,
      );
      final prev = lastLogs.where((l) => l.exerciseId == ex.id);
      final prevMax = prev.isEmpty
          ? 0.0
          : prev.fold<double>(
              0,
              (m, l) => l.actualWeight > m ? l.actualWeight : m,
            );
      if (currMax > prevMax && currMax > 0) {
        // Reps usadas en la serie que rompió récord (la más pesada).
        final prSet = curr.reduce(
          (a, b) => a.actualWeight >= b.actualWeight ? a : b,
        );
        out.add(
          _PrInfo(
            exerciseName: ex.name,
            currentWeight: currMax,
            previousWeight: prevMax,
            reps: prSet.actualReps,
          ),
        );
      }
    }
    return out;
  }

  List<_ComparisonInfo> _computeComparisons() {
    if (lastLogs.isEmpty) return const [];
    final out = <_ComparisonInfo>[];
    for (final ex in exercises) {
      final curr = currentLogs.where((l) => l.exerciseId == ex.id).toList();
      final prev = lastLogs.where((l) => l.exerciseId == ex.id).toList();
      if (curr.isEmpty && prev.isEmpty) continue;
      final currAvgW = _avgWeight(curr);
      final prevAvgW = _avgWeight(prev);
      out.add(
        _ComparisonInfo(
          exerciseName: ex.name,
          currentSets: curr.length,
          previousSets: prev.length,
          currentAvgWeight: currAvgW,
          previousAvgWeight: prevAvgW,
        ),
      );
    }
    return out;
  }

  static double _avgWeight(List<SetLog> logs) {
    if (logs.isEmpty) return 0.0;
    final total = logs.fold<double>(0, (s, l) => s + l.actualWeight);
    return total / logs.length;
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.isStrictlyCompleted, required this.missingSets});

  final bool isStrictlyCompleted;
  final int missingSets;

  @override
  Widget build(BuildContext context) {
    final color = isStrictlyCompleted ? AppColors.success : AppColors.primary;
    final icon = isStrictlyCompleted
        ? Icons.check_circle_rounded
        : Icons.pending_actions_rounded;
    final title = isStrictlyCompleted ? '¡Rutina completada!' : 'Sesión finalizada';
    final subtitle = isStrictlyCompleted
        ? 'Cumpliste todo el volumen programado'
        : 'Faltan $missingSets series para el objetivo completo';
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
          ),
          child: Icon(icon, color: color, size: 38),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          title,
          style: AppTextStyles.heading1.copyWith(fontSize: 22),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.completedSets,
    required this.targetSets,
    required this.volume,
    required this.prCount,
  });

  final int completedSets;
  final int targetSets;
  final double volume;
  final int prCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'SERIES',
            value: '$completedSets',
            secondary: targetSets > 0 ? '/ $targetSets' : null,
            accent: AppColors.primary,
            icon: Icons.task_alt_rounded,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _MetricCard(
            label: 'CARGA',
            value: volume.toStringAsFixed(0),
            secondary: 'kg·reps',
            accent: AppColors.textPrimary,
            icon: Icons.fitness_center_rounded,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _MetricCard(
            label: 'RÉCORDS',
            value: '$prCount',
            secondary: prCount == 1 ? 'nuevo' : 'nuevos',
            accent: prCount > 0 ? AppColors.warning : AppColors.textSecondary,
            icon: Icons.emoji_events_rounded,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.secondary,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final String? secondary;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTextStyles.heading2.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                if (secondary != null)
                  TextSpan(
                    text: ' $secondary',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.text,
    required this.icon,
    required this.iconColor,
  });

  final String text;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 14),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _PrInfo {
  const _PrInfo({
    required this.exerciseName,
    required this.currentWeight,
    required this.previousWeight,
    required this.reps,
  });

  final String exerciseName;
  final double currentWeight;
  final double previousWeight;
  final int reps;

  double get delta => currentWeight - previousWeight;
}

class _PrRow extends StatelessWidget {
  const _PrRow({required this.pr});
  final _PrInfo pr;

  String _fmt(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: AppColors.warning,
            size: 18,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pr.exerciseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_fmt(pr.currentWeight)} kg × ${pr.reps} reps',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${_fmt(pr.delta)} kg',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonInfo {
  const _ComparisonInfo({
    required this.exerciseName,
    required this.currentSets,
    required this.previousSets,
    required this.currentAvgWeight,
    required this.previousAvgWeight,
  });

  final String exerciseName;
  final int currentSets;
  final int previousSets;
  final double currentAvgWeight;
  final double previousAvgWeight;
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.data});
  final _ComparisonInfo data;

  @override
  Widget build(BuildContext context) {
    final delta = data.currentAvgWeight - data.previousAvgWeight;
    final isUp = delta > 0.05;
    final isDown = delta < -0.05;
    final color = isUp
        ? AppColors.success
        : isDown
        ? AppColors.error
        : AppColors.textSecondary;
    final icon = isUp
        ? Icons.trending_up_rounded
        : isDown
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;
    final deltaStr = delta.abs() < 0.05
        ? '='
        : (delta > 0 ? '+' : '−') + delta.abs().toStringAsFixed(1);
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.exerciseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${data.currentAvgWeight.toStringAsFixed(1)} kg avg · '
                  '${data.currentSets} series',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                deltaStr,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'kg',
                style: AppTextStyles.label.copyWith(
                  color: color,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoachingRow extends StatelessWidget {
  const _CoachingRow({required this.item});
  final CoachingAnalysis item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.exerciseName,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.recommendation,
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.onContinue,
    required this.onFinishAndSave,
  });

  final VoidCallback onContinue;
  final VoidCallback onFinishAndSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: onContinue,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
            ),
            child: Text(
              'CONTINUAR',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: onFinishAndSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.md),
              ),
            ),
            child: Text(
              'FINALIZAR Y GUARDAR',
              style: AppTextStyles.label.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
