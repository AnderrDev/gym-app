import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/presentation/widgets/glass_container.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';

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
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacing.md),
                child: GlassContainer(
                  opacity: 0.1,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(Spacing.sm),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: context.colors.primary,
                      ),
                    ),
                    title: Text(routine.name, style: context.text.bodyLarge),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.analytics_rounded,
                            color: context.colors.primary,
                            size: 20,
                          ),
                          onPressed: () => onOpenRoutineStats(routine),
                        ),
                        Icon(
                          Icons.calendar_month_rounded,
                          color: context.colors.primary,
                        ),
                      ],
                    ),
                    onTap: () => onSelectRoutine(routine),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
