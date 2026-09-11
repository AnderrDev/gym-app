import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';

/// Diálogo de confirmación para eliminar una rutina. Devuelve `true` si el
/// usuario confirma, `false`/`null` si cancela.
class DeleteRoutineDialog extends StatelessWidget {
  const DeleteRoutineDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const DeleteRoutineDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('¿Eliminar Rutina?', style: context.text.headlineMedium),
      content: Text(
        'Esta acción no se puede deshacer. Se borrarán todos los días y '
        'configuraciones asociadas.',
        style: context.text.bodyMedium?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'CANCELAR',
            style: context.text.labelMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'ELIMINAR',
            style: context.text.labelMedium?.copyWith(
              color: context.colors.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
