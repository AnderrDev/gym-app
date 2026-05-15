import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/barbell_loader.dart';
import 'package:gym_flutter/features/auth/domain/entities/user.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/profile/presentation/widgets/profile_header.dart';
import 'package:gym_flutter/features/profile/presentation/widgets/profile_info_card.dart';
import 'package:gym_flutter/features/profile/presentation/widgets/profile_sign_out_button.dart';

/// Pestaña "PERFIL" — read-only MVP.
///
/// Renderiza la info disponible del usuario autenticado (consumiendo
/// directamente `AuthBloc`) más un CTA de cierre de sesión. Cualquier
/// capacidad de edición (nombre, avatar, preferencias) construirá su propia
/// feature `profile/` con bloc + repo cuando llegue el momento; hoy sería
/// abstracción prematura.
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
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial || state is AuthLoading) {
            return const Center(child: BarbellLoader.medium());
          }
          if (state is Authenticated) {
            return _ProfileContent(user: state.user);
          }
          // Unauthenticated / AuthError: el router redirige a /login;
          // devolvemos un widget vacío como defensa.
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.lg,
        Spacing.xl,
        Spacing.xxl + 80,
      ),
      children: [
        ProfileHeader(user: user),
        const SizedBox(height: Spacing.xxl),
        const ProfileSectionTitle('CUENTA'),
        const SizedBox(height: Spacing.sm),
        ProfileInfoCard(
          rows: [
            ProfileInfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Nombre',
              value: user.fullName ?? '—',
              trailingTag: 'PRÓXIMAMENTE',
            ),
            ProfileInfoRow(
              icon: Icons.alternate_email_rounded,
              label: 'Email',
              value: user.email,
            ),
          ],
        ),
        const SizedBox(height: Spacing.xl),
        const ProfileSectionTitle('PREFERENCIAS'),
        const SizedBox(height: Spacing.sm),
        const ProfileInfoCard(
          rows: [
            ProfileInfoRow(
              icon: Icons.language_rounded,
              label: 'Idioma',
              value: 'Español',
              trailingTag: 'PRÓXIMAMENTE',
            ),
            ProfileInfoRow(
              icon: Icons.straighten_rounded,
              label: 'Unidades',
              value: 'Kilogramos (kg)',
              trailingTag: 'PRÓXIMAMENTE',
            ),
          ],
        ),
        const SizedBox(height: Spacing.xl),
        const ProfileSectionTitle('SESIÓN'),
        const SizedBox(height: Spacing.sm),
        const ProfileSignOutButton(),
      ],
    );
  }
}
