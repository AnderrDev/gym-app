import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/day_editor_save_action.dart';

class DayEditorAppBar extends StatelessWidget {
  const DayEditorAppBar({
    super.key,
    required this.isDirty,
    required this.onBack,
    required this.onSave,
    this.isOwner = true,
  });

  final bool isDirty;
  final bool isOwner;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SliverAppBar(
      pinned: true,
      titleSpacing: 0,
      backgroundColor: colors.background,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: colors.textPrimary,
          size: 20,
        ),
        tooltip: 'Volver',
        onPressed: onBack,
      ),
      title: Text(
        isOwner ? 'Editar día' : 'Vista previa',
        style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      actions: [
        if (isOwner) DayEditorSaveAction(isDirty: isDirty, onSave: onSave),
        const SizedBox(width: 8),
      ],
    );
  }
}
