import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/forms/form_bloc_base.dart';
import 'package:gym_flutter/core/forms/inputs/email.dart';
import 'package:gym_flutter/core/forms/inputs/password.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/login_form/login_form_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/login_form/login_form_state.dart';

/// Mantiene los inputs validados de la pantalla de login. La submisión real
/// la hace la página llamando a `AuthBloc.add(SignInRequested(...))` cuando
/// `state.isValid`.
class LoginFormBloc extends FormBlocBase<LoginFormEvent, LoginFormState> {
  LoginFormBloc({String? seedEmail, String? seedPassword})
    : super(
        LoginFormState(
          email: (seedEmail == null || seedEmail.isEmpty)
              ? const Email.pure()
              : Email.dirty(seedEmail),
          password: (seedPassword == null || seedPassword.isEmpty)
              ? const Password.pure()
              : Password.dirty(seedPassword),
        ),
      ) {
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
  }

  void _onEmailChanged(LoginEmailChanged event, Emitter<LoginFormState> emit) {
    emit(state.copyWith(email: Email.dirty(event.value)));
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginFormState> emit,
  ) {
    emit(state.copyWith(password: Password.dirty(event.value)));
  }
}
