import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_event.dart';

/// CTA destructivo (error tint) que confirma con un AlertDialog antes de
/// disparar `SignOutRequested` en el `AuthBloc`. Tras el confirm el botón
/// queda deshabilitado mostrando un spinner mientras el bloc procesa — el
/// widget se desmonta cuando el router redirige a `/login`, así que no
/// hace falta resetear el flag manualmente.
class ProfileSignOutButton extends StatefulWidget {
  const ProfileSignOutButton({super.key});

  @override
  State<ProfileSignOutButton> createState() => _ProfileSignOutButtonState();
}

class _ProfileSignOutButtonState extends State<ProfileSignOutButton> {
  bool _submitting = false;

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
          title: Text('¿Cerrar sesión?', style: text.headlineSmall),
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
    if (confirmed != true || !mounted) return;
    setState(() => _submitting = true);
    authBloc.add(SignOutRequested());
    // Cuando el AuthBloc emite Unauthenticated, el router navega a /login
    // y este widget se desmonta — no hace falta resetear `_submitting`.
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
        onPressed: _submitting ? null : () => _confirmAndSignOut(context),
        child: _submitting
            ? AppSpinner.small(color: colors.error)
            : Row(
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
