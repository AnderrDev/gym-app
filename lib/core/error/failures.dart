import 'package:equatable/equatable.dart';

/// `Failure` es el tipo Left de los `Either<Failure, T>` que devuelven los
/// repositorios. El bloc/UI consume `failure.message` para mostrar al usuario.
/// Cuando lo necesite, puede `is`-check contra subclases para reaccionar
/// distinto (p.ej. mostrar pantalla de login al `AuthFailure`).
abstract class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error del servidor']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Error de caché local']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión a internet']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Datos inválidos']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Error de autenticación']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso no encontrado']);
}

class ConflictFailure extends Failure {
  const ConflictFailure([super.message = 'Conflicto en el servidor']);
}
