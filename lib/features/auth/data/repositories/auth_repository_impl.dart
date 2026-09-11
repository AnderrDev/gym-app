import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Stream<bool> get authStateChanges => remoteDataSource.authStateChanges;

  @override
  Future<Either<Failure, User>> signInWithEmail(
    String email,
    String password,
  ) {
    return guard(() async {
      final remoteUser = await remoteDataSource.signInWithEmail(
        email,
        password,
      );
      await localDataSource.cacheUser(remoteUser);
      return remoteUser.toEntity();
    });
  }

  @override
  Future<Either<Failure, User>> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) {
    return guard(() async {
      final remoteUser = await remoteDataSource.signUpWithEmail(
        email,
        password,
        fullName,
      );
      await localDataSource.cacheUser(remoteUser);
      return remoteUser.toEntity();
    });
  }

  @override
  Future<Either<Failure, void>> signOut() {
    return guard(() async {
      await remoteDataSource.signOut();
      await localDataSource.clearCache();
    });
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      if (user != null) {
        await localDataSource.cacheUser(user);
      }
      return Right(user?.toEntity());
    } catch (_) {
      // Fallback a SharedPreferences si Supabase falla (token caducado, etc.)
      final cachedUser = await localDataSource.getLastCachedUser();
      return Right(cachedUser?.toEntity());
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) {
    return guard(() => remoteDataSource.sendPasswordResetEmail(email));
  }
}
