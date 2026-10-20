import 'package:flutter/material.dart';
import 'package:gym_flutter/core/utils/date_format.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/molecules/app_card.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_history_session.dart';

/// Card de sesión histórica en la pantalla de stats de rutina: icono +
/// nombre del día + fecha + volumen total a la derecha.
class RoutineSessionCard extends StatelessWidget {
  const RoutineSessionCard({super.key, required this.session});

  final RoutineHistorySession session;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
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
                  AppDateFormat.weekdayLongDayMonth(
                    session.sessionDate,
                  ).toUpperCase(),
                  style: context.text.labelSmall?.copyWith(
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
                '${session.totalVolume.toStringAsFixed(0)} kg',
                style: context.text.bodyLarge?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'VOL. TOTAL',
                style: context.text.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
