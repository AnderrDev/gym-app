import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_flutter/core/forms/inputs/password.dart';
import 'package:gym_flutter/core/routes/app_routes.dart';
import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/atoms/app_button.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';
import 'package:gym_flutter/core/ui/molecules/app_empty_state.dart';
import 'package:gym_flutter/core/ui/molecules/app_form_field.dart';
import 'package:gym_flutter/features/auth/domain/usecases/update_password.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/auth/presentation/widgets/password_strength_meter.dart';
import 'package:gym_flutter/injection_container.dart';

/// Destino del enlace de recuperación de contraseña.
///
/// Supabase canjea el enlace al arrancar y deja una sesión temporal: con ella
/// el usuario fija la contraseña nueva. Sin sesión (enlace caducado, ya usado
/// o abierto en otro navegador/dispositivo que el que lo pidió) se explica
/// qué pasó en vez de rebotar al login sin contexto. Igual que `ForgotPasswordSheet`, es un
/// flujo one-shot que no pasa por `AuthBloc`.
class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key, this.updatePassword});

  /// Inyectable para tests; por defecto se resuelve del DI.
  final UpdatePassword? updatePassword;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Nueva contraseña'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) => switch (state) {
                AuthInitial() ||
                AuthLoading() => const Center(child: AppSpinner.medium()),
                Authenticated() => _NewPasswordForm(
                  updatePassword: updatePassword ?? sl<UpdatePassword>(),
                ),
                _ => AppEmptyState(
                  icon: Icons.link_off_rounded,
                  title: 'El enlace no es válido o ya caducó',
                  subtitle: kIsWeb
                      ? 'Ábrelo en el mismo navegador donde lo pediste o '
                            'solicita uno nuevo desde "¿Olvidaste tu '
                            'contraseña?".'
                      : 'Ábrelo en el mismo dispositivo donde lo pediste o '
                            'solicita uno nuevo desde "¿Olvidaste tu '
                            'contraseña?".',
                  primaryActionLabel: 'Ir a iniciar sesión',
                  onPrimaryAction: () => context.go(AppRoutes.login),
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NewPasswordForm extends StatefulWidget {
  const _NewPasswordForm({required this.updatePassword});

  final UpdatePassword updatePassword;

  @override
  State<_NewPasswordForm> createState() => _NewPasswordFormState();
}

class _NewPasswordFormState extends State<_NewPasswordForm> {
  Password _password = const Password.pure();
  String _confirmation = '';
  bool _confirmationTouched = false;
  bool _submitting = false;

  bool get _matches => _confirmation == _password.value;

  String? get _confirmationError =>
      _confirmationTouched && !_matches ? 'Las contraseñas no coinciden' : null;

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_password.isValid || !_matches) {
      setState(() {
        _password = Password.dirty(_password.value);
        _confirmationTouched = true;
      });
      return;
    }
    setState(() => _submitting = true);
    final result = await widget.updatePassword(_password.value);
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold((failure) => AppSnackBar.error(context, failure.message), (_) {
      AppSnackBar.success(context, 'Contraseña actualizada');
      context.go(AppRoutes.dashboard);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.xl),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Elige una contraseña nueva para tu cuenta.',
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            AppFormField(
              label: 'Contraseña nueva',
              value: _password.value,
              onChanged: (v) => setState(() => _password = Password.dirty(v)),
              errorText: _password.isPure ? null : _password.error?.message,
              obscureText: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              prefixIcon: Icons.lock_outline_rounded,
            ),
            PasswordStrengthMeter(password: _password.value),
            const SizedBox(height: Spacing.md),
            AppFormField(
              label: 'Repite la contraseña',
              value: _confirmation,
              onChanged: (v) => setState(() {
                _confirmation = v;
                _confirmationTouched = true;
              }),
              errorText: _confirmationError,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              prefixIcon: Icons.lock_outline_rounded,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: Spacing.xl),
            AppButton(
              label: 'Guardar contraseña',
              onPressed: _submit,
              isLoading: _submitting,
              expand: true,
            ),
            const SizedBox(height: Spacing.sm),
            AppButton(
              label: 'Ahora no',
              variant: AppButtonVariant.ghost,
              onPressed: _submitting
                  ? null
                  : () => context.go(AppRoutes.dashboard),
              expand: true,
            ),
          ],
        ),
      ),
    );
  }
}
