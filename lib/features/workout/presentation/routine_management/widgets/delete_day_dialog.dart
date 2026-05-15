import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';

/// Diálogo de confirmación para eliminar un día de una rutina.
/// Devuelve `true` si el usuario confirma; `false`/`null` si cancela.
class DeleteDayDialog extends StatelessWidget {
  const DeleteDayDialog({super.key, required this.dayName});

  final String dayName;

  static Future<bool> show(BuildContext context, {required String dayName}) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteDayDialog(dayName: dayName),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('¿Eliminar día?', style: AppTextStyles.heading2),
      content: Text(
        'Se borrará "$dayName" y todos sus ejercicios.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'CANCELAR',
            style:
                AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'ELIMINAR',
            style: AppTextStyles.label.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}
