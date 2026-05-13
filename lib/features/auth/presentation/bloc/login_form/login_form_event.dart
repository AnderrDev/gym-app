import 'package:equatable/equatable.dart';

abstract class LoginFormEvent extends Equatable {
  const LoginFormEvent();

  @override
  List<Object?> get props => const [];
}

class LoginEmailChanged extends LoginFormEvent {
  const LoginEmailChanged(this.value);
  final String value;

  @override
  List<Object?> get props => [value];
}

class LoginPasswordChanged extends LoginFormEvent {
  const LoginPasswordChanged(this.value);
  final String value;

  @override
  List<Object?> get props => [value];
}
