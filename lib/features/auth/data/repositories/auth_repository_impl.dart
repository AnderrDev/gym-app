import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> signInWithEmail(String email, String password) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteUser = await remoteDataSource.signInWithEmail(email, password);
        return Right(remoteUser);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message ?? 'Error al iniciar sesión'));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, User>> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteUser = await remoteDataSource.signUpWithEmail(email, password, fullName);
        return Right(remoteUser);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message ?? 'Error al registrarse'));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    // Para getCurrentUser, intentamos obtener el usuario actual.
    // Supabase permite obtener el usuario actual si la sesión está persistida incluso offline.
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
