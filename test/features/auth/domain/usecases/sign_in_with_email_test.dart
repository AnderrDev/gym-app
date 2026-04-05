import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gym_flutter/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:gym_flutter/core/error/failures.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/test_fixtures.dart';

void main() {
  late MockAuthRepository mockRepository;
  late SignInWithEmail usecase;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = SignInWithEmail(mockRepository);
  });

  test('retorna User cuando el login es exitoso', () async {
    when(
      () => mockRepository.signInWithEmail('test@example.com', 'password'),
    ).thenAnswer((_) async => const Right(testUser));

    final result = await usecase('test@example.com', 'password');

    expect(result, const Right(testUser));
    verify(
      () => mockRepository.signInWithEmail('test@example.com', 'password'),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('retorna Failure cuando el login falla', () async {
    when(
      () => mockRepository.signInWithEmail('test@example.com', 'password'),
    ).thenAnswer((_) async => const Left(ServerFailure('boom')));

    final result = await usecase('test@example.com', 'password');

    expect(result, const Left(ServerFailure('boom')));
  });
}
