import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/durations.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_card.dart';

/// Vista "One Exercise Focus": un ejercicio ocupa la pantalla completa, swipe
/// horizontal entre ejercicios. El stepper superior muestra el progreso por
/// ejercicio y permite saltar tap-eando un dot.
///
/// Reutiliza la `ExerciseCard` existente para no duplicar la lógica de
/// timer/sets/save. Solo cambia el contenedor (PageView) y añade el stepper.
class RoutineDayActiveFocusView extends StatefulWidget {
  const RoutineDayActiveFocusView({
    super.key,
    required this.sessionId,
    required this.exercises,
    required this.completedLogs,
    required this.lastPerformances,
    required this.coachingAnalyses,
    required this.effectiveReadOnly,
    required this.onSetAdded,
    this.onSetRemoved,
    this.onFinishWorkout,
  });

  final String sessionId;
  final List<Exercise> exercises;
  final List<SetLog> completedLogs;
  final Map<String, SetLog?> lastPerformances;
  final Map<String, CoachingAnalysis?> coachingAnalyses;
  final bool effectiveReadOnly;
  final void Function(SetLog log) onSetAdded;
  final void Function(String exerciseId, int setIndex)? onSetRemoved;
  final VoidCallback? onFinishWorkout;

  @override
  State<RoutineDayActiveFocusView> createState() =>
      _RoutineDayActiveFocusViewState();
}

class _RoutineDayActiveFocusViewState extends State<RoutineDayActiveFocusView> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = _firstIncompleteIndex();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void didUpdateWidget(covariant RoutineDayActiveFocusView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el padre rebuilde con una lista de ejercicios distinta (p.ej. el
    // bloc emite una nueva sesión) y nuestro índice ya no es válido, lo
    // clampeamos antes del próximo build para evitar RangeError en
    // `_ExerciseStepper` (que indexa `exercises[currentIndex]`).
    final exCount = widget.exercises.length;
    if (exCount == 0) {
      _currentIndex = 0;
    } else if (_currentIndex >= exCount) {
      _currentIndex = exCount - 1;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _firstIncompleteIndex() {
    for (var i = 0; i < widget.exercises.length; i++) {
      final ex = widget.exercises[i];
      final done = _doneCountFor(ex);
      if (done < ex.targetSets) return i;
    }
    return widget.exercises.isEmpty ? 0 : widget.exercises.length - 1;
  }

  int _doneCountFor(Exercise ex) =>
      widget.completedLogs.where((l) => l.exerciseId == ex.id).length;

  void _jumpTo(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      index,
      duration: AppDurations.medium,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Spacing.xl),
          child: Text(
            'No hay ejercicios para esta sesión',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return Column(
      children: [
        _ExerciseStepper(
          exercises: widget.exercises,
          completedLogs: widget.completedLogs,
          currentIndex: _currentIndex,
          onTap: _jumpTo,
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.exercises.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = i);
            },
            itemBuilder: (context, index) {
              final ex = widget.exercises[index];
              final allSetsDone = _doneCountFor(ex) >= ex.targetSets;
              final isLast = index == widget.exercises.length - 1;
              final nextEx = isLast ? null : widget.exercises[index + 1];
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.md,
                  Spacing.lg,
                  Spacing.lg,
                ),
                child: Column(
                  children: [
                    ExerciseCard(
                      key: ValueKey('exercise-card-${ex.id}'),
                      exercise: ex,
                      sessionId: widget.sessionId,
                      initialCompletedSets: widget.completedLogs,
                      lastPerformance: widget.lastPerformances[ex.id],
                      readOnly: widget.effectiveReadOnly,
                      coachingAnalysis: widget.coachingAnalyses[ex.id],
                      forceExpanded: !widget.effectiveReadOnly,
                      onSetAdded: widget.effectiveReadOnly
                          ? null
                          : widget.onSetAdded,
                      onSetRemoved: widget.effectiveReadOnly
                          ? null
                          : (idx) => widget.onSetRemoved?.call(ex.id, idx),
                    ),
                    if (allSetsDone && !widget.effectiveReadOnly) ...[
                      const SizedBox(height: Spacing.md),
                      _NextStepCta(
                        nextExerciseName: nextEx?.name,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          if (nextEx != null) {
                            _jumpTo(index + 1);
                          } else if (widget.onFinishWorkout != null) {
                            widget.onFinishWorkout!();
                          }
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ExerciseStepper extends StatelessWidget {
  const _ExerciseStepper({
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
    // rango aborta el frame entero y, en iOS device real, puede tirar la
    // app. Mejor un stepper vacío que un crash.
    if (exercises.isEmpty || currentIndex < 0 || currentIndex >= exercises.length) {
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
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
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
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                '${currentIndex + 1}/${exercises.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
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
      _DotState.completed => AppColors.primary,
      _DotState.inProgress => AppColors.primary.withValues(alpha: 0.4),
      _DotState.pending => Colors.transparent,
    };
    final border = isCurrent ? AppColors.primary : AppColors.divider;
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

class _NextStepCta extends StatelessWidget {
  const _NextStepCta({required this.nextExerciseName, required this.onTap});

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
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            Icon(
              isLast
                  ? Icons.flag_rounded
                  : Icons.arrow_forward_rounded,
              color: AppColors.onPrimary,
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
                      color: AppColors.onPrimary.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    isLast
                        ? 'Finalizar entrenamiento'
                        : nextExerciseName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
