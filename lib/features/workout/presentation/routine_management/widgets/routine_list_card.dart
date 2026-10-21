import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/utils/routine_color.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_card_actions.dart';

/// Card de rutina en el listado:
/// - Avatar con la inicial sobre el acento de la rutina (identidad visual).
/// - Nombre y una línea de metadatos (ejercicios · autor · pública).
/// - Footer: "Rutina activa" o las acciones (ACTIVAR / CREAR MI COPIA).
/// Tocar la card abre el editor (o la vista previa si es ajena).
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

  /// Callback al volver del editor (haya o no cambios).
  final VoidCallback? onEdited;

  /// Disparado al tocar "CREAR MI COPIA" para rutinas ajenas públicas.
  /// `null` cuando el botón no aplica (rutina propia o privada ajena).
  final ValueChanged<String>? onFork;

  Future<void> _openDetails(BuildContext context) async {
    unawaited(HapticFeedback.selectionClick());
    await pushRoutineEditor(context, routineId: routine.id);
    // Siempre: el editor guarda días/ejercicios al instante y volver con el
    // gesto del sistema no trae resultado.
    onEdited?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = RoutineColor.accentFor(context, routine.name);
    final radius = BorderRadius.circular(Radii.xl);

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: isActive ? accent : colors.divider.withValues(alpha: 0.6),
          width: isActive ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.lg,
            Spacing.sm,
            Spacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RoutineAvatar(name: routine.name, accent: accent),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: _Title(routine: routine, isMine: isMine),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Padding(
                padding: const EdgeInsets.only(right: Spacing.sm),
                child: RoutineCardActions(
                  isActive: isActive,
                  accent: accent,
                  onActivate: () => onActivate(routine.id),
                  onFork: onFork == null ? null : () => onFork!(routine.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cuadrado redondeado con la inicial de la rutina sobre su acento. Se
/// reutiliza en el editor para que la rutina se reconozca entre pantallas.
class RoutineAvatar extends StatelessWidget {
  const RoutineAvatar({
    super.key,
    required this.name,
    required this.accent,
    this.size = 44,
  });

  final String name;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty
        ? null
        : name.trim().characters.first.toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: RoutineColor.tint(context, accent),
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: initial == null
            ? Icon(Icons.fitness_center_rounded, color: accent, size: 20)
            : Text(
                initial,
                style: context.text.titleLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.42,
                  height: 1,
                ),
              ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.routine, required this.isMine});

  final Routine routine;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final count = routine.exerciseCount;
    final author = isMine
        ? 'Mi rutina'
        : (routine.creatorName?.isNotEmpty == true
              ? 'Por ${routine.creatorName}'
              : 'Comunidad');
    final meta = [
      count == 0
          ? 'Sin ejercicios'
          : '$count ${count == 1 ? 'ejercicio' : 'ejercicios'}',
      author,
      if (routine.isPublic && !isMine) 'Pública',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          routine.name,
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          meta,
          style: context.text.bodySmall?.copyWith(
            color: context.colors.textSecondary,
            fontSize: 13,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
