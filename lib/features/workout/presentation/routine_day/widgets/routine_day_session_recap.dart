import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';

/// Header compacto "Última: 28 abr · ↗ +12% volumen". Si hay 2 sesiones
/// recientes calcula el delta de volumen entre la más reciente y la anterior;
/// si solo hay 1, muestra el volumen sin delta.
class RoutineDaySessionRecap extends StatelessWidget {
  const RoutineDaySessionRecap({
    super.key,
    required this.recentSessions,
    required this.recentSessionsLogs,
    required this.exercises,
    required this.onOpenLastSession,
  });

  final List<WorkoutSession> recentSessions;
  final Map<String, List<SetLog>> recentSessionsLogs;
  final List<Exercise> exercises;
  final void Function(
    WorkoutSession session,
    List<SetLog> logs,
    List<Exercise> exercises,
  )
  onOpenLastSession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (recentSessions.isEmpty) return const SizedBox.shrink();

    final last = recentSessions.first;
    final lastLogs = recentSessionsLogs[last.id] ?? const <SetLog>[];
    final lastVolume = _volume(lastLogs);

    final prev = recentSessions.length > 1 ? recentSessions[1] : null;
    final prevVolume = prev == null
        ? null
        : _volume(recentSessionsLogs[prev.id] ?? const <SetLog>[]);
    final deltaPercent = (prevVolume != null && prevVolume > 0)
        ? ((lastVolume - prevVolume) / prevVolume) * 100
        : null;

    final isUp = (deltaPercent ?? 0) >= 0;
    final deltaColor = deltaPercent == null
        ? AppColors.textSecondary
        : (isUp ? AppColors.success : AppColors.error);

    return InkWell(
      onTap: () => onOpenLastSession(last, lastLogs, exercises),
      borderRadius: BorderRadius.circular(Radii.lg),
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ÚLTIMA SESIÓN',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(last.sessionDate)} · ${lastLogs.length} series · ${lastVolume.toStringAsFixed(0)} kg',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (deltaPercent != null) ...[
              const SizedBox(width: Spacing.sm),
              _DeltaPill(color: deltaColor, isUp: isUp, percent: deltaPercent),
            ],
            const SizedBox(width: Spacing.sm),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  static double _volume(List<SetLog> logs) =>
      logs.fold(0.0, (s, l) => s + l.actualWeight * l.actualReps);

  static String _formatDate(DateTime d) {
    const months = [
      '',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${d.day} ${months[d.month]}';
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({
    required this.color,
    required this.isUp,
    required this.percent,
  });

  final Color color;
  final bool isUp;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${isUp ? '+' : ''}${percent.toStringAsFixed(1)}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
