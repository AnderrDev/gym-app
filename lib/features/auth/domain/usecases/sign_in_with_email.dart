import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmail {
  final AuthRepository repository;

  SignInWithEmail(this.repository);

  Future<User> call(String email, String password) async {
    return await repository.signInWithEmail(email, password);
  }
}
