import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';

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
          foregroundColor: context.colors.primary,
          disabledForegroundColor:
              context.colors.textSecondary.withValues(alpha: 0.4),
        ),
        child: Text(
          'GUARDAR',
          style: context.text.labelMedium?.copyWith(
            color: isDirty
                ? context.colors.primary
                : context.colors.textSecondary.withValues(alpha: 0.5),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
