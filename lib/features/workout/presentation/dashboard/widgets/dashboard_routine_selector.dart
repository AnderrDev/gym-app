import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
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
          child: Text('Mis Rutinas', style: AppTextStyles.heading2),
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
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(routine.name, style: AppTextStyles.bodyLarge),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.analytics_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          onPressed: () => onOpenRoutineStats(routine),
                        ),
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.primary,
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
