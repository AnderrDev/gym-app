import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/utils/routine_color.dart';

/// Card que representa un día dentro del editor de rutina.
///
/// - Cuadro con el día de la semana (LUN…DOM): es el dato que ordena la
///   lista, así que va primero y en grande.
/// - Nombre del día + ejercicios y preview de nombres + chevron.
/// - Borrar va en el menú "Más opciones" (mouse, touch y lector de
///   pantalla) en lugar de una papelera roja por fila; el swipe izquierdo se
///   mantiene como atajo en mobile.
class RoutineDayCard extends StatelessWidget {
  const RoutineDayCard({
    super.key,
    required this.index,
    required this.day,
    required this.onTap,
    this.onDelete,
    this.confirmDelete,
  });

  final int index;
  final RoutineDay day;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final Future<bool> Function()? confirmDelete;

  static const _dayLabels = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];

  String get _dayShortLabel {
    final dow = day.dayOfWeek;
    if (dow >= 1 && dow <= 7) return _dayLabels[dow - 1];
    return 'D${index + 1}';
  }

  /// Preview compacto: primeros 3 nombres separados por `·` y "+N" cuando hay
  /// más. Pensado para una sola línea con ellipsis si igual no entra.
  static String _buildPreview(List<String> names) {
    if (names.length <= 3) return names.join(' · ');
    return '${names.take(3).join(' · ')} · +${names.length - 3}';
  }

  Future<void> _delete() async {
    final ok = (await confirmDelete?.call()) ?? true;
    if (!ok) return;
    unawaited(HapticFeedback.heavyImpact());
    onDelete!();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exerciseCount = day.exercises.length;
    final card = Material(
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
            onDelete == null ? Spacing.sm : 0,
            Spacing.md,
          ),
          child: Row(
            children: [
              _WeekdayTile(label: _dayShortLabel),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.name,
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exerciseCount == 0
                          ? 'Sin ejercicios · toca para añadir'
                          : day.exerciseNamesPreview.isNotEmpty
                          ? _buildPreview(day.exerciseNamesPreview)
                          : '$exerciseCount ${exerciseCount == 1 ? "ejercicio" : "ejercicios"}',
                      style: context.text.bodySmall?.copyWith(
                        color: exerciseCount == 0
                            ? colors.primary
                            : colors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (exerciseCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: Spacing.sm),
                  child: Text(
                    '$exerciseCount',
                    semanticsLabel:
                        '$exerciseCount ${exerciseCount == 1 ? "ejercicio" : "ejercicios"}',
                    style: context.text.titleMedium?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              if (onDelete != null)
                PopupMenuButton<bool>(
                  tooltip: 'Más opciones',
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colors.textSecondary,
                  ),
                  onSelected: (_) => _delete(),
                  itemBuilder: (context) => [
                    // Un `value` null cuenta como cancelar y no llega a
                    // `onSelected`.
                    PopupMenuItem<bool>(
                      value: true,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.delete_outline_rounded,
                          color: colors.error,
                        ),
                        title: Text(
                          'Eliminar día',
                          style: TextStyle(color: colors.error),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );

    final body = Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: card,
    );

    if (onDelete == null) return body;

    return Dismissible(
      key: ValueKey('day_${day.id}_$index'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final ok = (await confirmDelete?.call()) ?? true;
        if (ok) unawaited(HapticFeedback.heavyImpact());
        return ok;
      },
      onDismissed: (_) => onDelete!(),
      background: Container(
        margin: const EdgeInsets.only(bottom: Spacing.md),
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

class _WeekdayTile extends StatelessWidget {
  const _WeekdayTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: RoutineColor.tint(context, context.colors.primary),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: context.text.labelLarge?.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
