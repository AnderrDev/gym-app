import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';

class RoutineEditorAppBar extends StatelessWidget {
  const RoutineEditorAppBar({
    super.key,
    required this.activeRoutineId,
    required this.isDirty,
    required this.onClose,
    required this.onDelete,
    required this.onSave,
  });

  final String? activeRoutineId;
  final bool isDirty;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      titleSpacing: 0,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.close_rounded,
          color: AppColors.textPrimary,
        ),
        tooltip: 'Cerrar editor',
        onPressed: onClose,
      ),
      title: Text(
        activeRoutineId == null ? 'Nueva rutina' : 'Editar rutina',
        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800),
      ),
      actions: [
        if (activeRoutineId != null)
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            tooltip: 'Eliminar rutina',
            onPressed: onDelete,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: TextButton(
            onPressed: isDirty ? onSave : null,
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
        ),
      ],
    );
  }
}
