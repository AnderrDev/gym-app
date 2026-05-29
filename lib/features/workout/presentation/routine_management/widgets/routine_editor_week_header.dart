import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/section_header.dart';

class RoutineEditorWeekHeader extends StatelessWidget {
  const RoutineEditorWeekHeader({super.key, required this.dayCount});

  final int dayCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lgPlus,
        Spacing.sm,
        Spacing.lgPlus,
        Spacing.md,
      ),
      child: SectionHeader(
        label: 'Estructura semanal',
        trailing: Text(
          '$dayCount ${dayCount == 1 ? "DÍA" : "DÍAS"}',
          style: context.text.labelMedium?.copyWith(
            color: context.colors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
