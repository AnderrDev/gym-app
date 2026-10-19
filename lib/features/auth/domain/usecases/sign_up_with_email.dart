import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignUpWithEmail {
  final AuthRepository repository;

  SignUpWithEmail(this.repository);

  Future<Either<Failure, User>> call(
    String email,
    String password,
    String fullName,
  ) async {
    return await repository.signUpWithEmail(email, password, fullName);
  }
}
