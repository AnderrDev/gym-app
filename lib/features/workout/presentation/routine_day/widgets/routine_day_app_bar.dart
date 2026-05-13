import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';

class RoutineDayAppBar extends StatelessWidget {
  final RoutineDay routineDay;
  final String dateLabel;
  final WorkoutSession? lastSession;
  final List<SetLog> lastLogs;
  final List<Exercise> exercises;
  final bool isActive;
  final double? totalVolume;
  final int completedSets;
  final int totalSets;
  final VoidCallback onClose;
  final VoidCallback? onFinish;
  final void Function(
    WorkoutSession session,
    List<SetLog> logs,
    List<Exercise> exercises,
  )
  onShowLastSessionDetails;

  const RoutineDayAppBar({
    super.key,
    required this.routineDay,
    required this.dateLabel,
    required this.lastSession,
    required this.lastLogs,
    required this.exercises,
    required this.onClose,
    required this.onShowLastSessionDetails,
    this.isActive = false,
    this.totalVolume,
    this.completedSets = 0,
    this.totalSets = 0,
    this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return SliverAppBar(
        pinned: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: AppColors.textPrimary,
            size: 24,
          ),
          onPressed: onClose,
        ),
        title: Text(
          routineDay.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: _ActiveBottomBar(
            completedSets: completedSets,
            totalSets: totalSets,
            totalVolume: totalVolume ?? 0,
            hasLastSession: lastSession != null,
            onOpenHistory: lastSession == null
                ? null
                : () => onShowLastSessionDetails(
                    lastSession!,
                    lastLogs,
                    exercises,
                  ),
            onFinish: onFinish,
          ),
        ),
      );
    }
    // Prestart / lectura: mantenemos el hero con gradiente.
    return SliverAppBar(
      expandedHeight: 132,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.close_rounded,
          color: AppColors.textPrimary,
          size: 24,
        ),
        onPressed: onClose,
      ),
      actions: [
        if (lastSession != null)
          IconButton(
            icon: const Icon(
              Icons.history_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            onPressed: () =>
                onShowLastSessionDetails(lastSession!, lastLogs, exercises),
          ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              routineDay.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.heading2.copyWith(
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              dateLabel,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.background,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveBottomBar extends StatelessWidget {
  const _ActiveBottomBar({
    required this.completedSets,
    required this.totalSets,
    required this.totalVolume,
    required this.hasLastSession,
    required this.onOpenHistory,
    required this.onFinish,
  });

  final int completedSets;
  final int totalSets;
  final double totalVolume;
  final bool hasLastSession;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final progress = totalSets > 0
        ? (completedSets / totalSets).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        0,
        Spacing.sm,
        Spacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de progreso implícitamente animada. Solo el child
          // (FractionallySizedBox) cambia su widthFactor a 60fps; el
          // resto del app bar no se rebuildea. Es lighter que un
          // TweenAnimationBuilder envolviendo un LinearProgressIndicator
          // porque no recrea el widget cada frame y no paga el paint de
          // un LinearProgressIndicator (que internamente maneja también
          // el modo indeterminado).
          SizedBox(
            height: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                // fit: expand pasa constraints tight a los children no
                // posicionados, así FractionallySizedBox tiene un maxWidth
                // finito contra el que computar el factor.
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: AppColors.divider),
                  AnimatedFractionallySizedBox(
                    widthFactor: progress,
                    alignment: Alignment.centerLeft,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: const ColoredBox(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Row(
            children: [
              Text(
                '$completedSets/$totalSets series',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (totalVolume > 0) ...[
                const SizedBox(width: Spacing.sm),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  '${totalVolume.toStringAsFixed(0)} kg',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const Spacer(),
              if (hasLastSession && onOpenHistory != null)
                IconButton(
                  icon: const Icon(
                    Icons.history_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: onOpenHistory,
                ),
              if (onFinish != null) ...[
                const SizedBox(width: 4),
                TextButton(
                  onPressed: onFinish,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Text(
                    'FINALIZAR',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
