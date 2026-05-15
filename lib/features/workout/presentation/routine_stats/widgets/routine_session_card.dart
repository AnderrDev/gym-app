import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
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
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.primary,
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
                  style: AppTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('EEEE, d MMM', 'es')
                      .format(session.sessionDate)
                      .toUpperCase(),
                  style: AppTextStyles.label.copyWith(
                    fontSize: 10,
                    color: AppColors.textDisabled,
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
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'VOL. TOTAL',
                style: AppTextStyles.label.copyWith(fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
