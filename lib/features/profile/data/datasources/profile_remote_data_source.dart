import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:gym_flutter/core/error/exceptions.dart';
import 'package:gym_flutter/core/network/edge_function_invoker.dart';
import 'package:gym_flutter/core/observability/app_logger.dart';

abstract class ProfileRemoteDataSource {
  /// Actualiza el `full_name` del profile del user autenticado. Devuelve el
  /// nombre actualizado (tal cual lo guardó la DB).
  Future<String?> updateFullName(String userId, String fullName);

  /// Elimina la cuenta del user autenticado vía la Edge Function
  /// `delete_account_v1`. [confirmation] viaja como `confirm` y el servidor
  /// exige que sea exactamente `ELIMINAR`. Lanza [WorkoutFunctionException]
  /// con el código del contrato si el servidor la rechaza.
  Future<void> deleteAccount({required String confirmation});
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl({required this.client})
    : _invoker = EdgeFunctionInvoker(client: client);

  final supabase.SupabaseClient client;
  final EdgeFunctionInvoker _invoker;

  static const String deleteAccountFunction = 'delete_account_v1';

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

  @override
  Future<void> deleteAccount({required String confirmation}) async {
    final response = await _invoker.invoke(
      functionName: deleteAccountFunction,
      body: {'confirm': confirmation},
      errorCodePrefix: 'DELETE_ACCOUNT',
      genericErrorMessage:
          'No se pudo eliminar tu cuenta. Inténtalo de nuevo en unos minutos.',
      codeMappings: const {
        'CONFIRMATION_REQUIRED': WorkoutFunctionException(
          code: 'VALIDATION_ERROR',
          userMessage: 'Escribe ELIMINAR para confirmar.',
        ),
        'RATE_LIMIT_EXCEEDED': WorkoutFunctionException(
          code: 'RATE_LIMIT_EXCEEDED',
          userMessage:
              'Demasiados intentos. Espera un minuto y vuelve a intentarlo.',
        ),
        // La RPC es transaccional: si falla no se borró nada.
        'DELETE_ACCOUNT_DATA_ERROR': WorkoutFunctionException(
          code: 'DELETE_ACCOUNT_DATA_ERROR',
          userMessage:
              'No se pudo eliminar tu cuenta y tus datos siguen intactos. '
              'Inténtalo de nuevo.',
        ),
        // Datos ya borrados pero el usuario de Auth sigue: reintentar es
        // seguro (todo el flujo es idempotente).
        'DELETE_AUTH_USER_ERROR': WorkoutFunctionException(
          code: 'DELETE_AUTH_USER_ERROR',
          userMessage:
              'No se pudo terminar de eliminar tu cuenta. Inténtalo de nuevo.',
        ),
      },
    );
    final data = response['data'];
    AppLogger.instance.info(
      'delete_account_v1 ok: ${data is Map ? data['deleted'] : '-'}',
    );
  }
}
