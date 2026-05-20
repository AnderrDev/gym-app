import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/ui/adaptive/adaptive_scroll_physics.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';

/// Métricas semanales compactas. Fila scrollable horizontal con chips
/// densas (adherencia, tendencia, PRs, sesiones, volumen total). Cuando
/// no hay insights pero sí error muestra una microalerta inline,
/// discreta para no romper jerarquía con la lista de días.
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
    final trendIcon = trendUp
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final trendLabel = trendUp
        ? '+${i.volumeTrendPercent.toStringAsFixed(1)}%'
        : '${i.volumeTrendPercent.toStringAsFixed(1)}%';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: AdaptiveScrollPhysics.preferred,
      child: Row(
        children: [
          _Metric(
            icon: Icons.flag_circle_rounded,
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
            icon: Icons.emoji_events_rounded,
            label: 'PRs',
            value: '${i.personalRecords}',
            color: AppColors.warning,
          ),
          const SizedBox(width: Spacing.sm),
          _Metric(
            icon: Icons.event_available_rounded,
            label: 'Sesiones',
            value: '${i.completedSessions}/${i.plannedDays}',
            color: AppColors.info,
          ),
          const SizedBox(width: Spacing.sm),
          _Metric(
            icon: Icons.local_fire_department_rounded,
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: Spacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
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
