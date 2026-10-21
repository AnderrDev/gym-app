import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';

/// Línea de resumen bajo el título: "4 rutinas · Activa: Fuerza". Sin
/// rutina activa invita a activar una. Va como texto y no como card: la
/// card de la rutina activa ya la destaca y así la lista empieza antes.
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
    final count = totalCount == 0
        ? 'Aún no tienes rutinas'
        : '$totalCount ${totalCount == 1 ? "rutina" : "rutinas"}';
    final active = activeRoutine == null
        ? 'Activa una para empezar a entrenar'
        : 'Activa: ${activeRoutine!.name}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lgPlus,
        0,
        Spacing.lgPlus,
        Spacing.lg,
      ),
      child: Text(
        '$count · $active',
        style: context.text.bodyMedium?.copyWith(
          color: context.colors.textSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
