import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_event.dart';

/// Stub inicial de la pestaña PERFIL. Solo expone el botón "CERRAR SESIÓN"
/// para que el shell sea funcional end-to-end; el contenido real (avatar,
/// datos de cuenta, preferencias) se construye en una task siguiente.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'PERFIL',
          style: AppTextStyles.heading2.copyWith(letterSpacing: 2),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.construction_rounded,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                'Próximamente',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: Spacing.xxl),
              FilledButton.icon(
                onPressed: () =>
                    context.read<AuthBloc>().add(SignOutRequested()),
                icon: const Icon(Icons.logout_rounded),
                label: Text(
                  'CERRAR SESIÓN',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.12),
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.xl,
                    vertical: Spacing.md,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
