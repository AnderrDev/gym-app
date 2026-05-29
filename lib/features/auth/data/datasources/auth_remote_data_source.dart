import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:gym_flutter/core/error/exceptions.dart';
import 'package:gym_flutter/core/observability/app_logger.dart';

import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> signUpWithEmail(
    String email,
    String password,
    String fullName,
  );
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<void> sendPasswordResetEmail(String email);

  /// Domain-level stream: `true` when an authenticated session is active.
  /// Filters Supabase events down to the ones that affect auth state
  /// (initialSession, signedIn, userUpdated, signedOut) so consumers in
  /// upper layers don't depend on the SDK enum.
  Stream<bool> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final supabase.SupabaseClient client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Stream<bool> get authStateChanges => client.auth.onAuthStateChange
      .where(
        (data) =>
            data.event == supabase.AuthChangeEvent.initialSession ||
            data.event == supabase.AuthChangeEvent.signedIn ||
            data.event == supabase.AuthChangeEvent.userUpdated ||
            data.event == supabase.AuthChangeEvent.signedOut,
      )
      .map((data) => data.session != null);

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    final supabase.AuthResponse response;
    try {
      response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw ServerException('signIn failed: $e');
    }
    final user = response.user;
    if (user == null) {
      throw AuthException('No se pudo iniciar sesión.');
    }

    // Best-effort upsert del perfil. Si falla, lo logueamos como warning
    // y seguimos — el sign-in sigue siendo válido.
    final metaFullName = user.userMetadata?['full_name'] as String?;
    if (metaFullName != null) {
      try {
        await client.from('profiles').upsert({
          'id': user.id,
          'full_name': metaFullName,
        });
      } catch (e) {
        AppLogger.instance.warning(
          'profiles upsert (signIn) falló para ${user.id}: $e',
        );
      }
    }

    // user.email puede venir null en flujos OTP/admin import: caemos al param
    // recibido (que es el email con el que se autenticó).
    return _getUserProfile(user.id, user.email ?? email);
  }

  @override
  Future<UserModel> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    final supabase.AuthResponse response;
    try {
      response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw ServerException('signUp failed: $e');
    }
    final user = response.user;
    if (user == null) {
      throw AuthException('No se pudo registrar la cuenta.');
    }

    try {
      // Intentamos insertar/actualizar el perfil. Si la confirmación de email
      // está habilitada, esto puede fallar por RLS porque aún no hay sesión.
      // En ese caso lo retomamos en signIn.
      await client.from('profiles').upsert({
        'id': user.id,
        'full_name': fullName,
      });
    } catch (e) {
      AppLogger.instance.warning(
        'profiles upsert (signUp) falló para ${user.id}: $e',
      );
    }

    return UserModel(
      id: user.id,
      email: user.email ?? email,
      fullName: fullName,
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw ServerException('signOut failed: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    // currentUser puede ser null en arranque frío antes del initialSession.
    // Usamos currentSession?.user como fallback (misma sesión en memoria).
    final user = client.auth.currentUser ?? client.auth.currentSession?.user;
    if (user == null) return null;
    return _getUserProfile(user.id, user.email ?? '');
  }

  Future<UserModel> _getUserProfile(String userId, String email) async {
    try {
      final profileData = await client
          .from('profiles')
          .select('id, full_name')
          .eq('id', userId)
          .maybeSingle();

      return UserModel(
        id: userId,
        email: email,
        fullName: profileData?['full_name'] as String?,
      );
    } catch (e) {
      AppLogger.instance.warning(
        'getUserProfile fallback (sin full_name) para $userId: $e',
      );
      return UserModel(id: userId, email: email);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw ServerException('resetPassword failed: $e');
    }
  }
}
