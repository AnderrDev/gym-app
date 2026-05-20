import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_set_row_parts.dart';

/// Identifica cuál input está focuseado (peso vs reps) para decidir qué
/// strip de chips mostrar y a qué controller mutar.
enum SetRowFocusedField { none, weight, reps }

/// Etiqueta pequeña a la izquierda con la performance previa (ej. `60×8`).
class PrevPerformanceLabel extends StatelessWidget {
  const PrevPerformanceLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(
          color: AppColors.textSecondary.withValues(alpha: 0.8),
          fontSize: 11,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Fila inferior de chips que aparece bajo los inputs cuando uno tiene
/// focus. Combina [QuickStepStrip] (incrementos/decrementos rápidos)
/// con un [KeyboardToggleChip] al borde derecho para abrir el teclado
/// del sistema cuando el usuario quiere tipear un valor arbitrario.
class FocusChipsRow extends StatelessWidget {
  const FocusChipsRow({
    super.key,
    required this.focused,
    required this.keyboardField,
    required this.onBumpWeight,
    required this.onBumpReps,
    required this.onOpenKeyboardForFocused,
  });

  final SetRowFocusedField focused;
  final SetRowFocusedField keyboardField;
  final void Function(double) onBumpWeight;
  final void Function(int) onBumpReps;
  final VoidCallback onOpenKeyboardForFocused;

  static String _formatStep(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    // TextFieldTapRegion: por defecto TextField desfoquea cuando detecta
    // un tap fuera de su región (en web esto cierra el foco al tocar un
    // chip, colapsa la fila y el handler nunca corre). Marcando los chips
    // como parte de la misma "región de TextField", los taps acá quedan
    // dentro del grupo y el campo no pierde foco.
    return TextFieldTapRegion(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: focused == SetRowFocusedField.none
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: focused == SetRowFocusedField.weight
                          ? QuickStepStrip(
                              steps: const [-2.5, -1, 1, 2.5],
                              formatter: (v) => v > 0
                                  ? '+${_formatStep(v)}'
                                  : _formatStep(v),
                              onTap: onBumpWeight,
                            )
                          : QuickStepStrip(
                              steps: const [-1, 1, 2],
                              formatter: (v) => v > 0
                                  ? '+${v.toInt()}'
                                  : v.toInt().toString(),
                              onTap: (v) => onBumpReps(v.toInt()),
                            ),
                    ),
                    const SizedBox(width: 6),
                    // El tap normal en el campo solo muestra chips. El usuario
                    // habilita el teclado del sistema tocando este chip.
                    KeyboardToggleChip(
                      isActive: keyboardField == focused,
                      onTap: keyboardField == focused
                          ? null
                          : onOpenKeyboardForFocused,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class SetCircle extends StatelessWidget {
  final String label;
  final bool filled;
  final bool active;

  const SetCircle({
    super.key,
    required this.label,
    required this.filled,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? AppColors.success
        : active
        ? AppColors.primary.withValues(alpha: 0.12)
        : Colors.transparent;
    final border = filled
        ? AppColors.success
        : active
        ? AppColors.primary
        : AppColors.textSecondary;
    final textColor = filled
        ? AppColors.onPrimary
        : active
        ? AppColors.primary
        : AppColors.textSecondary;

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
