import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:gym_flutter/core/error/exceptions.dart';

abstract class ProfileRemoteDataSource {
  /// Actualiza el `full_name` del profile del user autenticado. Devuelve el
  /// nombre actualizado (tal cual lo guardó la DB).
  Future<String?> updateFullName(String userId, String fullName);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl({required this.client});

  final supabase.SupabaseClient client;

  @override
  Future<String?> updateFullName(String userId, String fullName) async {
    try {
      // Update doble: profiles.full_name (canónico) y auth.users metadata
      // (para que el JWT lo refleje y siguientes sign-ins lo restituyan).
      final updated = await client
          .from('profiles')
          .update({'full_name': fullName})
          .eq('id', userId)
          .select('full_name')
          .single();
      try {
        await client.auth.updateUser(
          supabase.UserAttributes(data: {'full_name': fullName}),
        );
      } catch (_) {
        // No bloqueamos si la actualización de metadata falla; el dato
        // canónico está en profiles.
      }
      return updated['full_name'] as String?;
    } on supabase.PostgrestException catch (e) {
      throw ServerException('updateFullName failed: ${e.message}');
    } catch (e) {
      throw ServerException('updateFullName failed: $e');
    }
  }
}
