import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

enum RoutineListFilter { all, mine, community }

/// Strip horizontal de filtros para el listado de rutinas (Todas / Mías /
/// Comunidad). Alto 40 + padding del hit-test de Material = objetivo ≥ 48.
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
          _chip(context, RoutineListFilter.all, 'Todas'),
          const SizedBox(width: Spacing.sm),
          _chip(context, RoutineListFilter.mine, 'Mías'),
          const SizedBox(width: Spacing.sm),
          _chip(context, RoutineListFilter.community, 'Comunidad'),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, RoutineListFilter type, String label) {
    final colors = context.colors;
    final isSelected = selected == type;
    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected ? colors.textPrimary : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
          side: BorderSide(
            color: isSelected ? colors.textPrimary : colors.divider,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onChanged(type),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Text(
              label,
              style: context.text.labelLarge?.copyWith(
                color: isSelected ? colors.background : colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
