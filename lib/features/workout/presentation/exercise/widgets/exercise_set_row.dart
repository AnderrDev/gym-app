import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_set_row_parts.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_set_row_readonly.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/weight_format.dart';

/// Fila de una serie en la sesión activa. Muestra el objetivo mientras está
/// pendiente y lo registrado (con la diferencia vs objetivo) cuando se
/// completa. El registro ocurre en `CompleteSetSheet`: tocar la fila abre el
/// modal para esa serie (completar, editar o desmarcar).
class ExerciseSetRow extends StatelessWidget {
  const ExerciseSetRow({
    super.key,
    required this.setNumber,
    required this.targetReps,
    required this.targetWeight,
    required this.completedLog,
    required this.readOnly,
    this.isNext = false,
    this.onTap,
  });

  final int setNumber;
  final int targetReps;
  final double targetWeight;
  final SetLog? completedLog;
  final bool readOnly;

  /// Primera serie pendiente — se resalta como "la que sigue".
  final bool isNext;
  final VoidCallback? onTap;

  bool get isDone => completedLog != null;

  @override
  Widget build(BuildContext context) {
    if (readOnly) {
      return ExerciseSetRowReadOnly(
        setNumber: setNumber,
        isDone: isDone,
        completedLog: completedLog,
      );
    }
    final colors = context.colors;
    final log = completedLog;
    final borderColor = isDone
        ? colors.success.withValues(alpha: 0.35)
        : isNext
        ? colors.primary.withValues(alpha: 0.6)
        : colors.divider;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Material(
        color: isDone
            ? colors.success.withValues(alpha: 0.06)
            : colors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: isNext ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                SetCircle(label: '$setNumber', filled: isDone, active: isNext),
                const SizedBox(width: 12),
                Expanded(
                  child: log == null
                      ? _PendingLabel(
                          targetWeight: targetWeight,
                          targetReps: targetReps,
                          isNext: isNext,
                        )
                      : _DoneLabel(
                          log: log,
                          targetWeight: targetWeight,
                          targetReps: targetReps,
                        ),
                ),
                Icon(
                  isDone ? Icons.check_circle_rounded : Icons.chevron_right,
                  color: isDone ? colors.success : colors.textSecondary,
                  size: isDone ? 20 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingLabel extends StatelessWidget {
  const _PendingLabel({
    required this.targetWeight,
    required this.targetReps,
    required this.isNext,
  });

  final double targetWeight;
  final int targetReps;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Text(
          'Objetivo',
          style: context.text.labelMedium?.copyWith(
            color: isNext ? colors.primary : colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Flexible(
          child: Text(
            '${formatWeight(targetWeight)} kg × $targetReps reps',
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(
              color: isNext ? colors.textPrimary : colors.textSecondary,
              fontWeight: isNext ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _DoneLabel extends StatelessWidget {
  const _DoneLabel({
    required this.log,
    required this.targetWeight,
    required this.targetReps,
  });

  final SetLog log;
  final double targetWeight;
  final int targetReps;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final weightDelta = targetWeight > 0 ? log.actualWeight - targetWeight : 0;
    final repsDelta = log.actualReps - targetReps;
    final chips = <Widget>[
      if (weightDelta.abs() >= 0.01)
        _DeltaChip(
          label: weightDelta > 0
              ? '+${formatWeight(weightDelta.toDouble())} kg'
              : '-${formatWeight(-weightDelta.toDouble())} kg',
          positive: weightDelta > 0,
        ),
      if (repsDelta != 0)
        _DeltaChip(
          label: repsDelta > 0 ? '+$repsDelta reps' : '$repsDelta reps',
          positive: repsDelta > 0,
        ),
    ];
    return Row(
      children: [
        Flexible(
          child: Text(
            '${formatWeight(log.actualWeight)} kg × ${log.actualReps} reps',
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final chip in chips) ...[const SizedBox(width: 6), chip],
      ],
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.label, required this.positive});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? context.colors.success : context.colors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
