import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_card_coaching.dart';

enum _HeaderMenuAction { target, insights, progress, howTo }

class _HeaderMenuTile extends StatelessWidget {
  const _HeaderMenuTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: context.colors.primary),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            label,
            style: context.text.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class ExerciseCardHeader extends StatelessWidget {
  final Exercise exercise;
  final SetLog? lastPerformance;
  final CoachingAnalysis? coachingAnalysis;
  final bool readOnly;
  final bool isExpanded;
  final bool allDone;
  final int targetSets;
  final int doneCount;
  final bool showLiveAdvice;
  final String? liveAdvice;
  final Animation<double> pulseAnimation;
  final VoidCallback onToggleExpanded;
  final VoidCallback onOpenTargetEditor;
  final VoidCallback onOpenInsights;
  final VoidCallback onOpenProgress;
  final VoidCallback onOpenHowTo;
  final String Function(String) recommendationText;
  final bool showExpandChevron;

  const ExerciseCardHeader({
    super.key,
    required this.exercise,
    required this.lastPerformance,
    required this.coachingAnalysis,
    required this.readOnly,
    required this.isExpanded,
    required this.allDone,
    required this.targetSets,
    required this.doneCount,
    required this.showLiveAdvice,
    required this.liveAdvice,
    required this.pulseAnimation,
    required this.onToggleExpanded,
    required this.onOpenTargetEditor,
    required this.onOpenInsights,
    required this.onOpenProgress,
    required this.onOpenHowTo,
    required this.recommendationText,
    this.showExpandChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      onTap: onToggleExpanded,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: allDone
                        ? context.colors.success.withValues(alpha: 0.15)
                        : context.colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    allDone
                        ? Icons.check_circle_rounded
                        : Icons.local_fire_department_rounded,
                    size: 20,
                    color: allDone
                        ? context.colors.success
                        : context.colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: context.text.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'TARGET: ${exercise.targetWeight.toStringAsFixed(0)}kg x ${exercise.targetReps}',
                              style: context.text.labelMedium?.copyWith(
                                color: context.colors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '$targetSets series',
                            style: context.text.labelMedium?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                          if (lastPerformance != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 12,
                                  color: context.colors.primary.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Record: ${lastPerformance!.actualWeight.toStringAsFixed(0)}kg x ${lastPerformance!.actualReps}',
                                  style: context.text.labelMedium?.copyWith(
                                    color: context.colors.primary.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '$doneCount/$targetSets',
                  style: context.text.bodyMedium?.copyWith(
                    color: readOnly
                        ? context.colors.textSecondary
                        : (allDone
                              ? context.colors.success
                              : context.colors.primary),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                if (showExpandChevron)
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: context.colors.textSecondary,
                  ),
                PopupMenuButton<_HeaderMenuAction>(
                  tooltip: 'Más opciones',
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: context.colors.textSecondary,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  onSelected: (action) {
                    switch (action) {
                      case _HeaderMenuAction.target:
                        onOpenTargetEditor();
                      case _HeaderMenuAction.insights:
                        onOpenInsights();
                      case _HeaderMenuAction.progress:
                        onOpenProgress();
                      case _HeaderMenuAction.howTo:
                        onOpenHowTo();
                    }
                  },
                  itemBuilder: (context) => [
                    if (!readOnly)
                      const PopupMenuItem(
                        key: ValueKey('menu_target'),
                        value: _HeaderMenuAction.target,
                        child: _HeaderMenuTile(
                          icon: Icons.settings_remote_rounded,
                          label: 'Cambiar objetivo',
                        ),
                      ),
                    const PopupMenuItem(
                      key: ValueKey('menu_howto'),
                      value: _HeaderMenuAction.howTo,
                      child: _HeaderMenuTile(
                        icon: Icons.info_outline_rounded,
                        label: 'Cómo se hace',
                      ),
                    ),
                    const PopupMenuItem(
                      key: ValueKey('menu_insights'),
                      value: _HeaderMenuAction.insights,
                      child: _HeaderMenuTile(
                        icon: Icons.insights_rounded,
                        label: 'Insights',
                      ),
                    ),
                    const PopupMenuItem(
                      key: ValueKey('menu_progress'),
                      value: _HeaderMenuAction.progress,
                      child: _HeaderMenuTile(
                        icon: Icons.open_in_full_rounded,
                        label: 'Ver progreso',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (coachingAnalysis?.hasActionableAdvice ?? false) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ExerciseCardCoachingBadge(
                  coaching: coachingAnalysis!,
                  pulseAnimation: pulseAnimation,
                ),
              ),
            ],
            // Barra de progreso intra-ejercicio removida: era redundante con
            // el contador "X/Y" del header, los dots del stepper superior, y
            // el estado verde por fila. La barra del app bar comunica el
            // progreso de la rutina completa.
            if ((coachingAnalysis?.hasActionableAdvice ?? false) &&
                !isExpanded) ...[
              const SizedBox(height: 12),
              ExerciseCardCoachingAdvice(
                coaching: coachingAnalysis!,
                compact: true,
                recommendationText: recommendationText,
              ),
            ],
            if (showLiveAdvice && liveAdvice != null) ...[
              const SizedBox(height: 12),
              ExerciseCardLiveAdvice(text: liveAdvice!),
            ],
          ],
        ),
      ),
    );
  }
}
