import 'package:flutter/material.dart';

import 'package:gym_flutter/core/ui/molecules/app_empty_state.dart';

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    required this.onExploreCatalog,
    required this.onCreateRoutine,
  });

  final VoidCallback onExploreCatalog;
  final VoidCallback onCreateRoutine;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.explore_off_rounded,
      title: 'Sin rutina activa',
      subtitle:
          'Para empezar a entrenar, elige una rutina del catálogo o crea la tuya.',
      primaryActionLabel: 'Explorar catálogo',
      onPrimaryAction: onExploreCatalog,
      secondaryActionLabel: 'Crear mi rutina',
      onSecondaryAction: onCreateRoutine,
    );
  }
}
