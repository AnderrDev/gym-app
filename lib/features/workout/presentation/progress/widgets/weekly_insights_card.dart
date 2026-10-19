import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';

/// Tarjeta de insights de la semana: 4 métricas (volumen, sesiones,
/// adherencia, tendencia) en un grid 2×2. Maneja también los estados
/// `error` y `null` (sin datos) sin saltar layout.
class WeeklyInsightsCard extends StatelessWidget {
  const WeeklyInsightsCard({
    super.key,
    required this.insights,
    required this.error,
  });

  final WeeklyInsights? insights;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(Radii.md),
      border: Border.all(color: context.colors.divider),
    );

    if (error != null) {
      return _MessageRow(
        icon: Icons.info_outline_rounded,
        message: 'No pudimos cargar los insights de esta semana.',
        decoration: decoration,
      );
    }

    final i = insights;
    if (i == null) {
      return _MessageRow(
        icon: Icons.bar_chart_rounded,
        message: 'Sin datos esta semana',
        decoration: decoration,
      );
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: decoration,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: Spacing.md,
        mainAxisSpacing: Spacing.md,
        childAspectRatio: 2.1,
        children: [
          _MetricCell(
            icon: Icons.local_fire_department_rounded,
            label: 'VOLUMEN',
            value: '${i.totalVolume.toStringAsFixed(0)} kg',
            valueColor: context.colors.textPrimary,
          ),
          _MetricCell(
            icon: Icons.event_available_rounded,
            label: 'SESIONES',
            value: '${i.completedSessions}/${i.plannedDays}',
            valueColor: context.colors.primary,
          ),
          _MetricCell(
            icon: Icons.flag_circle_rounded,
            label: 'ADHERENCIA',
            value: '${i.adherenceRate.toStringAsFixed(0)}%',
            valueColor: context.colors.success,
          ),
          _MetricCell(
            icon: i.volumeTrendPercent >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            label: 'TENDENCIA',
            value:
                '${i.volumeTrendPercent >= 0 ? '+' : ''}${i.volumeTrendPercent.toStringAsFixed(1)}%',
            valueColor: i.volumeTrendPercent >= 0
                ? context.colors.success
                : context.colors.error,
          ),
        ],
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.icon,
    required this.message,
    required this.decoration,
  });

  final IconData icon;
  final String message;
  final BoxDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: decoration,
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.colors.textSecondary),
          const SizedBox(width: Spacing.sm),
          Expanded(child: Text(message, style: context.text.bodySmall)),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(icon, color: context.colors.primary, size: 20),
            const SizedBox(width: Spacing.xs),
            Expanded(
              child: Text(
                label,
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.textSecondary,
                  letterSpacing: 1,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          value,
          style: context.text.headlineMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
