import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';

class RoutineEditorAppBar extends StatelessWidget {
  const RoutineEditorAppBar({
    super.key,
    required this.activeRoutineId,
    required this.isDirty,
    required this.isOwner,
    required this.onClose,
    required this.onDelete,
    required this.onSave,
  });

  final String? activeRoutineId;
  final bool isDirty;

  /// `false` cuando la rutina abierta no pertenece al usuario actual (vista
  /// pública). En ese caso ocultamos GUARDAR/ELIMINAR — el CTA de copia vive
  /// en el body para que sea inconfundible.
  final bool isOwner;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isExisting = activeRoutineId != null;
    final title = !isExisting
        ? 'Nueva rutina'
        : (isOwner ? 'Editar rutina' : 'Vista previa');
    return SliverAppBar(
      pinned: true,
      titleSpacing: 0,
      backgroundColor: colors.background,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close_rounded, color: colors.textPrimary),
        tooltip: 'Cerrar editor',
        onPressed: onClose,
      ),
      title: Text(
        title,
        style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      actions: [
        if (isExisting && isOwner)
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: colors.error),
            tooltip: 'Eliminar rutina',
            onPressed: onDelete,
          ),
        if (isOwner)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: TextButton(
              onPressed: isDirty ? onSave : null,
              child: Text(
                'GUARDAR',
                style: context.text.labelMedium?.copyWith(
                  color: isDirty
                      ? colors.primary
                      : colors.textSecondary.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
