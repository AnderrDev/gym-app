import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gym_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:gym_flutter/core/error/failures.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockRepository;
  late SignOut usecase;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = SignOut(mockRepository);
  });

  test('retorna void cuando el logout es exitoso', () async {
    when(
      () => mockRepository.signOut(),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase();

    expect(result, const Right(null));
    verify(() => mockRepository.signOut()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('retorna Failure cuando el logout falla', () async {
    when(
      () => mockRepository.signOut(),
    ).thenAnswer((_) async => const Left(ServerFailure('boom')));

    final result = await usecase();

    expect(result, const Left(ServerFailure('boom')));
  });
}
