import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/forms/form_bloc_base.dart';
import 'package:gym_flutter/core/forms/inputs/email.dart';
import 'package:gym_flutter/core/forms/inputs/password.dart';
import 'package:gym_flutter/core/forms/inputs/required_text.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/register_form/register_form_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/register_form/register_form_state.dart';

class RegisterFormBloc
    extends FormBlocBase<RegisterFormEvent, RegisterFormState> {
  RegisterFormBloc() : super(RegisterFormState()) {
    on<RegisterFullNameChanged>(_onFullNameChanged);
    on<RegisterEmailChanged>(_onEmailChanged);
    on<RegisterPasswordChanged>(_onPasswordChanged);
  }

  void _onFullNameChanged(
    RegisterFullNameChanged event,
    Emitter<RegisterFormState> emit,
  ) {
    emit(
      state.copyWith(fullName: RequiredText.dirty(event.value, minLength: 2)),
    );
  }

  void _onEmailChanged(
    RegisterEmailChanged event,
    Emitter<RegisterFormState> emit,
  ) {
    emit(state.copyWith(email: Email.dirty(event.value)));
  }

  void _onPasswordChanged(
    RegisterPasswordChanged event,
    Emitter<RegisterFormState> emit,
  ) {
    emit(state.copyWith(password: Password.dirty(event.value)));
  }
}
