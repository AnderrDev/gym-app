import 'package:fpdart/fpdart.dart';

import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/profile/domain/repositories/profile_repository.dart';

/// Palabra que el usuario debe escribir para confirmar la eliminación. El
/// servidor (`delete_account_v1`) exige exactamente el mismo valor.
const String deleteAccountConfirmationWord = 'ELIMINAR';

/// Use case: elimina la cuenta del usuario en el servidor.
///
/// Valida la confirmación antes de llamar al repositorio para no gastar una
/// llamada (ni rate limit) con un texto que el servidor rechazaría.
class DeleteAccount {
  DeleteAccount(this.repository);

  final ProfileRepository repository;

  Future<Either<Failure, void>> call({required String confirmation}) async {
    final normalized = confirmation.trim();
    if (normalized != deleteAccountConfirmationWord) {
      return const Left(
        ValidationFailure(
          'Escribe $deleteAccountConfirmationWord para confirmar.',
        ),
      );
    }
    return repository.deleteAccount(confirmation: normalized);
  }
}
