import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/utils/routine_color.dart';

/// Header con resumen visible apenas se entra: "Tenés X rutinas · Activa: Y".
/// Si no hay rutina activa el subtítulo cambia al CTA "Activá una para
/// empezar".
class RoutineListSummaryHeader extends StatelessWidget {
  const RoutineListSummaryHeader({
    super.key,
    required this.totalCount,
    this.activeRoutine,
  });

  final int totalCount;
  final Routine? activeRoutine;

  @override
  Widget build(BuildContext context) {
    final hasActive = activeRoutine != null;
    final accent = hasActive
        ? RoutineColor.accentFor(activeRoutine!.name)
        : context.colors.primary;
    return Padding(
      // Más aire arriba (después del AppBar) y abajo (antes del buscador)
      // para que el header no quede pegado a los bloques vecinos.
      padding: const EdgeInsets.fromLTRB(
        Spacing.lgPlus,
        Spacing.md,
        Spacing.lgPlus,
        Spacing.lg,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lgPlus,
          Spacing.lg,
          Spacing.lgPlus,
          Spacing.lg,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withValues(alpha: hasActive ? 0.35 : 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasActive ? Icons.bolt_rounded : Icons.list_alt_rounded,
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    totalCount == 0
                        ? 'Aún no tenés rutinas'
                        : '$totalCount ${totalCount == 1 ? "rutina" : "rutinas"} disponibles',
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasActive
                        ? 'Activa: ${activeRoutine!.name}'
                        : 'Activá una para empezar a entrenar',
                    style: context.text.labelMedium?.copyWith(
                      color: hasActive ? accent : context.colors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
