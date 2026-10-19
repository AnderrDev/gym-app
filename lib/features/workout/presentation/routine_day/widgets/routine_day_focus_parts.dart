import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/durations.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';

/// Stepper horizontal arriba de la vista focus, con el ejercicio activo
/// destacado. Permite saltar entre ejercicios con tap.
class FocusViewExerciseStepper extends StatelessWidget {
  const FocusViewExerciseStepper({
    super.key,
    required this.exercises,
    required this.completedLogs,
    required this.currentIndex,
    required this.onTap,
  });

  final List<Exercise> exercises;
  final List<SetLog> completedLogs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Guard defensivo: si el padre rebuildea con menos ejercicios mientras
    // el stepper aún está pintado con el índice viejo, indexar fuera de
    // rango aborta el frame entero.
    if (exercises.isEmpty ||
        currentIndex < 0 ||
        currentIndex >= exercises.length) {
      return const SizedBox.shrink();
    }
    final current = exercises[currentIndex];
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.md,
      ),
      decoration: BoxDecoration(
        color: context.colors.background,
        border: Border(bottom: BorderSide(color: context.colors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  current.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                '${currentIndex + 1}/${exercises.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < exercises.length; i++) ...[
                  _StepperDot(
                    state: _stateFor(exercises[i]),
                    isCurrent: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                  if (i < exercises.length - 1)
                    const SizedBox(width: Spacing.xs),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _DotState _stateFor(Exercise ex) {
    final done = completedLogs.where((l) => l.exerciseId == ex.id).length;
    if (done == 0) return _DotState.pending;
    if (done >= ex.targetSets) return _DotState.completed;
    return _DotState.inProgress;
  }
}

enum _DotState { pending, inProgress, completed }

class _StepperDot extends StatelessWidget {
  const _StepperDot({
    required this.state,
    required this.isCurrent,
    required this.onTap,
  });

  final _DotState state;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = switch (state) {
      _DotState.completed => context.colors.primary,
      _DotState.inProgress => context.colors.primary.withValues(alpha: 0.4),
      _DotState.pending => Colors.transparent,
    };
    final border = isCurrent ? context.colors.primary : context.colors.divider;
    final width = isCurrent ? 28.0 : 18.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.pill),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        width: width,
        height: 8,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: border, width: 1.5),
        ),
      ),
    );
  }
}

/// CTA inferior que avanza al próximo ejercicio (o finaliza si es el último).
class FocusViewNextStepCta extends StatelessWidget {
  const FocusViewNextStepCta({
    super.key,
    required this.nextExerciseName,
    required this.onTap,
  });

  final String? nextExerciseName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = nextExerciseName == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        decoration: BoxDecoration(
          color: context.colors.primary,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            Icon(
              isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded,
              color: context.colors.onPrimary,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLast ? 'TERMINASTE' : 'SIGUIENTE EJERCICIO',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: context.colors.onPrimary.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    isLast ? 'Finalizar entrenamiento' : nextExerciseName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: context.colors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.colors.onPrimary),
          ],
        ),
      ),
    );
  }
}
