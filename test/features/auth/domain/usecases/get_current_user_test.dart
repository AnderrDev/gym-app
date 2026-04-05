import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gym_flutter/features/auth/domain/usecases/get_current_user.dart';
import 'package:gym_flutter/core/error/failures.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/test_fixtures.dart';

void main() {
  late MockAuthRepository mockRepository;
  late GetCurrentUser usecase;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = GetCurrentUser(mockRepository);
  });

  test('retorna User cuando existe sesion', () async {
    when(
      () => mockRepository.getCurrentUser(),
    ).thenAnswer((_) async => const Right(testUser));

    final result = await usecase();

    expect(result, const Right(testUser));
    verify(() => mockRepository.getCurrentUser()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('retorna null cuando no hay sesion', () async {
    when(
      () => mockRepository.getCurrentUser(),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase();

    expect(result, const Right(null));
    verify(() => mockRepository.getCurrentUser()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('retorna Failure cuando ocurre un error', () async {
    when(
      () => mockRepository.getCurrentUser(),
    ).thenAnswer((_) async => const Left(ServerFailure('boom')));

    final result = await usecase();

    expect(result, const Left(ServerFailure('boom')));
  });
}
