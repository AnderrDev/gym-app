import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gym_flutter/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:gym_flutter/core/error/failures.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/test_fixtures.dart';

void main() {
  late MockAuthRepository mockRepository;
  late SignUpWithEmail usecase;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = SignUpWithEmail(mockRepository);
  });

  test('retorna User cuando el registro es exitoso', () async {
    when(
      () => mockRepository.signUpWithEmail(
        'test@example.com',
        'password',
        'Test User',
      ),
    ).thenAnswer((_) async => const Right(testUser));

    final result = await usecase('test@example.com', 'password', 'Test User');

    expect(result, const Right(testUser));
    verify(
      () => mockRepository.signUpWithEmail(
        'test@example.com',
        'password',
        'Test User',
      ),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('retorna Failure cuando el registro falla', () async {
    when(
      () => mockRepository.signUpWithEmail(
        'test@example.com',
        'password',
        'Test User',
      ),
    ).thenAnswer((_) async => const Left(ServerFailure('boom')));

    final result = await usecase('test@example.com', 'password', 'Test User');

    expect(result, const Left(ServerFailure('boom')));
  });
}
