import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signInWithEmail(String email, String password);
  Future<Either<Failure, User>> signUpWithEmail(
    String email,
    String password,
    String fullName,
  );
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, User?>> getCurrentUser();

  /// Dispara el envío del email de recuperación. Supabase responde sin
  /// distinguir si el email existe (anti-enumeración), así que un Right
  /// no garantiza que haya cuenta — solo que la petición fue aceptada.
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Emits `true` when an authenticated session is active, `false` otherwise.
  /// Includes the initial restored-from-storage session, so subscribers get
  /// the bootstrap state without polling.
  Stream<bool> get authStateChanges;
}
