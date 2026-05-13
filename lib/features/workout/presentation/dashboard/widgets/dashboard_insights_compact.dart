import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';

/// Métricas semanales compactas. Una fila scrollable horizontal con chips
/// densas (adherencia, tendencia, PRs, sesiones, volumen total). Si no hay
/// insights y hay error muestra una microalerta inline.
class DashboardInsightsCompact extends StatelessWidget {
  const DashboardInsightsCompact({
    super.key,
    required this.insights,
    required this.error,
  });

  final WeeklyInsights? insights;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return const _ErrorChip();
    }
    final i = insights;
    if (i == null) return const SizedBox.shrink();

    final trendUp = i.volumeTrendPercent >= 0;
    final trendColor = trendUp ? AppColors.success : AppColors.error;
    final trendIcon = trendUp ? Icons.trending_up : Icons.trending_down;
    final trendLabel = trendUp
        ? '+${i.volumeTrendPercent.toStringAsFixed(1)}%'
        : '${i.volumeTrendPercent.toStringAsFixed(1)}%';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Metric(
            icon: Icons.flag_circle,
            label: 'Adherencia',
            value: '${i.adherenceRate.toStringAsFixed(0)}%',
            color: AppColors.primary,
          ),
          const SizedBox(width: Spacing.sm),
          _Metric(
            icon: trendIcon,
            label: 'Volumen',
            value: trendLabel,
            color: trendColor,
          ),
          const SizedBox(width: Spacing.sm),
          _Metric(
            icon: Icons.emoji_events,
            label: 'PRs',
            value: '${i.personalRecords}',
            color: AppColors.warning,
          ),
          const SizedBox(width: Spacing.sm),
          _Metric(
            icon: Icons.event_available,
            label: 'Sesiones',
            value: '${i.completedSessions}/${i.plannedDays}',
            color: AppColors.info,
          ),
          const SizedBox(width: Spacing.sm),
          _Metric(
            icon: Icons.fitness_center,
            label: 'Total',
            value: '${i.totalVolume.toStringAsFixed(0)} kg',
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: Spacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorChip extends StatelessWidget {
  const _ErrorChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              'Insights no disponibles esta semana',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
