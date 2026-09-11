import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gym_flutter/core/error/exceptions.dart';

/// Helper interno para invocar Edge Functions de Supabase de manera consistente:
/// refresca el token si hace falta, aplica un timeout, mapea los códigos de
/// error frecuentes a `WorkoutFunctionException` y devuelve `data` parseado.
///
/// Las funciones del proyecto comparten contrato `{ success: bool, code?: str,
/// data?: object }`; este wrapper centraliza esa convención.
class EdgeFunctionInvoker {
  EdgeFunctionInvoker({required this.client});

  final SupabaseClient client;

  static const Duration _timeout = Duration(seconds: 30);

  Future<String> _requireAccessToken() async {
    final current = client.auth.currentSession?.accessToken;
    if (current != null && current.isNotEmpty) return current;
    final refreshed = (await client.auth.refreshSession()).session?.accessToken;
    if (refreshed != null && refreshed.isNotEmpty) return refreshed;
    throw const WorkoutFunctionException(
      code: 'UNAUTHORIZED',
      userMessage: 'Tu sesión expiró. Inicia sesión nuevamente.',
    );
  }

  /// Invoca [functionName] con [body]. [errorCodePrefix] se usa para nombrar
  /// los códigos genéricos `${prefix}_FUNCTION_ERROR_$status` cuando la
  /// FunctionException no trae más detalle.
  Future<Map<String, dynamic>> invoke({
    required String functionName,
    required Map<String, dynamic> body,
    required String errorCodePrefix,
    required String genericErrorMessage,
    Map<int, WorkoutFunctionException> statusMappings = const {},
    Map<String, WorkoutFunctionException> codeMappings = const {},
  }) async {
    try {
      final token = await _requireAccessToken();
      final response = await client.functions
          .invoke(
            functionName,
            body: body,
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(
            _timeout,
            onTimeout: () => throw const WorkoutFunctionException(
              code: 'TIMEOUT',
              userMessage: 'La solicitud tardó demasiado. Intenta nuevamente.',
            ),
          );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final statusCode = response.status;
      final code = data['code']?.toString();
      final success = data['success'] == true;

      final mappedByStatus = statusMappings[statusCode];
      if (mappedByStatus != null) throw mappedByStatus;

      if (code != null) {
        final mappedByCode = codeMappings[code];
        if (mappedByCode != null) throw mappedByCode;
      }

      if (statusCode == 401 || code == 'UNAUTHORIZED') {
        throw const WorkoutFunctionException(
          code: 'UNAUTHORIZED',
          userMessage: 'Tu sesión expiró. Inicia sesión nuevamente.',
        );
      }

      if (!success || statusCode < 200 || statusCode >= 300) {
        throw WorkoutFunctionException(
          code: code ?? 'UNKNOWN_FUNCTION_ERROR',
          userMessage: genericErrorMessage,
        );
      }

      return data;
    } on WorkoutFunctionException {
      rethrow;
    } on FunctionException catch (e) {
      final status = e.status;
      final details = e.details?.toString() ?? e.toString();
      if (status == 401) {
        throw const WorkoutFunctionException(
          code: 'UNAUTHORIZED',
          userMessage: 'Tu sesión expiró (401). Inicia sesión nuevamente.',
        );
      }
      throw WorkoutFunctionException(
        code: '${errorCodePrefix}_FUNCTION_ERROR_$status',
        userMessage: 'Error del servidor ($status): $details',
      );
    } catch (e) {
      throw WorkoutFunctionException(
        code: '${errorCodePrefix}_RUNTIME_ERROR',
        userMessage: 'No se pudo conectar con el servidor: $e',
      );
    }
  }
}
