import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'exceptions.dart';
import 'failures.dart';

/// Maps any thrown object into a typed [Failure]. Centralizing this avoids
/// the 30+ `catch (e) { return Left(ServerFailure(e.toString())) }` blocks
/// scattered across repositories that lose the original exception's
/// semantics (auth vs network vs validation vs server) and leak raw error
/// strings into the UI.
Failure mapToFailure(Object error) {
  if (error is Failure) return error;

  if (error is AuthException) return AuthFailure(error.message);
  if (error is supabase.AuthException) return AuthFailure(error.message);

  if (error is supabase.PostgrestException) {
    final code = error.code;
    if (code == 'PGRST116' || code == 'PGRST106') {
      return NotFoundFailure(error.message);
    }
    if (code == '23505') return ConflictFailure(error.message);
    return ServerFailure(error.message);
  }

  if (error is NotFoundException) {
    return NotFoundFailure(error.message ?? 'Recurso no encontrado');
  }
  if (error is ConflictException) {
    return ConflictFailure(error.message ?? 'Conflicto en el servidor');
  }
  if (error is ValidationException) return ValidationFailure(error.message);

  if (error is WorkoutFunctionException) {
    switch (error.code) {
      case 'NOT_FOUND_OR_ALREADY_COMPLETED':
      case 'NOT_FOUND_OR_COMPLETED':
      case 'SESSION_NOT_FOUND':
        return NotFoundFailure(error.userMessage);
      case 'VALIDATION_ERROR':
      case 'INVALID_JSON':
      case 'INVALID_INSIGHTS_PAYLOAD':
      case 'COACHING_TOO_LARGE':
        return ValidationFailure(error.userMessage);
      case 'UNAUTHORIZED':
        return AuthFailure(error.userMessage);
      case 'TIMEOUT':
        return const NetworkFailure('La solicitud tardó demasiado.');
      case 'RATE_LIMIT_EXCEEDED':
        return ServerFailure(error.userMessage);
      default:
        return ServerFailure(error.userMessage);
    }
  }

  if (error is NetworkException) return const NetworkFailure();
  if (error is SocketException) return const NetworkFailure();
  if (error is TimeoutException) {
    return const NetworkFailure('La solicitud tardó demasiado.');
  }

  if (error is ServerException) {
    return ServerFailure(error.message ?? 'Error del servidor');
  }

  return ServerFailure(error.toString());
}

/// Wraps an async operation, returning `Right(value)` on success or
/// `Left(Failure)` on any throw. Use this in repository implementations
/// to keep them small and consistent.
Future<Either<Failure, T>> guard<T>(Future<T> Function() body) async {
  try {
    final result = await body();
    return Right(result);
  } catch (e) {
    return Left(mapToFailure(e));
  }
}
