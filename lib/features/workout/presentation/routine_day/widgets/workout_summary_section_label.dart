import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';

/// Etiqueta compartida usada como header de cada sección del summary
/// (Nuevos récords, Vs sesión anterior, Para la próxima…).
class WorkoutSummarySectionLabel extends StatelessWidget {
  const WorkoutSummarySectionLabel({
    super.key,
    required this.text,
    required this.icon,
    required this.iconColor,
  });

  final String text;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 14),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
