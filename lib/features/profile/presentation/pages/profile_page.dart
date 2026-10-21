import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/settings/presentation/settings_bloc.dart';
import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/adaptive/adaptive_sheet.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';
import 'package:gym_flutter/features/auth/domain/entities/user.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gym_flutter/features/profile/presentation/widgets/profile_delete_account_section.dart';
import 'package:gym_flutter/features/profile/presentation/widgets/profile_edit_name_sheet.dart';
import 'package:gym_flutter/features/profile/presentation/widgets/profile_header.dart';
import 'package:gym_flutter/features/profile/presentation/widgets/profile_info_card.dart';
import 'package:gym_flutter/features/profile/presentation/widgets/profile_sign_out_button.dart';
import 'package:gym_flutter/features/profile/presentation/widgets/profile_theme_mode_sheet.dart';
import 'package:gym_flutter/injection_container.dart';

/// Pestaña "PERFIL".
///
/// Renderiza info del user autenticado (consumiendo `AuthBloc`) y permite
/// editar el `full_name` vía `ProfileBloc` + bottom sheet. Al final, la
/// zona de peligro permite eliminar la cuenta. El resto de
/// preferencias (idioma, unidades, theme) sigue como placeholder hasta que
/// cada feature aterrice.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileBloc>(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        title: Text(
          'PERFIL',
          style: context.text.titleLarge?.copyWith(letterSpacing: 2),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial || state is AuthLoading) {
            return const Center(child: AppSpinner.medium());
          }
          if (state is Authenticated) {
            return _ProfileContent(user: state.user);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.user});

  final User user;

  void _onEditName(BuildContext context) {
    final profileBloc = context.read<ProfileBloc>();
    final authBloc = context.read<AuthBloc>();
    AdaptiveSheet.showRaw<void>(
      context,
      builder: (sheetCtx) => BlocProvider.value(
        value: profileBloc,
        child: ProfileEditNameSheet(
          userId: user.id,
          initialValue: user.fullName,
          onSaved: (fullName) {
            authBloc.add(UserProfileUpdated(fullName: fullName));
          },
        ),
      ),
    );
  }

  void _onPickTheme(BuildContext context) {
    AdaptiveSheet.showRaw<void>(
      context,
      builder: (_) => const ProfileThemeModeSheet(),
    );
  }

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
        // El email ya se ve en la cabecera; repetirlo aquí sólo añadía ruido.
        ProfileInfoCard(
          rows: [
            ProfileInfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Nombre',
              value: user.fullName?.isNotEmpty == true ? user.fullName! : '—',
              onTap: () => _onEditName(context),
            ),
          ],
        ),
        const SizedBox(height: Spacing.xl),
        const ProfileSectionTitle('PREFERENCIAS'),
        const SizedBox(height: Spacing.sm),
        BlocBuilder<SettingsBloc, SettingsState>(
          buildWhen: (p, c) => p.themeMode != c.themeMode,
          builder: (context, settings) {
            return ProfileInfoCard(
              rows: [
                ProfileInfoRow(
                  icon: Icons.dark_mode_outlined,
                  label: 'Tema',
                  value: themeModeLabel(settings.themeMode),
                  onTap: () => _onPickTheme(context),
                ),
                // Idioma y unidades no se pueden cambiar todavía: filas
                // "PRÓXIMAMENTE" sin acción no aportaban nada.
              ],
            );
          },
        ),
        const SizedBox(height: Spacing.xl),
        const ProfileSectionTitle('SESIÓN'),
        const SizedBox(height: Spacing.sm),
        const ProfileSignOutButton(),
        const SizedBox(height: Spacing.xxl),
        const ProfileSectionTitle('ZONA DE PELIGRO'),
        const SizedBox(height: Spacing.sm),
        ProfileDeleteAccountSection(userId: user.id),
      ],
    );
  }
}
