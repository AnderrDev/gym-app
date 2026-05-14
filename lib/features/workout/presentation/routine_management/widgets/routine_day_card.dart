import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/utils/routine_color.dart';

/// Card que representa un día dentro del editor de rutina.
///
/// Diseño "split-tile":
/// - Cuadro numerado prominente a la izquierda (color por índice).
/// - Nombre del día + contador de ejercicios + chevron.
/// - Swipe izquierdo borra (con confirmación) si `onDelete` está provisto.
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

  static const _dayLabels = ['LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB', 'DOM'];

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

  @override
  Widget build(BuildContext context) {
    final exerciseCount = day.exercises.length;
    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: Row(
              children: [
                _IndexTile(index: index, label: _dayShortLabel),
                const SizedBox(width: Spacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.name.toUpperCase(),
                        style: AppTextStyles.heading2.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exerciseCount == 0
                            ? 'Sin ejercicios · tocá para añadir'
                            : '$exerciseCount ${exerciseCount == 1 ? "ejercicio" : "ejercicios"}',
                        style: AppTextStyles.label.copyWith(
                          color: exerciseCount == 0
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      if (day.exerciseNamesPreview.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _buildPreview(day.exerciseNamesPreview),
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textDisabled,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textDisabled,
                ),
              ],
            ),
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
          color: AppColors.error.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        child: const Icon(
          Icons.delete_sweep_rounded,
          color: AppColors.onPrimary,
          size: 26,
        ),
      ),
      child: body,
    );
  }
}

class _IndexTile extends StatelessWidget {
  const _IndexTile({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = RoutineColor.byIndex(index);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${index + 1}',
            style: AppTextStyles.displayNumber.copyWith(
              fontSize: 20,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: color.withValues(alpha: 0.9),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
