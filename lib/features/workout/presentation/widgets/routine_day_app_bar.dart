import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/routine_day.dart';
import '../../domain/entities/set_log.dart';
import '../../domain/entities/workout_session.dart';

class RoutineDayAppBar extends StatelessWidget {
  final RoutineDay routineDay;
  final String dateLabel;
  final WorkoutSession? lastSession;
  final List<SetLog> lastLogs;
  final List<Exercise> exercises;
  final VoidCallback onClose;
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
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
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
              size: 24,
            ),
            onPressed: () =>
                onShowLastSessionDetails(lastSession!, lastLogs, exercises),
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              routineDay.name.toUpperCase(),
              style: AppTextStyles.heading2.copyWith(
                fontSize: 16,
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
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
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
            Positioned(
              right: -20,
              top: 40,
              child: Icon(
                Icons.fitness_center,
                size: 180,
                color: AppColors.primary.withValues(alpha: 0.03),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
