import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';

/// Componentes leaf compartidos por las filas de serie y `CompleteSetSheet`.
/// Todos son stateless (salvo el hover de los chips).

/// Strip de chips `-2.5 / -1 / +1 / +2.5` (o el set de pasos que reciba).
class QuickStepStrip extends StatelessWidget {
  const QuickStepStrip({
    super.key,
    required this.steps,
    required this.formatter,
    required this.onTap,
  });

  final List<double> steps;
  final String Function(double) formatter;
  final void Function(double) onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: QuickStepChip(
              label: formatter(steps[i]),
              onTap: () => onTap(steps[i]),
              positive: steps[i] > 0,
            ),
          ),
        ],
      ],
    );
  }
}

class QuickStepChip extends StatefulWidget {
  const QuickStepChip({
    super.key,
    required this.label,
    required this.onTap,
    required this.positive,
  });

  final String label;
  final VoidCallback onTap;
  final bool positive;

  @override
  State<QuickStepChip> createState() => _QuickStepChipState();
}

class _QuickStepChipState extends State<QuickStepChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.positive
        ? context.colors.primary
        : context.colors.textSecondary;
    final bg = color.withValues(alpha: _hovered ? 0.2 : 0.1);
    // Focus(canRequestFocus: false) evita que en web el chip robe el focus
    // del TextField al hacer click.
    return Focus(
      canRequestFocus: false,
      descendantsAreFocusable: false,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => widget.onTap(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              widget.label,
              style: context.text.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Círculo numerado de la serie: relleno (completada), activo (la que
/// sigue) o neutro.
class SetCircle extends StatelessWidget {
  const SetCircle({
    super.key,
    required this.label,
    required this.filled,
    this.active = false,
  });

  final String label;
  final bool filled;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? context.colors.success
        : active
        ? context.colors.primary.withValues(alpha: 0.12)
        : Colors.transparent;
    final border = filled
        ? context.colors.success
        : active
        ? context.colors.primary
        : context.colors.textSecondary;
    final textColor = filled
        ? context.colors.onPrimary
        : active
        ? context.colors.primary
        : context.colors.textSecondary;

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
