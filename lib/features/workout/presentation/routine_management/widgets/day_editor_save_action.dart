import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';

/// Botón GUARDAR del app-bar del `DayEditorPage`. Se desactiva si el
/// estado no está dirty.
class DayEditorSaveAction extends StatelessWidget {
  const DayEditorSaveAction({
    super.key,
    required this.isDirty,
    required this.onSave,
  });

  final bool isDirty;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: TextButton(
        onPressed: isDirty ? onSave : null,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor:
              AppColors.textSecondary.withValues(alpha: 0.4),
        ),
        child: Text(
          'GUARDAR',
          style: AppTextStyles.label.copyWith(
            color: isDirty
                ? AppColors.primary
                : AppColors.textSecondary.withValues(alpha: 0.5),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
