import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        title: Text(
          '¿Cerrar sesión?',
          style: AppTextStyles.heading2.copyWith(fontSize: 18),
        ),
        content: Text(
          'Tendrás que volver a iniciar sesión para acceder a tus rutinas.',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: Text(
              'CANCELAR',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onPrimary,
            ),
            child: Text(
              'CERRAR SESIÓN',
              style: AppTextStyles.label.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      authBloc.add(SignOutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.error.withValues(alpha: 0.12),
          foregroundColor: AppColors.error,
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          side: BorderSide(
            color: AppColors.error.withValues(alpha: 0.3),
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
            const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
            const SizedBox(width: Spacing.sm),
            Text(
              'CERRAR SESIÓN',
              style: AppTextStyles.label.copyWith(
                color: AppColors.error,
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
