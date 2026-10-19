import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

enum RoutineListFilter { all, mine, community }

/// Strip horizontal de filtros para el listado de rutinas (TODAS / MIS
/// RUTINAS / COMUNIDAD).
class RoutineListFilterChips extends StatelessWidget {
  const RoutineListFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final RoutineListFilter selected;
  final ValueChanged<RoutineListFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(context, RoutineListFilter.all, 'TODAS'),
          const SizedBox(width: 8),
          _chip(context, RoutineListFilter.mine, 'MIS RUTINAS'),
          const SizedBox(width: 8),
          _chip(context, RoutineListFilter.community, 'COMUNIDAD'),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, RoutineListFilter type, String label) {
    final colors = context.colors;
    final isSelected = selected == type;
    return InkWell(
      onTap: () => onChanged(type),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.glassFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.primary : colors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: context.text.labelMedium?.copyWith(
            color: isSelected ? colors.onPrimary : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
