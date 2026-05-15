import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
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
        fillColor: AppColors.surface,
        suffixText: suffix,
        suffixStyle: AppTextStyles.label.copyWith(
          color: AppColors.textSecondary,
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
          color: isDone ? AppColors.onPrimary : accent,
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

class KeyboardToggleChip extends StatelessWidget {
  const KeyboardToggleChip({
    super.key,
    required this.isActive,
    required this.onTap,
  });

  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 28,
        width: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(Icons.keyboard_alt_rounded, size: 16, color: color),
      ),
    );
  }
}

class QuickStepChip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final color = positive ? AppColors.primary : AppColors.textSecondary;
    // GestureDetector (no InkWell) para no robar el focus del TextField.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

