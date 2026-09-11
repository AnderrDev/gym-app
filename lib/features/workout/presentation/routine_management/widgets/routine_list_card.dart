import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/utils/routine_color.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_card_actions.dart';

/// Card de rutina en el listado. Diseño "split":
/// - Banda lateral de color (hash del nombre) como identidad visual.
/// - Bloque central con nombre, stats y atribución.
/// - Footer con CTA secundaria (DETALLES) y CTA primaria contextual
///   (ACTIVAR / ACTIVA según `isActive`).
class RoutineListCard extends StatelessWidget {
  const RoutineListCard({
    super.key,
    required this.routine,
    required this.isActive,
    required this.isMine,
    required this.onActivate,
    this.onEdited,
    this.onFork,
  });

  final Routine routine;
  final bool isActive;
  final bool isMine;
  final ValueChanged<String> onActivate;

  /// Callback cuando el editor pop-ea con cambios.
  final VoidCallback? onEdited;

  /// Disparado al tocar "CREAR MI COPIA" para rutinas ajenas públicas.
  /// `null` cuando el botón no aplica (rutina propia o privada ajena).
  final ValueChanged<String>? onFork;

  Future<void> _openDetails(BuildContext context) async {
    unawaited(HapticFeedback.selectionClick());
    final changed = await pushRoutineEditor(context, routineId: routine.id);
    if (changed == true) onEdited?.call();
  }

  @override
  Widget build(BuildContext context) {
    final accent = RoutineColor.accentFor(routine.name);
    final borderColor = isActive
        ? accent.withValues(alpha: 0.6)
        : context.colors.divider.withValues(alpha: 0.4);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetails(context),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: isActive ? 1.6 : 1),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banda de identidad
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.lgPlus,
                      Spacing.lg,
                      Spacing.lgPlus,
                      Spacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          name: routine.name,
                          isActive: isActive,
                          accent: accent,
                        ),
                        const SizedBox(height: Spacing.md),
                        _StatsRow(
                          routine: routine,
                          isMine: isMine,
                          accent: accent,
                        ),
                        const SizedBox(height: Spacing.md),
                        RoutineCardActions(
                          isActive: isActive,
                          accent: accent,
                          onActivate: () => onActivate(routine.id),
                          onFork: onFork == null
                              ? null
                              : () => onFork!(routine.id),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.isActive,
    required this.accent,
  });

  final String name;
  final bool isActive;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            name.toUpperCase(),
            style: context.text.headlineMedium?.copyWith(
              fontSize: 16,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(left: Spacing.sm),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ACTIVA',
              style: context.text.labelMedium?.copyWith(
                color: context.colors.background,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.routine,
    required this.isMine,
    required this.accent,
  });

  final Routine routine;
  final bool isMine;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final author = isMine
        ? 'Mi rutina'
        : (routine.creatorName?.isNotEmpty == true
              ? routine.creatorName!
              : 'Comunidad');
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.xs,
      children: [
        _StatChip(
          icon: Icons.local_fire_department_rounded,
          label: '${routine.exerciseCount} ejercicios',
          accent: accent,
        ),
        _StatChip(
          icon: isMine ? Icons.person_rounded : Icons.public_rounded,
          label: author,
          accent: accent,
        ),
        if (routine.isPublic && !isMine)
          _StatChip(
            icon: Icons.share_rounded,
            label: 'Pública',
            accent: accent,
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: context.text.labelMedium?.copyWith(
              color: context.colors.textPrimary.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
