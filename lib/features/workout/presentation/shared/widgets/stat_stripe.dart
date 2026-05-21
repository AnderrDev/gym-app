import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

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
  });

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
    final formatted = abs % 1 == 0
        ? abs.toStringAsFixed(0)
        : abs.toStringAsFixed(1);
    if (d > 0) return '+$formatted';
    if (d < 0) return '−$formatted';
    return '0';
  }

  @override
  Widget build(BuildContext context) {
    final actualColor = recordReached
        ? context.colors.success
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
            valueColor: context.colors.warning,
          ),
        ),
        const SizedBox(width: Spacing.xs),
        Expanded(child: _DeltaChip(delta: delta, unit: unit, formatter: _formatDelta)),
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
            style: context.text.labelMedium?.copyWith(
              color: context.colors.textSecondary,
              fontSize: 9,
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
                  style: context.text.labelMedium?.copyWith(
                    color: context.colors.textSecondary,
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

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({
    required this.delta,
    required this.unit,
    required this.formatter,
  });

  final double? delta;
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
        ? context.colors.success
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
            'VS ANTERIOR',
            style: context.text.labelMedium?.copyWith(
              color: color,
              fontSize: 9,
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
                          style: context.text.labelMedium?.copyWith(
                            color: color,
                            fontSize: 10,
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
