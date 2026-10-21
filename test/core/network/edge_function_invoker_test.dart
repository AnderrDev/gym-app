import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gym_flutter/core/error/exceptions.dart';
import 'package:gym_flutter/core/network/edge_function_invoker.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockSession extends Mock implements Session {}

class _MockFunctionsClient extends Mock implements FunctionsClient {}

/// Los 404 no son todos iguales: el de la función ("la sesión ya se cerró")
/// se descarta en el SyncWorker; el del gateway ("la función no existe") hay
/// que reintentarlo.
void main() {
  late _MockFunctionsClient functions;
  late EdgeFunctionInvoker invoker;

  setUp(() {
    final client = _MockSupabaseClient();
    final auth = _MockGoTrueClient();
    final session = _MockSession();
    functions = _MockFunctionsClient();
    when(() => client.auth).thenReturn(auth);
    when(() => client.functions).thenReturn(functions);
    when(() => auth.currentSession).thenReturn(session);
    when(() => session.accessToken).thenReturn('token');
    invoker = EdgeFunctionInvoker(client: client);
  });

  Future<WorkoutFunctionException> invokeThrowing(
    FunctionException error,
  ) async {
    when(
      () => functions.invoke(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
      ),
    ).thenThrow(error);
    try {
      await invoker.invoke(
        functionName: 'finalize_workout_session_v1',
        body: const {'session_id': 's1'},
        errorCodePrefix: 'FINALIZE',
        genericErrorMessage: 'No se pudo finalizar.',
        statusMappings: const {
          404: WorkoutFunctionException(
            code: 'NOT_FOUND_OR_ALREADY_COMPLETED',
            userMessage: 'Ya finalizada o inexistente.',
          ),
        },
        codeMappings: const {
          'NOT_FOUND_OR_COMPLETED': WorkoutFunctionException(
            code: 'NOT_FOUND_OR_COMPLETED',
            userMessage: 'Ya finalizada o inexistente.',
          ),
          'NOT_FOUND_OR_ALREADY_COMPLETED': WorkoutFunctionException(
            code: 'NOT_FOUND_OR_ALREADY_COMPLETED',
            userMessage: 'Ya finalizada o inexistente.',
          ),
        },
      );
    } on WorkoutFunctionException catch (e) {
      return e;
    }
    fail('Se esperaba WorkoutFunctionException');
  }

  test('404 de la función con su código → código del contrato', () async {
    final e = await invokeThrowing(
      const FunctionException(
        status: 404,
        details: {'success': false, 'code': 'NOT_FOUND_OR_ALREADY_COMPLETED'},
      ),
    );
    expect(e.code, 'NOT_FOUND_OR_ALREADY_COMPLETED');
  });

  test('404 con el código real del servidor → código del contrato', () async {
    final e = await invokeThrowing(
      const FunctionException(
        status: 404,
        details: {'success': false, 'code': 'NOT_FOUND_OR_COMPLETED'},
      ),
    );
    expect(e.code, 'NOT_FOUND_OR_COMPLETED');
  });

  test('404 del gateway (función no desplegada) → error genérico', () async {
    final e = await invokeThrowing(
      const FunctionException(
        status: 404,
        details: {
          'code': 'NOT_FOUND',
          'message': 'Requested function was not found',
        },
      ),
    );
    expect(e.code, 'FINALIZE_FUNCTION_ERROR_404');
  });

  test('404 sin body → se usa el mapeo por status', () async {
    final e = await invokeThrowing(const FunctionException(status: 404));
    expect(e.code, 'NOT_FOUND_OR_ALREADY_COMPLETED');
  });
}
