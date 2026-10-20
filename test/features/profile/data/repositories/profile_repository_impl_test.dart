import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/core/error/exceptions.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/profile/data/repositories/profile_repository_impl.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockProfileRemoteDataSource remote;
  late ProfileRepositoryImpl repository;

  setUp(() {
    remote = MockProfileRemoteDataSource();
    repository = ProfileRepositoryImpl(remote: remote);
  });

  group('deleteAccount', () {
    test('Right(null) cuando la function responde OK', () async {
      when(
        () => remote.deleteAccount(confirmation: any(named: 'confirmation')),
      ).thenAnswer((_) async {});

      final result = await repository.deleteAccount(confirmation: 'ELIMINAR');

      expect(result, const Right<Failure, void>(null));
      verify(() => remote.deleteAccount(confirmation: 'ELIMINAR')).called(1);
    });

    test('VALIDATION_ERROR → ValidationFailure', () async {
      when(
        () => remote.deleteAccount(confirmation: any(named: 'confirmation')),
      ).thenThrow(
        const WorkoutFunctionException(
          code: 'VALIDATION_ERROR',
          userMessage: 'Escribe ELIMINAR para confirmar.',
        ),
      );

      final result = await repository.deleteAccount(confirmation: 'ELIMINAR');

      expect(
        result,
        const Left<Failure, void>(
          ValidationFailure('Escribe ELIMINAR para confirmar.'),
        ),
      );
    });

    test(
      'error del servidor → ServerFailure con el mensaje de usuario',
      () async {
        when(
          () => remote.deleteAccount(confirmation: any(named: 'confirmation')),
        ).thenThrow(
          const WorkoutFunctionException(
            code: 'DELETE_ACCOUNT_DATA_ERROR',
            userMessage: 'No se pudo eliminar tu cuenta.',
          ),
        );

        final result = await repository.deleteAccount(confirmation: 'ELIMINAR');

        expect(
          result,
          const Left<Failure, void>(
            ServerFailure('No se pudo eliminar tu cuenta.'),
          ),
        );
      },
    );

    test('UNAUTHORIZED → AuthFailure', () async {
      when(
        () => remote.deleteAccount(confirmation: any(named: 'confirmation')),
      ).thenThrow(
        const WorkoutFunctionException(
          code: 'UNAUTHORIZED',
          userMessage: 'Tu sesión expiró.',
        ),
      );

      final result = await repository.deleteAccount(confirmation: 'ELIMINAR');

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<AuthFailure>());
    });
  });
}
