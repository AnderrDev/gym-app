import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';

/// Componentes leaf usados por `ExerciseSetRow`. Se extraen para mantener
/// el archivo principal bajo 300 líneas. Todos son stateless.

class CompactNumberField extends StatelessWidget {
  const CompactNumberField({
    super.key,
    required this.controller,
    required this.suffix,
    required this.decimal,
    this.focusNode,
    this.suppressKeyboard = false,
  });

  final TextEditingController controller;
  final String suffix;
  final bool decimal;
  final FocusNode? focusNode;
  // `true` => `TextInputType.none` (campo focuseable pero el sistema no
  // muestra el teclado). `false` => número con decimales según el flag.
  final bool suppressKeyboard;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      showCursor: true,
      keyboardType: suppressKeyboard
          ? TextInputType.none
          : TextInputType.numberWithOptions(decimal: decimal),
      textAlign: TextAlign.center,
      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: context.colors.surface,
        suffixText: suffix,
        suffixStyle: AppTextStyles.label.copyWith(
          color: context.colors.textSecondary,
          fontSize: 10,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class SetSaveButton extends StatelessWidget {
  const SetSaveButton({
    super.key,
    required this.isDone,
    required this.accent,
    required this.onTap,
    this.tooltip,
  });

  final bool isDone;
  final Color accent;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDone ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent, width: 1.5),
        ),
        child: Icon(
          Icons.check_rounded,
          size: 20,
          color: isDone ? context.colors.onPrimary : accent,
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Strip de chips `-2.5 / -1 / +1 / +2.5` (o el set de pasos que reciba).
/// Aparece debajo de la fila cuando el input está focuseado y mutan el
/// controller del campo. No piden focus, así el input no pierde el cursor.
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

class KeyboardToggleChip extends StatefulWidget {
  const KeyboardToggleChip({
    super.key,
    required this.isActive,
    required this.onTap,
  });

  final bool isActive;
  final VoidCallback? onTap;

  @override
  State<KeyboardToggleChip> createState() => _KeyboardToggleChipState();
}

class _KeyboardToggleChipState extends State<KeyboardToggleChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isActive ? context.colors.primary : context.colors.textSecondary;
    // Focus(canRequestFocus: false) evita que en web el chip robe el focus
    // del TextField al hacer click — preserva la fila de chips visible.
    // MouseRegion: cursor pointer + tint en hover (no-op en touch puro).
    final bg = widget.isActive
        ? context.colors.primary.withValues(alpha: _hovered ? 0.3 : 0.2)
        : (_hovered ? context.colors.surfaceHighlight : context.colors.surface);
    return Focus(
      canRequestFocus: false,
      descendantsAreFocusable: false,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown:
              widget.onTap == null ? null : (_) => widget.onTap!(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 28,
            width: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.keyboard_alt_rounded, size: 16, color: color),
          ),
        ),
      ),
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
    final color =
        widget.positive ? context.colors.primary : context.colors.textSecondary;
    final bg = color.withValues(alpha: _hovered ? 0.2 : 0.1);
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
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              widget.label,
              style: AppTextStyles.label.copyWith(
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

