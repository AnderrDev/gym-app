import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_card_coaching.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_set_row.dart';

class ExerciseCardBody extends StatelessWidget {
  final bool isExpanded;
  final int targetSets;
  final Exercise exercise;
  final String sessionId;
  final Map<int, SetLog> completedSets;
  final SetLog? lastPerformance;
  final bool readOnly;
  final CoachingAnalysis? coachingAnalysis;
  final void Function(SetLog log, int setIndex) onSaveSet;
  final void Function(int setIndex)? onUnsaveSet;
  final String Function(String) recommendationText;

  const ExerciseCardBody({
    super.key,
    required this.isExpanded,
    required this.targetSets,
    required this.exercise,
    required this.sessionId,
    required this.completedSets,
    required this.lastPerformance,
    required this.readOnly,
    required this.coachingAnalysis,
    required this.onSaveSet,
    required this.recommendationText,
    this.onUnsaveSet,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.fastOutSlowIn,
      alignment: Alignment.topCenter,
      child: !isExpanded
          ? const SizedBox(width: double.infinity, height: 0)
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                0,
                Spacing.lg,
                Spacing.lg,
              ),
              child: Column(
                children: [
                  const Divider(height: 1, color: AppColors.divider),
                  if (coachingAnalysis?.hasActionableAdvice ?? false) ...[
                    const SizedBox(height: 12),
                    ExerciseCardCoachingAdvice(
                      coaching: coachingAnalysis!,
                      compact: false,
                      recommendationText: recommendationText,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Column(
                    key: const ValueKey('sets_list'),
                    children: List.generate(targetSets, (i) {
                      final n = i + 1;
                      return ExerciseSetRow(
                        key: ValueKey('set_${exercise.id}_$n'),
                        setNumber: n,
                        targetReps: exercise.targetReps,
                        targetWeight: exercise.targetWeight,
                        isDone: completedSets.containsKey(n),
                        completedLog: completedSets[n],
                        lastPerformanceLog: lastPerformance,
                        sessionId: sessionId,
                        exerciseId: exercise.id,
                        readOnly: readOnly,
                        onSaved: readOnly
                            ? (_) {}
                            : (log) => onSaveSet(log, n),
                        onUnsaved: readOnly ? null : onUnsaveSet,
                      );
                    }),
                  ),
                ],
              ),
            ),
    );
  }
}
