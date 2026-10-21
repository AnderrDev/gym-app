import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/training_history.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/weight_format.dart';

/// Resumen de una semana: entrenamientos, constancia, volumen y cambio
/// frente a la semana anterior, cada cifra con una línea que dice qué es
/// (antes "TENDENCIA +100%" no decía frente a qué). Maneja también `error`
/// y `null` (sin datos) sin saltar layout.
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
        message: 'No pudimos cargar el resumen de esta semana.',
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

    final change = percentChange(i.totalVolume, i.previousWeekVolume);
    // Verde/rojo solo cuando hay algo que celebrar o vigilar: "+0 %" o un
    // "0 %" a mitad de semana no son un logro.
    final changeColor = change == null || change.round() == 0
        ? context.colors.textSecondary
        : change > 0
        ? context.colors.successText
        : context.colors.error;

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricCell(
                  icon: Icons.event_available_rounded,
                  label: 'ENTRENAMIENTOS',
                  value: '${i.completedSessions}',
                  caption: i.plannedDays == 0
                      ? 'sin días planificados'
                      : 'de ${i.plannedDays} planificados',
                  valueColor: context.colors.primary,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _MetricCell(
                  icon: Icons.flag_circle_rounded,
                  label: 'CONSTANCIA',
                  value: '${i.adherenceRate.toStringAsFixed(0)} %',
                  caption: 'del plan cumplido',
                  valueColor: i.adherenceRate >= 80
                      ? context.colors.successText
                      : context.colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricCell(
                  icon: Icons.local_fire_department_rounded,
                  label: 'VOLUMEN',
                  value: '${formatVolume(i.totalVolume)} kg',
                  caption: 'peso × reps sumado',
                  valueColor: context.colors.textPrimary,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _MetricCell(
                  icon: change == null || change >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  label: 'CAMBIO',
                  value: change == null
                      ? '—'
                      : '${change >= 0 ? '+' : '−'}'
                            '${change.abs().toStringAsFixed(0)} %',
                  caption: change == null
                      ? 'vs semana anterior, que no tuvo volumen'
                      : 'vs ${formatVolume(i.previousWeekVolume)} kg la anterior',
                  valueColor: changeColor,
                ),
              ),
            ],
          ),
          if (i.personalRecords > 0) ...[
            const SizedBox(height: Spacing.lg),
            Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  size: 18,
                  color: context.colors.warningText,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    i.personalRecords == 1
                        ? '1 récord personal esta semana'
                        : '${i.personalRecords} récords personales esta semana',
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
    required this.caption,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: context.colors.primary, size: 18),
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
        Text(
          caption,
          style: context.text.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}
