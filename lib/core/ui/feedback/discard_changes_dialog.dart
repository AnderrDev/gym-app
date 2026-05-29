import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';

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
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('¿Descartar cambios?', style: context.text.headlineMedium),
      content: Text(
        'Tenés cambios sin guardar. Si salís ahora se perderán.',
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
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'DESCARTAR',
            style: context.text.labelMedium?.copyWith(
              color: context.colors.error,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
