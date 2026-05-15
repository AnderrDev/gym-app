import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Input grande del nombre del día dentro del editor — sin chrome extra,
/// solo una línea con underline animado.
class DayNameInput extends StatelessWidget {
  const DayNameInput({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

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
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          TextField(
            controller: controller,
            onChanged: onChanged,
            style:
                AppTextStyles.heading1.copyWith(fontSize: 22, letterSpacing: -0.4),
            decoration: InputDecoration(
              hintText: 'Pull Day · Espalda/Bíceps',
              hintStyle: AppTextStyles.heading1.copyWith(
                color: AppColors.textDisabled,
                fontSize: 22,
                letterSpacing: -0.4,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              border: InputBorder.none,
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
