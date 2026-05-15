import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/durations.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_card.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_focus_parts.dart';

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
        FocusViewExerciseStepper(
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
                      FocusViewNextStepCta(
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
