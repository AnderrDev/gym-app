import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_local_data_source.dart';

// NetworkInfo desactivado temporalmente — todo va a Supabase directo

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, User>> signInWithEmail(String email, String password) async {
    try {
      final remoteUser = await remoteDataSource.signInWithEmail(email, password);
      await localDataSource.cacheUser(remoteUser);
      return Right(remoteUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error al iniciar sesión'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final remoteUser = await remoteDataSource.signUpWithEmail(email, password, fullName);
      await localDataSource.cacheUser(remoteUser);
      return Right(remoteUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error al registrarse'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      await localDataSource.clearCache();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      if (user != null) {
        await localDataSource.cacheUser(user);
      }
      return Right(user);
    } catch (e) {
      // Fallback a SharedPreferences si Supabase falla (token caducado, etc.)
      final cachedUser = await localDataSource.getLastCachedUser();
      return Right(cachedUser);
    }
  }
}
