import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';

/// Hero del detalle de ejercicio:
/// - Si hay `animationUrl` (GIF/MP4 corto), se prefiere — usamos `Image.network`
///   porque también sirve GIFs animados. Para MP4 hace falta otro widget (no
///   lo manejamos por ahora: si el campo tiene un .mp4, cae al fallback).
/// - Si no, `imageUrl` estática.
/// - Si tampoco, placeholder con el ícono y el nombre del músculo.
class ExerciseMediaHero extends StatelessWidget {
  const ExerciseMediaHero({
    super.key,
    required this.muscleGroup,
    this.imageUrl,
    this.animationUrl,
  });

  final String muscleGroup;
  final String? imageUrl;
  final String? animationUrl;

  String? get _bestSource {
    final candidate = animationUrl ?? imageUrl;
    if (candidate == null || candidate.trim().isEmpty) return null;
    // No soportamos MP4 inline todavía — si el .mp4 viene en animation_url,
    // intentamos image_url como fallback.
    if (candidate.toLowerCase().endsWith('.mp4') ||
        candidate.toLowerCase().endsWith('.webm')) {
      if (imageUrl != null && imageUrl!.trim().isNotEmpty) return imageUrl;
      return null;
    }
    return candidate;
  }

  @override
  Widget build(BuildContext context) {
    final src = _bestSource;
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceHighlight,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: src == null
            ? _Placeholder(muscleGroup: muscleGroup)
            : Image.network(
                src,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: AppSpinner.medium());
                },
                errorBuilder: (context, error, stack) =>
                    _Placeholder(muscleGroup: muscleGroup),
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.muscleGroup});

  final String muscleGroup;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              size: 48,
              color: context.colors.textDisabled,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              muscleGroup.isEmpty
                  ? 'Sin imagen disponible'
                  : muscleGroup.toUpperCase(),
              style: AppTextStyles.label.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
