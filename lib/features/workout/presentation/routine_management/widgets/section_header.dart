import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';

/// Label de sección en mayúsculas con contador opcional a la derecha y un
/// hint terciario (microcopy para gestos: "Mantén para reordenar", etc).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.hint,
  });

  final String label;

  /// Widget colocado al final de la fila (típicamente un contador como
  /// "4 DÍAS" o "EJERCICIOS · 6"). Opcional.
  final Widget? trailing;

  /// Hint de microcopy debajo del label, usado para indicar affordance de
  /// gestos (ej. "Mantén para reordenar").
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.textSecondary,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: context.colors.textDisabled,
              ),
              const SizedBox(width: 4),
              Text(
                hint!,
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.textDisabled,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
