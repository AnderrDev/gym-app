import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Cabecera del [WorkoutHistoryBottomSheet]: badge + fecha + cierre.
class WorkoutHistoryHeader extends StatelessWidget {
  const WorkoutHistoryHeader({
    super.key,
    required this.date,
    required this.onClose,
  });

  final DateTime date;
  final VoidCallback onClose;

  String _formatDate(DateTime d) {
    // intl con locale es: `Lunes, 13 may 2026`.
    final dayName = DateFormat('EEEE', 'es').format(d);
    final rest = DateFormat('d MMM yyyy', 'es').format(d);
    final capDay = dayName[0].toUpperCase() + dayName.substring(1);
    return '$capDay · $rest';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.sm,
        Spacing.sm,
        Spacing.lg,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Icon(
              Icons.history_rounded,
              color: context.colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesión anterior',
                  style: AppTextStyles.label.copyWith(
                    color: context.colors.textSecondary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              color: context.colors.textSecondary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
