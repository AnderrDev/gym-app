import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<User> signInWithEmail(String email, String password) async {
    return await remoteDataSource.signInWithEmail(email, password);
  }

  @override
  Future<User> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    return await remoteDataSource.signUpWithEmail(email, password, fullName);
  }

  @override
  Future<void> signOut() async {
    await remoteDataSource.signOut();
  }

  @override
  Future<User?> getCurrentUser() async {
    return await remoteDataSource.getCurrentUser();
  }
}
