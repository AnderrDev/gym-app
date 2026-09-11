import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/ui/atoms/app_button.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_card_coaching.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_set_row.dart';

class ExerciseCardBody extends StatelessWidget {
  final bool isExpanded;
  final int targetSets;
  final Exercise exercise;
  final Map<int, SetLog> completedSets;
  final bool readOnly;
  final CoachingAnalysis? coachingAnalysis;
  final String Function(String) recommendationText;

  /// Primera serie sin completar, o `null` si ya están todas.
  final int? nextPendingSet;

  /// Abre el modal de la serie indicada. `null` en modo solo lectura.
  final void Function(int setNumber)? onOpenSet;

  const ExerciseCardBody({
    super.key,
    required this.isExpanded,
    required this.targetSets,
    required this.exercise,
    required this.completedSets,
    required this.readOnly,
    required this.coachingAnalysis,
    required this.recommendationText,
    this.nextPendingSet,
    this.onOpenSet,
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
                  Divider(height: 1, color: context.colors.divider),
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
                        completedLog: completedSets[n],
                        readOnly: readOnly,
                        isNext: n == nextPendingSet,
                        onTap: readOnly || onOpenSet == null
                            ? null
                            : () => onOpenSet!(n),
                      );
                    }),
                  ),
                  if (!readOnly && nextPendingSet != null && onOpenSet != null)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.sm),
                      child: AppButton(
                        key: ValueKey('complete_set_button_${exercise.id}'),
                        label: 'Completar serie $nextPendingSet',
                        icon: Icons.check_rounded,
                        onPressed: () => onOpenSet!(nextPendingSet!),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
