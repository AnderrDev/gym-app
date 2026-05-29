import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';

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
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('¿Eliminar día?', style: context.text.headlineMedium),
      content: Text(
        'Se borrará "$dayName" y todos sus ejercicios.',
        style: context.text.bodyMedium?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'CANCELAR',
            style:
                context.text.labelMedium?.copyWith(color: context.colors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'ELIMINAR',
            style: context.text.labelMedium?.copyWith(color: context.colors.error),
          ),
        ),
      ],
    );
  }
}
