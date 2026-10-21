import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:gym_flutter/core/config/deep_links.dart';
import 'package:gym_flutter/core/error/exceptions.dart';
import 'package:gym_flutter/core/error/user_messages.dart';
import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:gym_flutter/core/routes/app_routes.dart';

import 'package:gym_flutter/features/auth/data/datasources/password_recovery_buffer.dart';

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

  /// Cambia la contraseña del usuario de la sesión actual (la que abre el
  /// enlace de recuperación).
  Future<void> updatePassword(String newPassword);

  /// Emite cuando el usuario vuelve desde el enlace de recuperación de
  /// contraseña (`AuthChangeEvent.passwordRecovery`). Si el evento llegó
  /// antes de que nadie escuchara (arranque en frío desde el deep link), se
  /// entrega al primer oyente — ver [PasswordRecoveryBuffer].
  Stream<void> get passwordRecoveryEvents;

  /// Domain-level stream: `true` when an authenticated session is active.
  /// Filters Supabase events down to the ones that affect auth state
  /// (initialSession, signedIn, passwordRecovery, userUpdated, signedOut) so
  /// consumers in upper layers don't depend on the SDK enum.
  Stream<bool> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final supabase.SupabaseClient client;

  /// Se suscribe a los eventos de recovery en el constructor (no en el
  /// getter) para no perder el que emite `supabase_flutter` durante el
  /// arranque. Por eso DI instancia este datasource en cuanto lo registra.
  AuthRemoteDataSourceImpl({required this.client})
    : _recovery = PasswordRecoveryBuffer(
        client.auth.onAuthStateChange
            .where(
              (data) => data.event == supabase.AuthChangeEvent.passwordRecovery,
            )
            .map((_) {}),
      );

  final PasswordRecoveryBuffer _recovery;

  @override
  Stream<bool> get authStateChanges => client.auth.onAuthStateChange
      .where(
        (data) =>
            data.event == supabase.AuthChangeEvent.initialSession ||
            data.event == supabase.AuthChangeEvent.signedIn ||
            // El canje del enlace de recuperación deja una sesión pero emite
            // `passwordRecovery` en vez de `signedIn`: sin él, `AuthBloc` no
            // pasaría a `Authenticated` y `ResetPasswordPage` diría que el
            // enlace no vale.
            data.event == supabase.AuthChangeEvent.passwordRecovery ||
            data.event == supabase.AuthChangeEvent.userUpdated ||
            data.event == supabase.AuthChangeEvent.signedOut,
      )
      .map((data) => data.session != null);

  @override
  Stream<void> get passwordRecoveryEvents => _recovery.events;

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    final supabase.AuthResponse response;
    try {
      response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on supabase.AuthException catch (e) {
      if (e is supabase.AuthRetryableFetchException) throw NetworkException();
      throw AuthException(authErrorMessage(e));
    } catch (e) {
      _throwUnexpected('signIn', e);
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
      if (e is supabase.AuthRetryableFetchException) throw NetworkException();
      throw AuthException(authErrorMessage(e));
    } catch (e) {
      _throwUnexpected('signUp', e);
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
      if (e is supabase.AuthRetryableFetchException) throw NetworkException();
      throw AuthException(authErrorMessage(e));
    } catch (e) {
      _throwUnexpected('signOut', e);
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
      // El enlace tiene que volver al mismo sitio que lo pidió: el flujo es
      // PKCE y el code verifier vive en ese navegador/dispositivo. En web,
      // a `/reset-password` de esta misma app; en móvil, al deep link propio
      // (lo canjea `supabase_flutter` y `AppRouter` navega con el evento
      // `passwordRecovery`). Ambas URLs deben estar en Supabase → Auth →
      // Redirect URLs o Supabase cae a la Site URL.
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb
            ? '${Uri.base.origin}${AppRoutes.resetPassword}'
            : DeepLinks.resetPassword,
      );
    } on supabase.AuthException catch (e) {
      if (e is supabase.AuthRetryableFetchException) throw NetworkException();
      throw AuthException(authErrorMessage(e));
    } catch (e) {
      _throwUnexpected('resetPassword', e);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await client.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );
    } on supabase.AuthException catch (e) {
      if (e is supabase.AuthRetryableFetchException) throw NetworkException();
      throw AuthException(authErrorMessage(e));
    } catch (e) {
      _throwUnexpected('updatePassword', e);
    }
  }
}

/// Errores fuera de `AuthException`: sin red el SDK lanza `ClientException`
/// / `SocketException` / timeout. Antes se envolvían como
/// `ServerException('signIn failed: ClientException…')` y ese texto llegaba
/// a la pantalla de login.
Never _throwUnexpected(String operation, Object error) {
  AppLogger.instance.warning('$operation failed: $error');
  if (error is http.ClientException ||
      error is SocketException ||
      error is TimeoutException) {
    throw NetworkException();
  }
  throw ServerException(genericErrorMessage);
}
