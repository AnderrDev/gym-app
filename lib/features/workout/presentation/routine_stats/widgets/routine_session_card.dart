import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/presentation/widgets/glass_container.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_history_session.dart';

/// Card de sesión histórica en la pantalla de stats de rutina: icono +
/// nombre del día + fecha + volumen total a la derecha.
class RoutineSessionCard extends StatelessWidget {
  const RoutineSessionCard({super.key, required this.session});

  final RoutineHistorySession session;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: BorderRadius.circular(16),
      opacity: 0.05,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
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
                  style: context.text.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('EEEE, d MMM', 'es')
                      .format(session.sessionDate)
                      .toUpperCase(),
                  style: context.text.labelMedium?.copyWith(
                    fontSize: 10,
                    color: context.colors.textDisabled,
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
                style: context.text.labelMedium?.copyWith(fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
