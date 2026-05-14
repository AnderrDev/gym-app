import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';

/// Diálogo único para confirmar "descartar cambios". Devuelve `true` si el
/// usuario confirma, `false`/`null` si cancela. Reemplaza los 3-4 dialogos
/// duplicados que vivían en cada editor.
class DiscardChangesDialog extends StatelessWidget {
  const DiscardChangesDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => const DiscardChangesDialog(),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('¿Descartar cambios?', style: AppTextStyles.heading2),
      content: Text(
        'Tenés cambios sin guardar. Si salís ahora se perderán.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'CANCELAR',
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'DESCARTAR',
            style: AppTextStyles.label.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
