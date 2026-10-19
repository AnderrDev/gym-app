import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

class LoginBrandMark extends StatelessWidget {
  const LoginBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.fitness_center_rounded,
            color: context.colors.onPrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: Spacing.md),
        Text(
          'Gym Tracker',
          style: context.text.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

/// Panel estático: identidad y progresión sin imágenes ni animaciones pesadas.
class LoginBrandPanel extends StatelessWidget {
  const LoginBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(Spacing.xxl),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colors.primary.withValues(alpha: 0.06),
          colors.surface,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoginBrandMark(),
          const SizedBox(height: Spacing.xxxl),
          Text(
            'Cada serie',
            style: context.text.displayMedium?.copyWith(
              fontSize: 52,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'cuenta.',
            style: context.text.displayMedium?.copyWith(
              fontSize: 52,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          Text(
            'Organiza tus rutinas, registra tus entrenamientos y descubre lo que puedes lograr.',
            style: context.text.bodyLarge?.copyWith(
              color: colors.textSecondary,
              height: 1.7,
            ),
          ),
          const SizedBox(height: Spacing.xxl),
          ExcludeSemantics(
            child: SizedBox(
              height: 112,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 6; i++) ...[
                    if (i > 0) const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Container(
                        height: const [28.0, 40.0, 36.0, 64.0, 88.0, 112.0][i],
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(
                            alpha: i == 5 ? 1 : 0.12 + i * 0.09,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: i == 5
                            ? Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: Spacing.md,
                                  ),
                                  child: Icon(
                                    Icons.north_east_rounded,
                                    size: 24,
                                    color: colors.onPrimary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          Text(
            'Constancia antes que perfección.',
            style: context.text.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
