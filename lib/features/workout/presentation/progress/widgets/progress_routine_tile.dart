import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';

/// Fila clickable de rutina dentro del tab "Progreso": navega a las stats
/// de esa rutina al tocar.
class ProgressRoutineTile extends StatelessWidget {
  const ProgressRoutineTile({
    super.key,
    required this.routine,
    required this.onTap,
  });

  final Routine routine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: context.colors.divider),
          ),
          child: Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 20,
                color: context.colors.primary,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      routine.name,
                      style: context.text.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text('Ver progreso', style: context.text.bodySmall),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: context.colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado vacío del tab "Progreso": invita a explorar el catálogo de
/// rutinas desde la pestaña Rutinas.
class ProgressEmptyRoutines extends StatelessWidget {
  const ProgressEmptyRoutines({super.key, required this.onGoToRoutines});

  final VoidCallback onGoToRoutines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 40,
            color: context.colors.textSecondary,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Sin rutinas asignadas',
            style:
                context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Explorá el catálogo desde la pestaña Rutinas.',
            style: context.text.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          OutlinedButton(
            onPressed: onGoToRoutines,
            child: Text(
              'IR A RUTINAS',
              style: context.text.labelMedium?.copyWith(
                color: context.colors.primary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
