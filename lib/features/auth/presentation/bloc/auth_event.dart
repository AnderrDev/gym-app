import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

final class AppStarted extends AuthEvent {}

final class AuthStateChanged extends AuthEvent {
  final bool isAuthenticated;

  const AuthStateChanged({required this.isAuthenticated});

  @override
  List<Object> get props => [isAuthenticated];
}

final class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

final class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;

  const SignUpRequested(this.email, this.password, this.fullName);

  @override
  List<Object> get props => [email, password, fullName];
}

final class SignOutRequested extends AuthEvent {}

/// Notifica que el profile del user fue editado (típicamente desde la
/// pestaña PERFIL). Permite refrescar el `User` global sin re-pedir el
/// `getCurrentUser` al backend.
final class UserProfileUpdated extends AuthEvent {
  final String? fullName;

  const UserProfileUpdated({this.fullName});

  @override
  List<Object> get props => [fullName ?? ''];
}
