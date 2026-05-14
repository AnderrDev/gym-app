import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/workout_performance_analyzer.dart';

/// Sheet de detalle de una sesión pasada. Muestra:
/// - Hero compacto con fecha formateada en español.
/// - Grilla de 3 métricas (Carga, Series, Ejercicios).
/// - Lista de ejercicios con resumen + serie más pesada destacada.
/// - Coaching cuando hay recomendación accionable.
class WorkoutHistoryBottomSheet extends StatelessWidget {
  final WorkoutSession session;
  final List<SetLog> logs;
  final List<Exercise> exercises;

  const WorkoutHistoryBottomSheet({
    super.key,
    required this.session,
    required this.logs,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    final groupedLogs = WorkoutPerformanceAnalyzer.groupByExerciseName(
      logs,
      exercises,
    );
    final totalVolume = logs.fold<double>(
      0,
      (s, l) => s + (l.actualWeight * l.actualReps),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const _Handle(),
            _Header(date: session.sessionDate, onClose: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  0,
                  Spacing.lg,
                  Spacing.xxxl,
                ),
                children: [
                  _MetricGrid(
                    totalVolume: totalVolume,
                    totalSets: logs.length,
                    exerciseCount: groupedLogs.length,
                  ),
                  const SizedBox(height: Spacing.lg),
                  ...groupedLogs.entries.map((entry) {
                    final coaching = session.coachingAnalysis?.firstWhereOrNull(
                      (a) =>
                          a.exerciseName == entry.key ||
                          a.exerciseId ==
                              exercises
                                  .firstWhereOrNull(
                                    (ex) => ex.name == entry.key,
                                  )
                                  ?.id,
                    );
                    return _HistoryExerciseCard(
                      exerciseName: entry.key,
                      logs: entry.value,
                      coaching: coaching,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

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

class _Header extends StatelessWidget {
  const _Header({required this.date, required this.onClose});

  final DateTime date;
  final VoidCallback onClose;

  String _formatDate(DateTime d) {
    // intl con locale es: `Lunes, 13 may 2026`.
    final dayName = DateFormat('EEEE', 'es').format(d);
    final rest = DateFormat('d MMM yyyy', 'es').format(d);
    final capDay = dayName[0].toUpperCase() + dayName.substring(1);
    return '$capDay · $rest';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.sm,
        Spacing.sm,
        Spacing.lg,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesión anterior',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.totalVolume,
    required this.totalSets,
    required this.exerciseCount,
  });

  final double totalVolume;
  final int totalSets;
  final int exerciseCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'CARGA',
            value: totalVolume.toStringAsFixed(0),
            secondary: 'kg·reps',
            accent: AppColors.textPrimary,
            icon: Icons.fitness_center_rounded,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _MetricCard(
            label: 'SERIES',
            value: '$totalSets',
            secondary: null,
            accent: AppColors.primary,
            icon: Icons.task_alt_rounded,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _MetricCard(
            label: 'EJERCICIOS',
            value: '$exerciseCount',
            secondary: null,
            accent: AppColors.info,
            icon: Icons.format_list_numbered_rounded,
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
                    fontSize: 20,
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

class _HistoryExerciseCard extends StatelessWidget {
  final String exerciseName;
  final List<SetLog> logs;
  final CoachingAnalysis? coaching;

  const _HistoryExerciseCard({
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.divider),
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
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${logs.length} ${logs.length == 1 ? 'serie' : 'series'} · '
                  '${exerciseVolume.toStringAsFixed(0)} kg·reps',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...logs.map(
            (log) => _SetRow(
              log: log,
              isTopSet: identical(log, topSet),
            ),
          ),
          if (coaching != null && coaching!.hasActionableAdvice) ...[
            const Divider(height: 1, color: AppColors.divider),
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
    final accent = isTopSet ? AppColors.warning : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
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
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: ' kg × ',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: '${log.actualReps}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: ' reps',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
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
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                'TOP',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.warning,
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
          style: AppTextStyles.label.copyWith(
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
    final isGood = score >= 0.85;
    final isGreat = score >= 1.0;
    final accent = isGreat
        ? AppColors.success
        : (isGood ? Colors.amber[400]! : Colors.orange[400]!);

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
          Icon(Icons.psychology_outlined, size: 16, color: accent),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              WorkoutPerformanceAnalyzer.friendlyRecommendation(
                coaching.recommendation,
              ),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
