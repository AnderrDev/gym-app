import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/utils/date_format.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/weight_format.dart';

/// Stripe horizontal con 3 métricas resumen: actual, récord y delta.
/// Pensado para vivir sobre un chart y darle al usuario la "respuesta"
/// numérica sin tener que descifrar la curva.
class StatStripe extends StatelessWidget {
  const StatStripe({
    super.key,
    required this.actualLabel,
    required this.recordLabel,
    required this.delta,
    required this.unit,
    this.recordReached = false,
    this.deltaCaption = 'VS ANTERIOR',
    this.formatter = formatDecimal,
  });

  /// Formato de la diferencia, el mismo que el de [actualLabel] (p. ej.
  /// `formatVolume` para que salga "+1.855" y no "+1855").
  final String Function(double) formatter;

  /// Frente a qué se compara [delta]: "VS SESIÓN ANTERIOR", etc.
  final String deltaCaption;

  /// Texto del valor actual (ya formateado, sin unidad). Ej `82.5`.
  final String actualLabel;

  /// Texto del récord histórico (sin unidad).
  final String recordLabel;

  /// Diferencia firmada con respecto al valor anterior. `null` cuando no
  /// hay sesión previa (1 sola sesión en la historia).
  final double? delta;

  /// Unidad para mostrar al lado de los valores. Ej `kg`, `kg·reps`.
  final String unit;

  /// `true` si actual == récord — pinta un "AHORA" en color de éxito.
  final bool recordReached;

  String _formatDelta(double d) {
    final abs = d.abs();
    final formatted = formatter(abs);
    if (d > 0) return '+$formatted';
    if (d < 0) return '−$formatted';
    return '0';
  }

  @override
  Widget build(BuildContext context) {
    final actualColor = recordReached
        ? context.colors.successText
        : context.colors.textPrimary;
    return Row(
      children: [
        Expanded(
          child: _Chip(
            caption: 'ACTUAL',
            value: actualLabel,
            unit: unit,
            valueColor: actualColor,
          ),
        ),
        const SizedBox(width: Spacing.xs),
        Expanded(
          child: _Chip(
            caption: 'RÉCORD',
            value: recordLabel,
            unit: unit,
            valueColor: context.colors.warningText,
          ),
        ),
        const SizedBox(width: Spacing.xs),
        Expanded(
          child: _DeltaChip(
            delta: delta,
            unit: unit,
            caption: deltaCaption,
            formatter: _formatDelta,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.caption,
    required this.value,
    required this.unit,
    required this.valueColor,
  });

  final String caption;
  final String value;
  final String unit;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            caption,
            style: context.text.labelSmall?.copyWith(
              color: context.colors.textSecondary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: context.text.bodyLarge?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
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

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({
    required this.delta,
    required this.unit,
    required this.caption,
    required this.formatter,
  });

  final double? delta;
  final String caption;
  final String unit;
  final String Function(double) formatter;

  @override
  Widget build(BuildContext context) {
    final d = delta;
    final isNeutral = d == null;
    final isUp = !isNeutral && d > 0;
    final isDown = !isNeutral && d < 0;
    final color = isNeutral
        ? context.colors.textSecondary
        : isUp
        ? context.colors.successText
        : isDown
        ? context.colors.error
        : context.colors.textSecondary;
    final icon = isNeutral
        ? Icons.remove_rounded
        : isUp
        ? Icons.trending_up_rounded
        : isDown
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall?.copyWith(
              color: color,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: isNeutral ? '—' : formatter(d),
                        style: context.text.bodyLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      if (!isNeutral)
                        TextSpan(
                          text: ' $unit',
                          style: context.text.labelSmall?.copyWith(
                            color: color,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Desde el 6 oct: +7,5 kg (+15 %)": el cambio en todo el periodo
/// mostrado, no sólo frente a la sesión anterior.
class PeriodChangeLine extends StatelessWidget {
  const PeriodChangeLine({
    super.key,
    required this.since,
    required this.first,
    required this.last,
    required this.unit,
    required this.formatter,
  });

  final DateTime since;
  final double first;
  final double last;
  final String unit;
  final String Function(double) formatter;

  @override
  Widget build(BuildContext context) {
    final diff = last - first;
    final color = diff > 0
        ? context.colors.successText
        : diff < 0
        ? context.colors.error
        : context.colors.textSecondary;
    final sign = diff > 0
        ? '+'
        : diff < 0
        ? '−'
        : '';
    final pct = first > 0
        ? ' ($sign${(diff.abs() / first * 100).toStringAsFixed(0)} %)'
        : '';
    return Row(
      children: [
        Icon(
          Icons.history_rounded,
          size: 16,
          color: context.colors.textSecondary,
        ),
        const SizedBox(width: Spacing.xs),
        Text(
          'Desde el ${AppDateFormat.dayMonthShort(since)}: ',
          style: context.text.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            diff == 0
                ? 'sin cambios'
                : '$sign${formatter(diff.abs())} $unit$pct',
            style: context.text.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
