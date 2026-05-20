import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_event.dart';

/// CTA destructivo (error tint) que confirma con un AlertDialog antes de
/// disparar `SignOutRequested` en el `AuthBloc`.
class ProfileSignOutButton extends StatelessWidget {
  const ProfileSignOutButton({super.key});

  Future<void> _confirmAndSignOut(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.colors;
        final text = dialogContext.text;
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          title: Text(
            '¿Cerrar sesión?',
            style: text.headlineSmall,
          ),
          content: Text(
            'Tendrás que volver a iniciar sesión para acceder a tus rutinas.',
            style: text.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
              ),
              child: Text(
                'CANCELAR',
                style: text.labelMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onPrimary,
              ),
              child: Text(
                'CERRAR SESIÓN',
                style: text.labelMedium?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      authBloc.add(SignOutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          backgroundColor: colors.error.withValues(alpha: 0.12),
          foregroundColor: colors.error,
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          side: BorderSide(
            color: colors.error.withValues(alpha: 0.3),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
        onPressed: () => _confirmAndSignOut(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout_rounded, size: 18, color: colors.error),
            const SizedBox(width: Spacing.sm),
            Text(
              'CERRAR SESIÓN',
              style: text.labelMedium?.copyWith(
                color: colors.error,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
