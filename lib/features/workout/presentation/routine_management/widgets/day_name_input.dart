import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Input grande del nombre del día dentro del editor — sin chrome extra,
/// solo una línea con underline animado.
class DayNameInput extends StatelessWidget {
  const DayNameInput({
    super.key,
    required this.controller,
    required this.onChanged,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.sm,
        Spacing.lg,
        Spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOMBRE DEL DÍA',
            style: context.text.labelMedium?.copyWith(
              color: context.colors.textSecondary,
              letterSpacing: 1.2,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          TextField(
            controller: controller,
            onChanged: onChanged,
            readOnly: readOnly,
            enabled: !readOnly,
            style: context.text.displayLarge?.copyWith(
              fontSize: 22,
              letterSpacing: -0.4,
            ),
            decoration: InputDecoration(
              hintText: 'Pull Day · Espalda/Bíceps',
              hintStyle: context.text.displayLarge?.copyWith(
                color: context.colors.textDisabled,
                fontSize: 22,
                letterSpacing: -0.4,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              border: InputBorder.none,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.colors.divider),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: context.colors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
