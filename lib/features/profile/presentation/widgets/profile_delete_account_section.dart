import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/atoms/app_button.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/core/ui/molecules/app_form_field.dart';
import 'package:gym_flutter/features/profile/domain/usecases/delete_account.dart';
import 'package:gym_flutter/features/profile/presentation/bloc/profile_bloc.dart';

/// Zona de peligro del perfil: "Eliminar cuenta" (App Store 5.1.1(v)).
///
/// Abre [DeleteAccountConfirmDialog]; al confirmar dispara
/// `DeleteAccountRequested` en el `ProfileBloc`. Mientras el servidor procesa
/// el botón muestra un spinner. Si falla, snackbar de error y la cuenta sigue
/// intacta; si va bien, el bloc limpia el dispositivo y cierra sesión, y el
/// router lleva a /login (el snackbar vive en el ScaffoldMessenger raíz, así
/// que sobrevive al cambio de pantalla).
class ProfileDeleteAccountSection extends StatelessWidget {
  const ProfileDeleteAccountSection({super.key, required this.userId});

  final String userId;

  Future<void> _onDelete(BuildContext context) async {
    final bloc = context.read<ProfileBloc>();
    final confirmation = await DeleteAccountConfirmDialog.show(context);
    if (confirmation == null) return;
    bloc.add(
      DeleteAccountRequested(userId: userId, confirmation: confirmation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (p, c) => p.deletionStatus != c.deletionStatus,
      listener: (context, state) {
        switch (state.deletionStatus) {
          case AccountDeletionStatus.deleted:
            AppSnackBar.success(
              context,
              'Tu cuenta se eliminó',
              duration: const Duration(seconds: 4),
            );
          case AccountDeletionStatus.failure:
            AppSnackBar.error(
              context,
              state.deletionErrorMessage ?? 'No se pudo eliminar tu cuenta.',
            );
            context.read<ProfileBloc>().add(const AcknowledgeProfileFeedback());
          case AccountDeletionStatus.idle:
          case AccountDeletionStatus.deleting:
            break;
        }
      },
      buildWhen: (p, c) => p.deletionStatus != c.deletionStatus,
      builder: (context, state) {
        final busy =
            state.deletionStatus == AccountDeletionStatus.deleting ||
            state.deletionStatus == AccountDeletionStatus.deleted;
        return Container(
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: colors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Eliminar cuenta',
                style: text.titleMedium?.copyWith(
                  color: colors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'Borra tu cuenta y tus datos de forma permanente.',
                style: text.bodySmall?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: Spacing.md),
              AppButton(
                label: 'Eliminar cuenta',
                icon: Icons.delete_forever_rounded,
                variant: AppButtonVariant.destructive,
                isLoading: busy,
                onPressed: busy ? null : () => _onDelete(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Diálogo de confirmación de "Eliminar cuenta". Explica qué se borra y
/// exige escribir `ELIMINAR` para habilitar el botón. Devuelve el texto
/// confirmado, o `null` si se cancela.
class DeleteAccountConfirmDialog extends StatefulWidget {
  const DeleteAccountConfirmDialog({super.key});

  static Future<String?> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showDialog<String>(
      context: context,
      builder: (_) => const DeleteAccountConfirmDialog(),
    );
  }

  @override
  State<DeleteAccountConfirmDialog> createState() =>
      _DeleteAccountConfirmDialogState();
}

class _DeleteAccountConfirmDialogState
    extends State<DeleteAccountConfirmDialog> {
  String _typed = '';

  // Sin distinguir mayúsculas: el teclado puede no estar en mayúsculas y
  // escribir la palabra ya es la acción deliberada que buscamos.
  bool get _matches =>
      _typed.trim().toUpperCase() == deleteAccountConfirmationWord;

  void _confirm() {
    if (!_matches) return;
    Navigator.of(context).pop(deleteAccountConfirmationWord);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
      title: Text('¿Eliminar tu cuenta?', style: text.headlineSmall),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción es permanente y no se puede deshacer. Se borrarán '
              'tu perfil, tu historial de entrenamientos y series, tu rutina '
              'asignada y tus rutinas privadas.',
              style: text.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'Tus rutinas públicas seguirán disponibles para quien las use, '
              'pero de forma anónima: ya no aparecerán a tu nombre.',
              style: text.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'Escribe $deleteAccountConfirmationWord para confirmar.',
              style: text.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            AppFormField(
              label: 'Confirmación',
              value: _typed,
              hintText: deleteAccountConfirmationWord,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (value) => setState(() => _typed = value),
              onSubmitted: (_) => _confirm(),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        AppButton(
          label: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
          variant: AppButtonVariant.ghost,
          expand: false,
        ),
        AppButton(
          key: const Key('delete_account_confirm_button'),
          label: 'Eliminar cuenta',
          onPressed: _matches ? _confirm : null,
          variant: AppButtonVariant.destructive,
          expand: false,
        ),
      ],
    );
  }
}
