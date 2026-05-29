import 'package:equatable/equatable.dart';

abstract class RegisterFormEvent extends Equatable {
  const RegisterFormEvent();

  @override
  List<Object?> get props => const [];
}

class RegisterFullNameChanged extends RegisterFormEvent {
  const RegisterFullNameChanged(this.value);
  final String value;

  @override
  List<Object?> get props => [value];
}

class RegisterEmailChanged extends RegisterFormEvent {
  const RegisterEmailChanged(this.value);
  final String value;

  @override
  List<Object?> get props => [value];
}

class RegisterPasswordChanged extends RegisterFormEvent {
  const RegisterPasswordChanged(this.value);
  final String value;

  @override
  List<Object?> get props => [value];
}
