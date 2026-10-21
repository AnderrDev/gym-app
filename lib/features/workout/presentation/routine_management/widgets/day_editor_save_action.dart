import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';

/// Botón GUARDAR del app-bar de los editores (`DayEditorPage`,
/// `RoutineEditorPage`). Se desactiva si el estado no está dirty; si además
/// lo editado ya existe en el servidor ([isSaved]) dice "GUARDADO" para que
/// no parezca que falta guardar (p. ej. una rutina recién creada al añadir
/// su primer día).
class DayEditorSaveAction extends StatelessWidget {
  const DayEditorSaveAction({
    super.key,
    required this.isDirty,
    required this.onSave,
    this.isSaved = true,
  });

  final bool isDirty;
  final VoidCallback onSave;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    final saved = !isDirty && isSaved;
    final color = isDirty
        ? context.colors.primary
        : saved
        ? context.colors.successText
        : context.colors.textSecondary.withValues(alpha: 0.5);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: TextButton(
        onPressed: isDirty ? onSave : null,
        style: TextButton.styleFrom(
          foregroundColor: context.colors.primary,
          disabledForegroundColor: color,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (saved) ...[
              Icon(Icons.check_rounded, size: 16, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              saved ? 'GUARDADO' : 'GUARDAR',
              style: context.text.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
