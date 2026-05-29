import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Estado vacío del `DayEditorPage`: invita a buscar ejercicios en el
/// catálogo cuando el día todavía no tiene nada.
class DayEditorEmptyState extends StatelessWidget {
  const DayEditorEmptyState({super.key, this.onTap});

  /// `null` cuando el editor se abre en read-only — ocultamos el CTA de
  /// buscar ejercicios pero seguimos mostrando el mensaje contextual.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: context.colors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: context.colors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'Sin ejercicios',
            style: context.text.headlineMedium?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            onTap == null
                ? 'Este día todavía no tiene ejercicios.'
                : 'Añadí ejercicios desde el catálogo para empezar a armar este día.',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(height: Spacing.lg),
            OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(
                'BUSCAR EJERCICIOS',
                style: context.text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.colors.primary,
                side: BorderSide(
                  color: context.colors.primary.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.md,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
