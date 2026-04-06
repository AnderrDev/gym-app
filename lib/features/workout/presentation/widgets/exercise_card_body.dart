import 'package:flutter/material.dart';

import '../../domain/entities/coaching_analysis.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/set_log.dart';
import 'exercise_card_coaching.dart';
import 'exercise_card_rest_timer.dart';
import 'exercise_set_row.dart';

class ExerciseCardBody extends StatelessWidget {
  final bool isExpanded;
  final bool isResting;
  final int restSecondsLeft;
  final int restTotalSeconds;
  final String formattedRestTime;
  final int targetSets;
  final Exercise exercise;
  final String sessionId;
  final Map<int, SetLog> completedSets;
  final int? activeSetIndex;
  final SetLog? lastPerformance;
  final bool readOnly;
  final CoachingAnalysis? coachingAnalysis;
  final void Function(int nextSetIndex) onSkipRest;
  final void Function(int setIndex) onActivateSet;
  final void Function(SetLog log, int setIndex) onSaveSet;
  final String Function(String) recommendationText;

  const ExerciseCardBody({
    super.key,
    required this.isExpanded,
    required this.isResting,
    required this.restSecondsLeft,
    required this.restTotalSeconds,
    required this.formattedRestTime,
    required this.targetSets,
    required this.exercise,
    required this.sessionId,
    required this.completedSets,
    required this.activeSetIndex,
    required this.lastPerformance,
    required this.readOnly,
    required this.coachingAnalysis,
    required this.onSkipRest,
    required this.onActivateSet,
    required this.onSaveSet,
    required this.recommendationText,
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFF2A2A2A)),
                  if (coachingAnalysis != null &&
                      coachingAnalysis!.feedback != 'PENDING') ...[
                    const SizedBox(height: 12),
                    ExerciseCardCoachingAdvice(
                      coaching: coachingAnalysis!,
                      compact: false,
                      recommendationText: recommendationText,
                    ),
                  ],
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    layoutBuilder: (currentChild, previousChildren) {
                      final stackedChildren = <Widget>[...previousChildren];
                      if (currentChild != null) {
                        stackedChildren.add(currentChild);
                      }
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: stackedChildren,
                      );
                    },
                    child: isResting
                        ? ExerciseCardRestTimer(
                            secondsLeft: restSecondsLeft,
                            totalSeconds: restTotalSeconds,
                            formattedTime: formattedRestTime,
                            onSkip: () => onSkipRest(completedSets.length + 1),
                          )
                        : Column(
                            key: const ValueKey('sets_list'),
                            children: List.generate(targetSets, (i) {
                              final n = i + 1;
                              return ExerciseSetRow(
                                key: ValueKey('set_${exercise.id}_$n'),
                                setNumber: n,
                                targetReps: exercise.targetReps,
                                targetWeight: exercise.targetWeight,
                                isDone: completedSets.containsKey(n),
                                isActive: activeSetIndex == n,
                                completedLog: completedSets[n],
                                lastPerformanceLog: lastPerformance,
                                sessionId: sessionId,
                                exerciseId: exercise.id,
                                readOnly: readOnly,
                                onActivate: readOnly
                                    ? () {}
                                    : () => onActivateSet(n),
                                onSaved: readOnly
                                    ? (_) {}
                                    : (log) => onSaveSet(log, n),
                              );
                            }),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
