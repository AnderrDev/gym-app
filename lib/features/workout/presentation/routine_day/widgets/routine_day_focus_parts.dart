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
    // El nombre del ejercicio ya encabeza la tarjeta: aquí sólo posición y
    // qué viene después.
    final next = currentIndex + 1 < exercises.length
        ? exercises[currentIndex + 1]
        : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.lg, 0),
      decoration: BoxDecoration(
        color: context.colors.background,
        border: Border(bottom: BorderSide(color: context.colors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Ejercicio ${currentIndex + 1} de ${exercises.length}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (next != null) ...[
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    'Siguiente: ${next.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < exercises.length; i++) ...[
                  _StepperDot(
                    state: _stateFor(exercises[i]),
                    isCurrent: i == currentIndex,
                    onTap: () => onTap(i),
                    semanticLabel:
                        'Ejercicio ${i + 1} de ${exercises.length}: '
                        '${exercises[i].name}',
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
    required this.semanticLabel,
  });

  final String semanticLabel;

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
    // El punto mide 8 px de alto; el área táctil se amplía con padding para
    // poder pulsarlo, y se anuncia como botón a los lectores de pantalla.
    return Semantics(
      button: true,
      selected: isCurrent,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 2),
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
