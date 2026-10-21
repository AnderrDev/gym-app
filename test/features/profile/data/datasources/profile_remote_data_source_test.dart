import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gym_flutter/core/error/exceptions.dart';
import 'package:gym_flutter/features/profile/data/datasources/profile_remote_data_source.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockSession extends Mock implements Session {}

class _MockFunctionsClient extends Mock implements FunctionsClient {}

void main() {
  late _MockSupabaseClient client;
  late _MockFunctionsClient functions;
  late ProfileRemoteDataSourceImpl dataSource;

  setUp(() {
    client = _MockSupabaseClient();
    functions = _MockFunctionsClient();
    final auth = _MockGoTrueClient();
    final session = _MockSession();
    when(() => client.auth).thenReturn(auth);
    when(() => client.functions).thenReturn(functions);
    when(() => auth.currentSession).thenReturn(session);
    when(() => session.accessToken).thenReturn('token');
    dataSource = ProfileRemoteDataSourceImpl(client: client);
  });

  void stubInvoke(Future<FunctionResponse> Function() answer) {
    when(
      () => functions.invoke(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer((_) => answer());
  }

  Future<WorkoutFunctionException> captureError() async {
    try {
      await dataSource.deleteAccount(confirmation: 'ELIMINAR');
    } on WorkoutFunctionException catch (e) {
      return e;
    }
    fail('Se esperaba WorkoutFunctionException');
  }

  group('deleteAccount', () {
    test('invoca delete_account_v1 con confirm y Bearer explícito', () async {
      stubInvoke(
        () async => FunctionResponse(
          data: {
            'success': true,
            'code': 'ACCOUNT_DELETED',
            'data': {'user_id': 'u1', 'deleted': <String, dynamic>{}},
          },
          status: 200,
        ),
      );

      await dataSource.deleteAccount(confirmation: 'ELIMINAR');

      verify(
        () => functions.invoke(
          'delete_account_v1',
          body: {'confirm': 'ELIMINAR'},
          headers: {'Authorization': 'Bearer token'},
        ),
      ).called(1);
    });

    test('400 CONFIRMATION_REQUIRED → VALIDATION_ERROR', () async {
      stubInvoke(
        () => throw const FunctionException(
          status: 400,
          details: {
            'success': false,
            'code': 'CONFIRMATION_REQUIRED',
            'error': {'message': 'confirm must be "ELIMINAR"'},
          },
        ),
      );

      final error = await captureError();
      expect(error.code, 'VALIDATION_ERROR');
      expect(error.userMessage, contains('ELIMINAR'));
    });

    test(
      '500 DELETE_ACCOUNT_DATA_ERROR conserva el código del contrato',
      () async {
        stubInvoke(
          () => throw const FunctionException(
            status: 500,
            details: {'success': false, 'code': 'DELETE_ACCOUNT_DATA_ERROR'},
          ),
        );

        final error = await captureError();
        expect(error.code, 'DELETE_ACCOUNT_DATA_ERROR');
        expect(error.userMessage, contains('siguen intactos'));
      },
    );

    test('429 RATE_LIMIT_EXCEEDED → mensaje de espera', () async {
      stubInvoke(
        () => throw const FunctionException(
          status: 429,
          details: {'success': false, 'code': 'RATE_LIMIT_EXCEEDED'},
        ),
      );

      final error = await captureError();
      expect(error.code, 'RATE_LIMIT_EXCEEDED');
    });

    test('401 → UNAUTHORIZED', () async {
      stubInvoke(() => throw const FunctionException(status: 401));

      final error = await captureError();
      expect(error.code, 'UNAUTHORIZED');
    });

    test(
      'status desconocido sin código → código genérico con prefijo',
      () async {
        stubInvoke(
          () => throw const FunctionException(
            status: 503,
            details: 'Service down',
          ),
        );

        final error = await captureError();
        expect(error.code, 'DELETE_ACCOUNT_FUNCTION_ERROR_503');
      },
    );

    test('200 con success=false → mensaje genérico', () async {
      stubInvoke(
        () async => FunctionResponse(data: {'success': false}, status: 200),
      );

      final error = await captureError();
      expect(error.code, 'UNKNOWN_FUNCTION_ERROR');
      expect(error.userMessage, contains('No se pudo eliminar tu cuenta'));
    });
  });
}
