import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_set_row_focus_parts.dart';

/// Variante stateless de la fila de serie: solo lectura para historial.
/// Sin inputs, sin botón ✓, sin chips — solo el círculo + texto resumido.
class ExerciseSetRowReadOnly extends StatelessWidget {
  const ExerciseSetRowReadOnly({
    super.key,
    required this.setNumber,
    required this.isDone,
    required this.completedLog,
  });

  final int setNumber;
  final bool isDone;
  final SetLog? completedLog;

  static String _formatWeight(double w) =>
      w % 1 == 0 ? w.toStringAsFixed(0) : w.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final log = completedLog;
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDone
            ? context.colors.success.withValues(alpha: 0.08)
            : context.colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone
              ? context.colors.success.withValues(alpha: 0.3)
              : context.colors.divider,
        ),
      ),
      child: Row(
        children: [
          SetCircle(label: '$setNumber', filled: isDone),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              log != null
                  ? '${_formatWeight(log.actualWeight)} kg × ${log.actualReps} reps'
                  : '— sin registro —',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                color: isDone
                    ? context.colors.textPrimary
                    : context.colors.textSecondary,
              ),
            ),
          ),
          if (isDone)
            Icon(
              Icons.check_circle_rounded,
              color: context.colors.success,
              size: 18,
            ),
        ],
      ),
    );
  }
}
