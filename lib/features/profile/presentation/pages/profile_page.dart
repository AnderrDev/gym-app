import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/barbell_loader.dart';
import 'package:gym_flutter/features/auth/domain/entities/user.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';

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
        _ProfileHeader(user: user),
        const SizedBox(height: Spacing.xxl),
        const _SectionTitle('CUENTA'),
        const SizedBox(height: Spacing.sm),
        _InfoCard(
          rows: [
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Nombre',
              value: user.fullName ?? '—',
              trailingTag: 'PRÓXIMAMENTE',
            ),
            _InfoRow(
              icon: Icons.alternate_email_rounded,
              label: 'Email',
              value: user.email,
            ),
          ],
        ),
        const SizedBox(height: Spacing.xl),
        const _SectionTitle('PREFERENCIAS'),
        const SizedBox(height: Spacing.sm),
        const _InfoCard(
          rows: [
            _InfoRow(
              icon: Icons.language_rounded,
              label: 'Idioma',
              value: 'Español',
              trailingTag: 'PRÓXIMAMENTE',
            ),
            _InfoRow(
              icon: Icons.straighten_rounded,
              label: 'Unidades',
              value: 'Kilogramos (kg)',
              trailingTag: 'PRÓXIMAMENTE',
            ),
          ],
        ),
        const SizedBox(height: Spacing.xl),
        const _SectionTitle('SESIÓN'),
        const SizedBox(height: Spacing.sm),
        const _SignOutButton(),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final initials = _computeInitials(user.fullName);
    final hasInitials = initials.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: hasInitials
              ? Text(
                  initials,
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.primary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : const Icon(
                  Icons.person_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
        ),
        const SizedBox(height: 16),
        Text(
          (user.fullName != null && user.fullName!.trim().isNotEmpty)
              ? user.fullName!
              : 'Sin nombre',
          style: AppTextStyles.heading2,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Primer letra del primer y último word (max 2 chars, en mayúsculas).
  /// Devuelve `''` cuando no hay nombre utilizable.
  static String _computeInitials(String? fullName) {
    if (fullName == null) return '';
    final words = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    if (words.length == 1) {
      return words.first.characters.first.toUpperCase();
    }
    final first = words.first.characters.first;
    final last = words.last.characters.first;
    return '$first$last'.toUpperCase();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: AppTextStyles.label.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(const Divider(
          height: 1,
          thickness: 1,
          color: AppColors.divider,
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailingTag,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? trailingTag;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailingTag != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Radii.xs),
              ),
              child: Text(
                trailingTag!,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

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

  Future<void> _confirmAndSignOut(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
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
        );
      },
    );
    if (confirmed == true) {
      authBloc.add(SignOutRequested());
    }
  }
}
