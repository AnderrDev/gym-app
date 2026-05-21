import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Footer del `RoutineListCard` con el botón ACTIVAR / ACTIVADA. El
/// disabled state se usa cuando la rutina ya es la activa del usuario.
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
    final bg = isActive ? accent.withValues(alpha: 0.15) : accent;
    final fg = isActive ? accent : context.colors.background;
    final label = isActive ? 'ACTIVADA' : 'ACTIVAR';
    final icon = isActive
        ? Icons.check_circle_rounded
        : Icons.play_arrow_rounded;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onFork != null) ...[
          TextButton.icon(
            onPressed: onFork,
            icon: Icon(
              Icons.copy_all_rounded,
              color: context.colors.textSecondary,
              size: 16,
            ),
            label: Text(
              'CREAR MI COPIA',
              style: context.text.labelMedium?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 11,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: context.colors.divider.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
        ],
        TextButton.icon(
          onPressed: isActive ? null : onActivate,
          icon: Icon(icon, color: fg, size: 18),
          label: Text(
            label,
            style: context.text.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: bg,
            disabledBackgroundColor: bg,
            disabledForegroundColor: fg,
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
