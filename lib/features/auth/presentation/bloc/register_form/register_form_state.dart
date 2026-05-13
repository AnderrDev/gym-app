import 'package:formz/formz.dart';

import 'package:gym_flutter/core/forms/form_bloc_base.dart';
import 'package:gym_flutter/core/forms/inputs/email.dart';
import 'package:gym_flutter/core/forms/inputs/password.dart';
import 'package:gym_flutter/core/forms/inputs/required_text.dart';

class RegisterFormState extends FormStateBase {
  RegisterFormState({
    this.fullName = const RequiredText.pure(minLength: 2),
    this.email = const Email.pure(),
    this.password = const Password.pure(),
    super.submissionStatus,
    super.errorMessage,
  }) : super(inputs: [fullName, email, password]);

  final RequiredText fullName;
  final Email email;
  final Password password;

  RegisterFormState copyWith({
    RequiredText? fullName,
    Email? email,
    Password? password,
    FormzSubmissionStatus? submissionStatus,
    String? errorMessage,
  }) {
    return RegisterFormState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
