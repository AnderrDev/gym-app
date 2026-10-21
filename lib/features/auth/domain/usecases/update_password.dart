import 'package:fpdart/fpdart.dart';

import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/auth/domain/repositories/auth_repository.dart';

/// Use case: fija la contraseña nueva tras abrir el enlace de recuperación.
class UpdatePassword {
  UpdatePassword(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, void>> call(String newPassword) =>
      repository.updatePassword(newPassword);
}
