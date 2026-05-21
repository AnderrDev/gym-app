import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/atoms/app_button.dart';

/// Estado de error con CTA de reintento. Sustituye los placeholders de error
/// que tenía cada pantalla con su propio Column + Icon + Retry.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Reintentar',
    this.icon = Icons.error_outline_rounded,
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: context.colors.error),
            const SizedBox(height: Spacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: context.colors.error),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: Spacing.lg),
              AppButton(
                label: retryLabel,
                onPressed: onRetry,
                icon: Icons.refresh_rounded,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
