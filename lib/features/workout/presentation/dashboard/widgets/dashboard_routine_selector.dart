import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/molecules/app_card.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/utils/routine_color.dart';

class DashboardRoutineSelector extends StatelessWidget {
  final List<Routine> routines;
  final ValueChanged<Routine> onSelectRoutine;
  final ValueChanged<Routine> onOpenRoutineStats;

  const DashboardRoutineSelector({
    super.key,
    required this.routines,
    required this.onSelectRoutine,
    required this.onOpenRoutineStats,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Mis Rutinas', style: context.text.headlineMedium),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              // Mismo acento que la rutina tiene en la pestaña RUTINAS.
              final accent = RoutineColor.accentFor(context, routine.name);
              return AppCard(
                margin: const EdgeInsets.only(bottom: Spacing.md),
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(Radii.md),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.lgPlus,
                    vertical: Spacing.md,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(Spacing.sm),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: accent,
                    ),
                  ),
                  title: Text(routine.name, style: context.text.bodyLarge),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Estadísticas de la rutina',
                        icon: Icon(
                          Icons.analytics_rounded,
                          color: context.colors.primary,
                          size: 20,
                        ),
                        onPressed: () => onOpenRoutineStats(routine),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.colors.textSecondary,
                      ),
                    ],
                  ),
                  onTap: () => onSelectRoutine(routine),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
