import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/utils/routine_color.dart';

/// Footer del `RoutineListCard`. La rutina activa muestra un estado
/// ("Rutina activa"), no un botón deshabilitado; el resto ofrece ACTIVAR
/// como acción tonal (no rellena: con varias cards en pantalla no debe
/// competir con el FAB) y, si es ajena y pública, CREAR MI COPIA.
class RoutineCardActions extends StatelessWidget {
  const RoutineCardActions({
    super.key,
    required this.isActive,
    required this.accent,
    required this.onActivate,
    this.onFork,
  });

  final bool isActive;
  final Color accent;
  final VoidCallback onActivate;

  /// Cuando la rutina es ajena y pública, la lista pasa este callback para
  /// ofrecer "CREAR MI COPIA" como acción secundaria. `null` lo oculta.
  final VoidCallback? onFork;

  @override
  Widget build(BuildContext context) {
    // Va como `textStyle` del botón (sin color) para que el texto tome el
    // `foregroundColor`; un `style` en el `Text` lo pisaría.
    final labelStyle = context.text.labelLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
      fontSize: 13,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.md),
    );

    if (isActive) {
      return SizedBox(
        height: 44,
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: accent, size: 20),
            const SizedBox(width: Spacing.sm),
            Text(
              'Rutina activa',
              style: context.text.bodyMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onFork != null) ...[
          TextButton.icon(
            onPressed: onFork,
            icon: const Icon(Icons.copy_all_rounded, size: 18),
            label: const Text('CREAR MI COPIA'),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.textSecondary,
              textStyle: labelStyle,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              shape: shape,
            ),
          ),
          const SizedBox(width: Spacing.xs),
        ],
        TextButton.icon(
          onPressed: onActivate,
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          label: const Text('ACTIVAR'),
          style: TextButton.styleFrom(
            foregroundColor: accent,
            textStyle: labelStyle,
            backgroundColor: RoutineColor.tint(context, accent),
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            shape: shape,
          ),
        ),
      ],
    );
  }
}
