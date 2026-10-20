import 'package:fpdart/fpdart.dart';

import 'package:gym_flutter/core/error/failures.dart';

abstract class ProfileRepository {
  /// Actualiza el nombre completo del user. Devuelve el nombre persistido
  /// para que el caller refresque su modelo local.
  Future<Either<Failure, String?>> updateFullName({
    required String userId,
    required String fullName,
  });

  /// Elimina en el servidor la cuenta del user autenticado: borra sus datos,
  /// anonimiza sus rutinas públicas y borra el usuario de Auth. No toca el
  /// estado local (eso lo orquesta la capa de presentación tras el éxito).
  Future<Either<Failure, void>> deleteAccount({required String confirmation});
}
