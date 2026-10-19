import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
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
      padding: const EdgeInsets.fromLTRB(Spacing.lgPlus, 0, Spacing.lgPlus, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.colors.divider.withValues(alpha: 0.5),
          ),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.textPrimary,
          ),
          decoration: InputDecoration(
            icon: Icon(
              Icons.search_rounded,
              color: context.colors.textDisabled,
              size: 20,
            ),
            hintText: 'Buscar rutina por nombre…',
            hintStyle: context.text.bodyMedium?.copyWith(
              color: context.colors.textDisabled,
            ),
            border: InputBorder.none,
            isDense: true,
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: context.colors.textDisabled,
                    ),
                    onPressed: onClear,
                  ),
          ),
        ),
      ),
    );
  }
}
