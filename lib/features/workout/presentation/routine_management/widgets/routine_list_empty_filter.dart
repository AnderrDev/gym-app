import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_list_filter_chips.dart';

/// Estado vacío de la lista de rutinas, sensible al filtro activo
/// (todas / mías / comunidad).
class RoutineListEmptyFilter extends StatelessWidget {
  const RoutineListEmptyFilter({super.key, required this.filter});

  final RoutineListFilter filter;

  String get _title => switch (filter) {
        RoutineListFilter.all => 'Sin rutinas',
        RoutineListFilter.mine => 'No tenés rutinas propias',
        RoutineListFilter.community => 'Sin rutinas de la comunidad',
      };

  String get _subtitle => switch (filter) {
        RoutineListFilter.all =>
          'Creá una rutina propia o explorá el catálogo de la comunidad.',
        RoutineListFilter.mine =>
          'Creá tu primera rutina y armala día por día.',
        RoutineListFilter.community =>
          'Cuando otros usuarios compartan rutinas, aparecerán acá.',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            _title,
            style: AppTextStyles.heading2.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
