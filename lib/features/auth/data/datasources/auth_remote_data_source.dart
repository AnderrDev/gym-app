import 'package:supabase_flutter/supabase_flutter.dart';
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
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Login failed');
    }
    final user = response.user!;

    // Verificamos si podemos sincronizar el profile desde el Auth metadata en caso
    // de que el trigger en base de datos no exista o la inserción del signup fallara.
    final metaFullName = user.userMetadata?['full_name'] as String?;
    if (metaFullName != null) {
      try {
        await client.from('profiles').upsert({
          'id': user.id,
          'full_name': metaFullName,
        });
      } catch (_) {
        // Ignorar falla de upsert si el perfil ya existe
      }
    }

    return await _getUserProfile(user.id, user.email!);
  }

  @override
  Future<UserModel> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    if (response.user == null) {
      throw Exception('Registration failed');
    }

    try {
      // Intentamos insertar o actualizar el perfil de inmediato.
      // Si la confirmación de email está habilitada en Supabase, esto fallará
      // por RLS porque la sesión no ha sido iniciada.
      // Si está deshabilitada, insertará el registro con éxito.
      await client.from('profiles').upsert({
        'id': response.user!.id,
        'full_name': fullName,
      });
    } catch (_) {
      // Ignorar el error (normalmente falla por RLS si no hay sesión).
      // Actualizaremos el perfil cuando el usuario inicie sesión en signInWithEmail.
    }

    return UserModel(
      id: response.user!.id,
      email: response.user!.email!,
      fullName: fullName,
    );
  }

  @override
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    // currentUser puede ser null en arranque frío antes del initialSession.
    // Usamos currentSession?.user como fallback (misma sesión en memoria).
    final user = client.auth.currentUser ?? client.auth.currentSession?.user;
    if (user == null) return null;
    return await _getUserProfile(user.id, user.email ?? '');
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
      // Return basic user if profile fails
      return UserModel(id: userId, email: email);
    }
  }
}
