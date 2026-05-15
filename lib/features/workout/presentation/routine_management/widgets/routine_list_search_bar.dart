import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Buscador de rutinas por nombre. Renderiza el frame con borde + un
/// `TextField` interno; el clear chip aparece solo cuando hay query.
class RoutineListSearchBar extends StatelessWidget {
  const RoutineListSearchBar({
    super.key,
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Vertical 0/0 — los containers vecinos (summary header arriba, filtros
      // abajo) aportan su propio padding. Evita acumular separaciones.
      padding: const EdgeInsets.fromLTRB(
        Spacing.lgPlus,
        0,
        Spacing.lgPlus,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.textDisabled,
              size: 20,
            ),
            hintText: 'Buscar rutina por nombre…',
            hintStyle:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
            border: InputBorder.none,
            isDense: true,
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textDisabled,
                    ),
                    onPressed: onClear,
                  ),
          ),
        ),
      ),
    );
  }
}
