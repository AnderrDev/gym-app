import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/profile/domain/usecases/delete_account.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockProfileRepository repository;
  late DeleteAccount usecase;

  setUp(() {
    repository = MockProfileRepository();
    usecase = DeleteAccount(repository);
  });

  test('delega en el repositorio con la palabra normalizada', () async {
    when(
      () => repository.deleteAccount(confirmation: any(named: 'confirmation')),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase(confirmation: '  ELIMINAR ');

    expect(result.isRight(), isTrue);
    verify(() => repository.deleteAccount(confirmation: 'ELIMINAR')).called(1);
  });

  test('rechaza otra confirmación sin llamar al servidor', () async {
    final result = await usecase(confirmation: 'eliminar cuenta');

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(
      () => repository.deleteAccount(confirmation: any(named: 'confirmation')),
    );
  });
}
