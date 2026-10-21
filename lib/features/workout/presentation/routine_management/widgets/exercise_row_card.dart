import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/atoms/app_button.dart';
import 'package:gym_flutter/core/ui/feedback/app_dialog.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/weight_format.dart';

/// Fila de ejercicio en el editor de un día.
///
/// - Tap → abre el sheet de edición de targets (`onTap`).
/// - Long-press → inicia el drag de reorder (lo consume `ReorderableDelayed
///   DragStartListener` del padre); el asa arrastra al instante.
/// - "Más opciones" agrupa ver detalle y quitar (con confirmación); en
///   read-only queda solo el botón ⓘ.
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

  /// Abre el detalle del ejercicio (media + instrucciones). `null` esconde la
  /// opción — útil en pruebas o contextos sin nav.
  final VoidCallback? onInfo;

  /// "45 s", "2 min", "1:30"; `null` sin descanso.
  static String? _formatRest(int secs) {
    if (secs <= 0) return null;
    if (secs < 60) return '$secs s';
    final m = secs ~/ 60;
    final s = secs % 60;
    return s == 0 ? '$m min' : '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Series × reps y carga: "3 × 10 · 60 kg".
  String get _prescription =>
      '${exercise.targetSets} × ${exercise.targetReps} · '
      '${formatLoad(exercise.targetWeight)}';

  Future<bool> _confirmRemove(BuildContext context) async {
    final ok = await AppDialog.confirm(
      context,
      title: 'Quitar ejercicio',
      message:
          'Vas a quitar "${exercise.name}" del día. Puedes volver a añadirlo desde el catálogo.',
      confirmLabel: 'Quitar',
      confirmVariant: AppButtonVariant.destructive,
    );
    return ok == true;
  }

  Future<void> _remove(BuildContext context) async {
    if (await _confirmRemove(context)) {
      unawaited(HapticFeedback.heavyImpact());
      onRemove!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final editable = onRemove != null;

    final body = Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: colors.divider.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.md,
              editable ? 0 : Spacing.xs,
              Spacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: context.text.labelLarge?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      _PrescriptionLine(
                        prescription: _prescription,
                        rest: _formatRest(exercise.restTimerSeconds),
                      ),
                    ],
                  ),
                ),
                if (!editable && onInfo != null)
                  IconButton(
                    onPressed: onInfo,
                    icon: Icon(
                      Icons.info_outline_rounded,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                    tooltip: 'Ver detalle del ejercicio',
                  ),
                if (editable) ...[
                  Builder(
                    builder: (ctx) => PopupMenuButton<_RowAction>(
                      tooltip: 'Más opciones',
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: colors.textSecondary,
                      ),
                      onSelected: (action) => switch (action) {
                        _RowAction.info => onInfo?.call(),
                        _RowAction.remove => _remove(ctx),
                      },
                      itemBuilder: (context) => [
                        if (onInfo != null)
                          const PopupMenuItem(
                            value: _RowAction.info,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.info_outline_rounded),
                              title: Text('Ver detalle'),
                            ),
                          ),
                        PopupMenuItem(
                          value: _RowAction.remove,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.delete_outline_rounded,
                              color: colors.error,
                            ),
                            title: Text(
                              'Quitar ejercicio',
                              style: TextStyle(color: colors.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrastre inmediato desde el asa; mantener pulsada la
                  // tarjeta sigue funcionando.
                  ReorderableDragStartListener(
                    index: index,
                    child: Semantics(
                      label: 'Arrastrar para reordenar',
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Spacing.xs,
                          Spacing.md,
                          Spacing.md,
                          Spacing.md,
                        ),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: colors.textSecondary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
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
      // Mismo diálogo que "Quitar ejercicio": un swipe accidental no borra.
      confirmDismiss: (_) => _confirmRemove(context),
      onDismissed: (_) {
        HapticFeedback.heavyImpact();
        onRemove!();
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: Spacing.sm),
        decoration: BoxDecoration(
          color: context.colors.error.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        child: Icon(
          Icons.delete_sweep_rounded,
          color: context.colors.onError,
          size: 26,
        ),
      ),
      child: body,
    );
  }
}

enum _RowAction { info, remove }

/// "3 × 10 · 60 kg  ⏱ 1:30" en una línea; el lector de pantalla oye
/// "… · descanso 1:30".
class _PrescriptionLine extends StatelessWidget {
  const _PrescriptionLine({required this.prescription, required this.rest});

  final String prescription;
  final String? rest;

  @override
  Widget build(BuildContext context) {
    final style = context.text.bodySmall?.copyWith(
      color: context.colors.textSecondary,
      fontSize: 13,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Text.rich(
      TextSpan(
        text: prescription,
        children: [
          if (rest != null) ...[
            const TextSpan(text: '   '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                Icons.timer_outlined,
                size: 14,
                color: context.colors.textSecondary,
              ),
            ),
            TextSpan(text: ' $rest'),
          ],
        ],
      ),
      semanticsLabel: rest == null
          ? prescription
          : '$prescription · descanso $rest',
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
