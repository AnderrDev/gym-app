import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case: pide a Supabase mandar el email de reset al `email` indicado.
/// El resultado `Right(null)` solo significa que la petición fue aceptada,
/// no que existe la cuenta (Supabase oculta esa info por seguridad).
class RequestPasswordReset {
  final AuthRepository repository;

  RequestPasswordReset(this.repository);

  Future<Either<Failure, void>> call(String email) =>
      repository.sendPasswordResetEmail(email);
}
