import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/atoms/app_button.dart';

/// Estado vacío genérico. Sustituye los empty UIs ad-hoc de cada pantalla.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconSize = 64,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: context.colors.textDisabled),
            const SizedBox(height: Spacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            ],
            if (primaryActionLabel != null) ...[
              const SizedBox(height: Spacing.xl),
              AppButton(label: primaryActionLabel!, onPressed: onPrimaryAction),
            ],
            if (secondaryActionLabel != null) ...[
              const SizedBox(height: Spacing.sm),
              AppButton(
                label: secondaryActionLabel!,
                onPressed: onSecondaryAction,
                variant: AppButtonVariant.ghost,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
