// Excepciones que el data layer puede lanzar antes del mapeo a `Failure`.
// Cualquier `try/catch` en repositorios debe distinguir explícitamente
// entre estos tipos para emitir el `Failure` correcto.

/// Error genérico del backend (5xx, JSON inválido, network puro).
class ServerException implements Exception {
  ServerException([this.message]);
  final String? message;

  @override
  String toString() => 'ServerException: ${message ?? 'unknown'}';
}

/// Cache local corrupto o inaccesible.
class CacheException implements Exception {}

/// Sin conectividad de red.
class NetworkException implements Exception {}

/// Validación de input rechazada (formato, rango, dependencia).
class ValidationException implements Exception {
  ValidationException(this.message);
  final String message;

  @override
  String toString() => 'ValidationException: $message';
}

/// Credenciales inválidas, sesión expirada, o reglas de Auth (Supabase).
class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// El recurso solicitado no existe en el backend.
class NotFoundException implements Exception {
  NotFoundException([this.message]);
  final String? message;

  @override
  String toString() => 'NotFoundException: ${message ?? 'unknown'}';
}

/// Conflicto: el recurso ya existe o hay otra mutación concurrente.
class ConflictException implements Exception {
  ConflictException([this.message]);
  final String? message;

  @override
  String toString() => 'ConflictException: ${message ?? 'unknown'}';
}

/// Error semántico devuelto por una Edge Function de Supabase (status no-2xx
/// o `success: false` en el body). [code] es el código estable del contrato
/// (`SESSION_NOT_FOUND`, `UNAUTHORIZED`, `VALIDATION_ERROR`, ...); el bloc/UI
/// puede ramificar por código en lugar de parsear el mensaje.
class WorkoutFunctionException implements Exception {
  const WorkoutFunctionException({required this.code, required this.userMessage});
  final String code;
  final String userMessage;

  @override
  String toString() => 'WorkoutFunctionException($code): $userMessage';
}
