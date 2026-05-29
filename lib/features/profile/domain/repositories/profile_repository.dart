import 'package:fpdart/fpdart.dart';

import 'package:gym_flutter/core/error/failures.dart';

abstract class ProfileRepository {
  /// Actualiza el nombre completo del user. Devuelve el nombre persistido
  /// para que el caller refresque su modelo local.
  Future<Either<Failure, String?>> updateFullName({
    required String userId,
    required String fullName,
  });
}
