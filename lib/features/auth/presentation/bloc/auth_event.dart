import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AppStarted extends AuthEvent {}

class AuthStateChanged extends AuthEvent {
  final bool isAuthenticated;
  
  const AuthStateChanged({required this.isAuthenticated});
  
  @override
  List<Object> get props => [isAuthenticated];
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;

  const SignUpRequested(this.email, this.password, this.fullName);

  @override
  List<Object> get props => [email, password, fullName];
}

class SignOutRequested extends AuthEvent {}
