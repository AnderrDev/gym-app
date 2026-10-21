import 'package:flutter/material.dart';
import 'package:gym_flutter/core/utils/date_format.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';
import 'package:gym_flutter/core/ui/molecules/app_card.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_history_session.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/weight_format.dart';

/// Card de sesión histórica en la pantalla de stats de rutina: día + fecha,
/// series y reps, y volumen a la derecha. Tocarla abre el detalle.
class RoutineSessionCard extends StatelessWidget {
  const RoutineSessionCard({
    super.key,
    required this.session,
    this.onTap,
    this.loading = false,
  });

  final RoutineHistorySession session;
  final VoidCallback? onTap;

  /// Cargando el detalle tras tocarla.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final sets = session.setCount;
    return AppCard(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: context.colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.routineDayName,
                  style: context.text.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppDateFormat.weekdayLongDayMonth(session.sessionDate),
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                Text(
                  '$sets ${sets == 1 ? 'serie' : 'series'} · '
                  '${session.totalReps} reps',
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatVolume(session.totalVolume)} kg',
                style: context.text.bodyLarge?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'volumen',
                style: context.text.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          if (onTap != null) ...[
            const SizedBox(width: Spacing.sm),
            SizedBox(
              width: 20,
              child: loading
                  ? const AppSpinner.small()
                  : Icon(
                      Icons.chevron_right_rounded,
                      color: context.colors.textSecondary,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
