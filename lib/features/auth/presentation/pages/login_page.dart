import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:formz/formz.dart';

import 'package:gym_flutter/core/forms/inputs/email.dart';
import 'package:gym_flutter/core/forms/inputs/password.dart';
import 'package:gym_flutter/core/presentation/widgets/glass_container.dart';
import 'package:gym_flutter/core/presentation/widgets/kinetic_button.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/core/ui/molecules/app_form_field.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/login_form/login_form_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/login_form/login_form_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/login_form/login_form_state.dart';
import 'package:gym_flutter/features/auth/presentation/widgets/auth_aura_background.dart';
import 'package:gym_flutter/features/auth/presentation/widgets/auth_stagger_entrance.dart';
import 'package:gym_flutter/features/auth/presentation/widgets/forgot_password_sheet.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginFormBloc>(
      create: (_) => LoginFormBloc(
        seedEmail: kDebugMode ? dotenv.maybeGet('DEV_LOGIN_EMAIL') : null,
        seedPassword: kDebugMode ? dotenv.maybeGet('DEV_LOGIN_PASSWORD') : null,
      ),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  void _onSubmit(BuildContext context) {
    final formState = context.read<LoginFormBloc>().state;
    if (!formState.isValid) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      SignInRequested(formState.email.value.trim(), formState.password.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
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
                      const AuthStaggerEntrance(
                        child: Icon(
                          Icons.bolt_rounded,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: Spacing.xl),
                      AuthStaggerEntrance(
                        delay: const Duration(milliseconds: 80),
                        child: Text(
                          'GYM TRACKER',
                          textAlign: TextAlign.center,
                          style: textTheme.displayMedium?.copyWith(
                            letterSpacing: 4,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      AuthStaggerEntrance(
                        delay: const Duration(milliseconds: 160),
                        child: Text(
                          'PRECISIÓN KINÉTICA',
                          textAlign: TextAlign.center,
                          style: textTheme.labelMedium?.copyWith(
                            letterSpacing: 2,
                            color: AppColors.primary.withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      AuthStaggerEntrance(
                        delay: const Duration(milliseconds: 240),
                        child: BlocBuilder<LoginFormBloc, LoginFormState>(
                          buildWhen: (p, c) => p.email != c.email,
                          builder: (context, state) {
                            return AppFormField(
                              label: 'Email',
                              value: state.email.value,
                              onChanged: (v) => context
                                  .read<LoginFormBloc>()
                                  .add(LoginEmailChanged(v)),
                              errorText: state.email.isPure
                                  ? null
                                  : state.email.error?.message,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              prefixIcon: Icons.alternate_email_rounded,
                              hintText: 'tu@email.com',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: Spacing.lgPlus),
                      AuthStaggerEntrance(
                        delay: const Duration(milliseconds: 320),
                        child: BlocBuilder<LoginFormBloc, LoginFormState>(
                          buildWhen: (p, c) => p.password != c.password,
                          builder: (context, state) {
                            return AppFormField(
                              label: 'Contraseña',
                              value: state.password.value,
                              onChanged: (v) => context
                                  .read<LoginFormBloc>()
                                  .add(LoginPasswordChanged(v)),
                              errorText: state.password.isPure
                                  ? null
                                  : state.password.error?.message,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              prefixIcon: Icons.lock_outline_rounded,
                              onSubmitted: (_) => _onSubmit(context),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      AuthStaggerEntrance(
                        delay: const Duration(milliseconds: 360),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              final email = context
                                  .read<LoginFormBloc>()
                                  .state
                                  .email
                                  .value;
                              ForgotPasswordSheet.show(
                                context,
                                initialEmail: email,
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              minimumSize: const Size(0, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: textTheme.labelMedium?.copyWith(
                                color:
                                    AppColors.primary.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),
                      AuthStaggerEntrance(
                        delay: const Duration(milliseconds: 400),
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
                            return BlocBuilder<LoginFormBloc, LoginFormState>(
                              builder: (context, formState) {
                                final disabled =
                                    authBusy ||
                                    !formState.isValid ||
                                    formState.submissionStatus ==
                                        FormzSubmissionStatus.inProgress;
                                return KineticButton(
                                  label: 'INICIAR SESIÓN',
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
                      const SizedBox(height: Spacing.xl),
                      AuthStaggerEntrance(
                        delay: const Duration(milliseconds: 480),
                        child: TextButton(
                          onPressed: () => goToRegister(context),
                          child: RichText(
                            text: TextSpan(
                              style: textTheme.bodyMedium,
                              children: const [
                                TextSpan(text: '¿NUEVO AQUÍ? '),
                                TextSpan(
                                  text: 'REGÍSTRATE',
                                  style: TextStyle(
                                    color: AppColors.primary,
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
