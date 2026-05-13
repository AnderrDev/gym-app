import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/presentation/widgets/glass_container.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';

/// Card de rutina en el listado/catálogo. Muestra nombre, badges y CTA
/// "ACTIVAR". Tap en "DETALLES" abre el editor.
class RoutineListCard extends StatelessWidget {
  const RoutineListCard({
    super.key,
    required this.routine,
    required this.isActive,
    required this.isMine,
    required this.onActivate,
    this.onEdited,
  });

  final Routine routine;
  final bool isActive;
  final bool isMine;
  final ValueChanged<String> onActivate;

  /// Se invoca cuando el editor de rutina pop-ea con cambios (`true`), para
  /// que el contenedor pueda refrescar el catálogo.
  final VoidCallback? onEdited;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(Spacing.xl),
      borderRadius: BorderRadius.circular(28),
      borderOpacity: isActive ? 0.4 : 0.1,
      borderColor: isActive ? AppColors.primary : AppColors.divider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  routine.name.toUpperCase(),
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ACTIVA',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.xl),
          Row(
            children: [
              _RoutineInfoTag(
                icon: Icons.fitness_center_rounded,
                label: '${routine.exerciseCount} EJERCICIOS',
              ),
              const SizedBox(width: Spacing.md),
              Flexible(
                child: _RoutineInfoTag(
                  icon: isMine ? Icons.person_rounded : Icons.public_rounded,
                  label: isMine
                      ? 'MI RUTINA'
                      : (routine.creatorName ?? 'COMUNIDAD'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () async {
                  unawaited(HapticFeedback.selectionClick());
                  final changed = await pushRoutineEditor(
                    context,
                    routineId: routine.id,
                  );
                  if (changed == true) onEdited?.call();
                },
                child: Text(
                  'DETALLES',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => onActivate(routine.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.lgPlus,
                    vertical: Spacing.sm,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'ACTIVAR',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutineInfoTag extends StatelessWidget {
  const _RoutineInfoTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary.withValues(alpha: 0.7), size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
