import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Chips compactos con metadata del ejercicio: músculo, equipo y dificultad.
/// Cada uno aparece sólo si tiene contenido — sin saltos visuales si faltan.
class ExerciseInfoChips extends StatelessWidget {
  const ExerciseInfoChips({
    super.key,
    required this.muscleGroup,
    this.equipment,
    this.difficulty,
  });

  final String muscleGroup;
  final String? equipment;
  final String? difficulty;

  static Color _difficultyColor(String? d) {
    switch (d?.toLowerCase()) {
      case 'principiante':
        return AppColors.success;
      case 'intermedio':
        return AppColors.warning;
      case 'avanzado':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  static String _difficultyLabel(String d) {
    return '${d[0].toUpperCase()}${d.substring(1).toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (muscleGroup.trim().isNotEmpty) {
      chips.add(
        _Chip(
          icon: Icons.accessibility_new_rounded,
          label: muscleGroup.toUpperCase(),
          color: AppColors.primary,
        ),
      );
    }
    if (equipment != null && equipment!.trim().isNotEmpty) {
      chips.add(
        _Chip(
          icon: Icons.fitness_center_rounded,
          label: equipment!,
          color: AppColors.textSecondary,
        ),
      );
    }
    if (difficulty != null && difficulty!.trim().isNotEmpty) {
      chips.add(
        _Chip(
          icon: Icons.bolt_rounded,
          label: _difficultyLabel(difficulty!),
          color: _difficultyColor(difficulty),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: chips,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
