import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/atoms/app_button.dart';
import 'package:gym_flutter/core/ui/feedback/app_dialog.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/utils/routine_color.dart';

/// Fila de ejercicio en el editor de un día.
///
/// - Tap → abre el sheet de edición de targets (`onTap`).
/// - Long-press → inicia el drag de reorder (lo consume `ReorderableDelayed
///   DragStartListener` del padre).
/// - Botón de basura visible (mouse + touch + accesibilidad) cuando hay
///   `onRemove`; pide confirmación antes de borrar.
/// - Swipe izquierdo mantiene el path de gesture para mobile.
class ExerciseRowCard extends StatelessWidget {
  const ExerciseRowCard({
    super.key,
    required this.exercise,
    required this.index,
    this.onRemove,
    this.onTap,
    this.onInfo,
  });

  final Exercise exercise;
  final int index;

  /// `null` cuando la card se renderiza en read-only (vista previa de rutina
  /// ajena). Sin remove implica también sin Dismissible.
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  /// Abre el detalle del ejercicio (media + instrucciones). `null` esconde el
  /// botón ⓘ — útil en pruebas o contextos sin nav.
  final VoidCallback? onInfo;

  static String _formatWeight(double w) {
    if (w == 0) return 'BW'; // bodyweight
    if (w == w.roundToDouble()) return '${w.toStringAsFixed(0)}kg';
    return '${w.toStringAsFixed(1)}kg';
  }

  static String _formatRest(int secs) {
    if (secs <= 0) return '—';
    if (secs < 60) return '${secs}s';
    final m = secs ~/ 60;
    final s = secs % 60;
    return s == 0 ? '${m}min' : '${m}m${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final accent = RoutineColor.byIndex(index);

    final body = Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: context.colors.divider.withValues(alpha: 0.4),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: context.text.displayLarge?.copyWith(
                        fontSize: 18,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name.toUpperCase(),
                          style: context.text.headlineMedium?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _StatTag(
                              icon: Icons.repeat_rounded,
                              label:
                                  '${exercise.targetSets}×${exercise.targetReps}',
                            ),
                            _StatTag(
                              icon: Icons.local_fire_department_rounded,
                              label: _formatWeight(exercise.targetWeight),
                            ),
                            _StatTag(
                              icon: Icons.timer_rounded,
                              label: _formatRest(exercise.restTimerSeconds),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  if (onInfo != null)
                    IconButton(
                      onPressed: onInfo,
                      icon: Icon(
                        Icons.info_outline_rounded,
                        color: context.colors.textSecondary,
                        size: 20,
                      ),
                      tooltip: 'Ver detalle del ejercicio',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  if (onRemove != null)
                    Builder(
                      builder: (ctx) => IconButton(
                        onPressed: () async {
                          final ok = await AppDialog.confirm(
                            ctx,
                            title: 'Quitar ejercicio',
                            message:
                                'Vas a quitar "${exercise.name}" del día. Podés volver a añadirlo desde el catálogo.',
                            confirmLabel: 'Quitar',
                            confirmVariant: AppButtonVariant.destructive,
                          );
                          if (ok == true) {
                            unawaited(HapticFeedback.heavyImpact());
                            onRemove!();
                          }
                        },
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: context.colors.error,
                          size: 20,
                        ),
                        tooltip: 'Quitar ejercicio',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ),
                  if (onRemove != null)
                    Icon(
                      Icons.drag_indicator_rounded,
                      color: context.colors.textDisabled,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
      );

    if (onRemove == null) return body;

    return Dismissible(
      key: ValueKey('dismiss_${exercise.id}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.heavyImpact();
        onRemove!();
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: Spacing.sm),
        decoration: BoxDecoration(
          color: context.colors.error.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        child: Icon(
          Icons.delete_sweep_rounded,
          color: context.colors.onPrimary,
          size: 26,
        ),
      ),
      child: body,
    );
  }
}

class _StatTag extends StatelessWidget {
  const _StatTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.divider.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: context.colors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.text.labelMedium?.copyWith(
              fontSize: 10.5,
              color: context.colors.textPrimary.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
