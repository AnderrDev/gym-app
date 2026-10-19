import 'package:formz/formz.dart';

import 'package:gym_flutter/core/forms/form_bloc_base.dart';
import 'package:gym_flutter/core/forms/inputs/email.dart';
import 'package:gym_flutter/core/forms/inputs/password.dart';

class LoginFormState extends FormStateBase {
  LoginFormState({
    this.email = const Email.pure(),
    this.password = const Password.pure(),
    super.submissionStatus,
    super.errorMessage,
  }) : super(inputs: [email, password]);

  final Email email;
  final Password password;

  LoginFormState copyWith({
    Email? email,
    Password? password,
    FormzSubmissionStatus? submissionStatus,
    String? errorMessage,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
