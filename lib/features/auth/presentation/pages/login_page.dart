import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:gym_flutter/core/forms/inputs/email.dart';
import 'package:gym_flutter/core/forms/inputs/password.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/atoms/app_button.dart';
import 'package:gym_flutter/core/ui/molecules/app_form_field.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/login_form/login_form_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/login_form/login_form_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/login_form/login_form_state.dart';
import 'package:gym_flutter/features/auth/presentation/widgets/forgot_password_sheet.dart';
import 'package:gym_flutter/features/auth/presentation/widgets/login_brand_panel.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginFormBloc>(
      create: (_) => LoginFormBloc(
        seedEmail: kDebugMode && dotenv.isInitialized
            ? dotenv.maybeGet('DEV_LOGIN_EMAIL')
            : null,
        seedPassword: kDebugMode && dotenv.isInitialized
            ? dotenv.maybeGet('DEV_LOGIN_PASSWORD')
            : null,
      ),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  void _onSubmit(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSubmitting || authState is AuthLoading) return;
    final form = context.read<LoginFormBloc>().state;
    if (!form.isValid) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      SignInRequested(form.email.value.trim(), form.password.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (_, current) => current is Authenticated,
        listener: (_, _) => TextInput.finishAutofillContext(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 960;
              final padding = wide ? Spacing.xxl : Spacing.xl;
              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, constraints.maxHeight - padding * 2),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1160),
                      child: wide
                          ? Row(
                              children: [
                                const Expanded(child: LoginBrandPanel()),
                                const SizedBox(width: 80),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: _LoginForm(
                                      wide: true,
                                      onSubmit: _onSubmit,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _LoginForm(wide: false, onSubmit: _onSubmit),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({required this.wide, required this.onSubmit});
  final bool wide;
  final void Function(BuildContext) onSubmit;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: AutofillGroup(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final busy =
                authState is AuthSubmitting || authState is AuthLoading;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!wide) ...[
                  const LoginBrandMark(),
                  const SizedBox(height: Spacing.xxxl),
                ],
                Semantics(
                  header: true,
                  child: Text(
                    'Bienvenido de nuevo',
                    style: context.text.headlineLarge?.copyWith(
                      fontSize: wide ? 34 : 30,
                      height: 1.2,
                      letterSpacing: -1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  'Tu próximo entrenamiento empieza aquí.',
                  style: context.text.bodyLarge?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: Spacing.xxl),
                BlocBuilder<LoginFormBloc, LoginFormState>(
                  buildWhen: (p, c) => p.email != c.email,
                  builder: (context, state) => AppFormField(
                    label: 'Correo electrónico',
                    uppercaseLabel: false,
                    autofocus: wide,
                    value: state.email.value,
                    onChanged: (v) {
                      context.read<AuthBloc>().add(AuthErrorDismissed());
                      context.read<LoginFormBloc>().add(LoginEmailChanged(v));
                    },
                    errorText: state.email.isPure
                        ? null
                        : state.email.error?.message,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    hintText: 'tu@correo.com',
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                BlocBuilder<LoginFormBloc, LoginFormState>(
                  buildWhen: (p, c) => p.password != c.password,
                  builder: (context, state) => AppFormField(
                    label: 'Contraseña',
                    uppercaseLabel: false,
                    value: state.password.value,
                    onChanged: (v) {
                      context.read<AuthBloc>().add(AuthErrorDismissed());
                      context.read<LoginFormBloc>().add(
                        LoginPasswordChanged(v),
                      );
                    },
                    errorText: state.password.isPure
                        ? null
                        : state.password.error?.message,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    hintText: 'Escribe tu contraseña',
                    onSubmitted: (_) => onSubmit(context),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => ForgotPasswordSheet.show(
                      context,
                      initialEmail: context
                          .read<LoginFormBloc>()
                          .state
                          .email
                          .value,
                    ),
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                if (authState is AuthError) ...[
                  const SizedBox(height: Spacing.md),
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.all(Spacing.lg),
                      decoration: BoxDecoration(
                        color: context.colors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        authState.message,
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.error,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: Spacing.lg),
                BlocBuilder<LoginFormBloc, LoginFormState>(
                  buildWhen: (p, c) => p.isValid != c.isValid,
                  builder: (context, form) => AppButton(
                    label: 'Iniciar sesión',
                    uppercaseLabel: false,
                    isLoading: busy,
                    onPressed: !busy && form.isValid
                        ? () => onSubmit(context)
                        : null,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '¿Aún no tienes cuenta?',
                      style: context.text.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => goToRegister(context),
                      child: const Text('Crear cuenta'),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xxl),
                Divider(color: context.colors.divider),
                const SizedBox(height: Spacing.lg),
                Text(
                  'Un entrenamiento a la vez.',
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
