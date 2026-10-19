import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/i18n/app_strings.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Fila con label + stepper (- / valor / +). Usada para series y reps.
class TargetStepperRow extends StatelessWidget {
  const TargetStepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.labelMedium?.copyWith(
                color: context.colors.textSecondary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _StepperButton(icon: Icons.remove_rounded, onTap: onMinus),
          SizedBox(
            width: 72,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: context.text.displayLarge?.copyWith(
                fontSize: 22,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          _StepperButton(icon: Icons.add_rounded, onTap: onPlus),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: context.colors.primary, size: 20),
      ),
    );
  }
}

/// Input numérico de peso (decimal). Solo permite dígitos y separador
/// decimal.
class TargetWeightField extends StatelessWidget {
  const TargetWeightField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'PESO',
              style: context.text.labelMedium?.copyWith(
                color: context.colors.textSecondary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: false,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: context.text.displayLarge?.copyWith(
                fontSize: 22,
                color: context.colors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                suffixText: AppStrings.kg,
                suffixStyle: context.text.labelMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
