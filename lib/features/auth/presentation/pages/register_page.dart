import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

import 'package:gym_flutter/core/forms/inputs/email.dart';
import 'package:gym_flutter/core/forms/inputs/password.dart';
import 'package:gym_flutter/core/forms/inputs/required_text.dart';
import 'package:gym_flutter/core/presentation/widgets/glass_container.dart';
import 'package:gym_flutter/core/presentation/widgets/kinetic_button.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/core/ui/molecules/app_form_field.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/register_form/register_form_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/register_form/register_form_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/register_form/register_form_state.dart';
import 'package:gym_flutter/features/auth/presentation/widgets/auth_aura_background.dart';
import 'package:gym_flutter/features/auth/presentation/widgets/auth_stagger_entrance.dart';
import 'package:gym_flutter/features/auth/presentation/widgets/password_strength_meter.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegisterFormBloc>(
      create: (_) => RegisterFormBloc(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatelessWidget {
  const _RegisterView();

  void _onSubmit(BuildContext context) {
    final formState = context.read<RegisterFormBloc>().state;
    if (!formState.isValid) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      SignUpRequested(
        formState.email.value.trim(),
        formState.password.value,
        formState.fullName.value.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) => current is AuthError,
        listener: (context, state) {
          if (state is AuthError) {
            AppSnackBar.error(context, state.message);
          }
        },
        child: AuthAuraBackground(
          child: AutofillGroup(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28.0),
                child: GlassContainer(
                  padding: const EdgeInsets.all(Spacing.xxl),
                  borderRadius: BorderRadius.circular(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthStaggerEntrance(
                        child: Icon(
                          Icons.person_add_rounded,
                          size: 64,
                          color: context.colors.primary,
                        ),
                      ),
                      const SizedBox(height: Spacing.xl),
                      AuthStaggerEntrance(
                        delay: const Duration(milliseconds: 80),
                        child: Text(
                          'UNIRSE A LA ÉLITE',
                          textAlign: TextAlign.center,
                          style: textTheme.displayMedium?.copyWith(
                            letterSpacing: 4,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      AuthStaggerEntrance(
                        delay: const Duration(milliseconds: 160),
                        child: Text(
                          'TU EVOLUCIÓN EMPIEZA AQUÍ',
                          textAlign: TextAlign.center,
                          style: textTheme.labelMedium?.copyWith(
                            letterSpacing: 2,
                            color: context.colors.primary.withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.xxxl),
                      AuthStaggerEntrance(
                        delay: const Duration(milliseconds: 240),
                        child: BlocBuilder<RegisterFormBloc, RegisterFormState>(
                          buildWhen: (p, c) => p.fullName != c.fullName,
                          builder: (context, state) {
                            final input = state.fullName;
                            return AppFormField(
                              label: 'Nombre completo',
                              value: input.value,
                              onChanged: (v) => context
                                  .read<RegisterFormBloc>()
                                  .add(RegisterFullNameChanged(v)),
                              errorText: input.isPure
                                  ? null
                                  : input.error?.message(input.minLength),
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              prefixIcon: Icons.person_outline_rounded,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),
                      AuthStaggerEntrance(
                        delay: const Duration(milliseconds: 320),
                        child: BlocBuilder<RegisterFormBloc, RegisterFormState>(
                          buildWhen: (p, c) => p.email != c.email,
                          builder: (context, state) {
                            return AppFormField(
                              label: 'Email',
                              value: state.email.value,
                              onChanged: (v) => context
                                  .read<RegisterFormBloc>()
                                  .add(RegisterEmailChanged(v)),
                              errorText: state.email.isPure
                                  ? null
                                  : state.email.error?.message,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newUsername],
                              prefixIcon: Icons.alternate_email_rounded,
                              hintText: 'tu@email.com',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),
                      AuthStaggerEntrance(
                        delay: const Duration(milliseconds: 400),
                        child: BlocBuilder<RegisterFormBloc, RegisterFormState>(
                          buildWhen: (p, c) => p.password != c.password,
                          builder: (context, state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppFormField(
                                  label: 'Contraseña',
                                  value: state.password.value,
                                  onChanged: (v) => context
                                      .read<RegisterFormBloc>()
                                      .add(RegisterPasswordChanged(v)),
                                  errorText: state.password.isPure
                                      ? null
                                      : state.password.error?.message,
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  prefixIcon: Icons.lock_outline_rounded,
                                  onSubmitted: (_) => _onSubmit(context),
                                ),
                                PasswordStrengthMeter(
                                  password: state.password.value,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: Spacing.xxl),
                      AuthStaggerEntrance(
                        delay: const Duration(milliseconds: 480),
                        child: BlocBuilder<AuthBloc, AuthState>(
                          buildWhen: (previous, current) =>
                              current is AuthSubmitting ||
                              current is AuthLoading ||
                              current is AuthError ||
                              current is Unauthenticated ||
                              current is Authenticated,
                          builder: (context, authState) {
                            final authBusy =
                                authState is AuthSubmitting ||
                                authState is AuthLoading;
                            return BlocBuilder<
                              RegisterFormBloc,
                              RegisterFormState
                            >(
                              builder: (context, formState) {
                                final disabled =
                                    authBusy ||
                                    !formState.isValid ||
                                    formState.submissionStatus ==
                                        FormzSubmissionStatus.inProgress;
                                return KineticButton(
                                  label: 'REGISTRARSE',
                                  isLoading: authBusy,
                                  onTap: disabled
                                      ? null
                                      : () => _onSubmit(context),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: Spacing.lgPlus),
                      AuthStaggerEntrance(
                        delay: const Duration(milliseconds: 560),
                        child: TextButton(
                          onPressed: () => goToLogin(context),
                          child: RichText(
                            text: TextSpan(
                              style: textTheme.bodyMedium,
                              children: [
                                const TextSpan(text: '¿TIENES CUENTA? '),
                                TextSpan(
                                  text: 'INICIA SESIÓN',
                                  style: TextStyle(
                                    color: context.colors.primary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
