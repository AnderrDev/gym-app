import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthSubmitting extends AuthState {}

final class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

final class Unauthenticated extends AuthState {}

/// Registro correcto pero sin sesión: el proyecto exige confirmar el email.
/// Antes caía en `Unauthenticated` sin ningún aviso.
final class AuthAwaitingEmailConfirmation extends AuthState {
  final String email;

  const AuthAwaitingEmailConfirmation(this.email);

  @override
  List<Object?> get props => [email];
}

final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
