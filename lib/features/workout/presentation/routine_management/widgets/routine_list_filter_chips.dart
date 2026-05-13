import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
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
          _chip(RoutineListFilter.all, 'TODAS'),
          const SizedBox(width: 8),
          _chip(RoutineListFilter.mine, 'MIS RUTINAS'),
          const SizedBox(width: 8),
          _chip(RoutineListFilter.community, 'COMUNIDAD'),
        ],
      ),
    );
  }

  Widget _chip(RoutineListFilter type, String label) {
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
          color: isSelected ? AppColors.primary : AppColors.glassFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
