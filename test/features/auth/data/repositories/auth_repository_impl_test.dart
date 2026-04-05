import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/core/error/exceptions.dart';
import 'package:gym_flutter/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:gym_flutter/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:gym_flutter/features/auth/data/models/user_model.dart';
import 'package:gym_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password';
  const tUserModel = UserModel(id: 'u1', email: tEmail, fullName: 'Test');

  setUpAll(() {
    registerFallbackValue(tUserModel);
  });

  group('signInWithEmail', () {
    test(
      'debería retornar el usuario y cachearlo cuando el login remoto es exitoso',
      () async {
        when(
          () => mockRemoteDataSource.signInWithEmail(any(), any()),
        ).thenAnswer((_) async => tUserModel);
        when(
          () => mockLocalDataSource.cacheUser(any()),
        ).thenAnswer((_) async => {});

        final result = await repository.signInWithEmail(tEmail, tPassword);

        expect(result.isRight(), isTrue);
        result.fold((l) => fail('L'), (r) => expect(r, tUserModel));
        verify(
          () => mockRemoteDataSource.signInWithEmail(tEmail, tPassword),
        ).called(1);
        verify(() => mockLocalDataSource.cacheUser(tUserModel)).called(1);
      },
    );

    test(
      'debería retornar ServerFailure cuando el login remoto falla',
      () async {
        when(
          () => mockRemoteDataSource.signInWithEmail(any(), any()),
        ).thenThrow(ServerException('Invalid credentials'));

        final result = await repository.signInWithEmail(tEmail, tPassword);

        expect(result.isLeft(), isTrue);
        result.fold((l) => expect(l, isA<ServerFailure>()), (r) => fail('R'));
      },
    );
  });

  group('getCurrentUser', () {
    test('debería retornar el usuario remoto y cachearlo si existe', () async {
      when(
        () => mockRemoteDataSource.getCurrentUser(),
      ).thenAnswer((_) async => tUserModel);
      when(
        () => mockLocalDataSource.cacheUser(any()),
      ).thenAnswer((_) async => {});

      final result = await repository.getCurrentUser();

      expect(result, const Right(tUserModel));
      verify(() => mockLocalDataSource.cacheUser(tUserModel)).called(1);
    });

    test(
      'debería retornar el usuario cacheado si la llamada remota falla',
      () async {
        when(
          () => mockRemoteDataSource.getCurrentUser(),
        ).thenThrow(Exception());
        when(
          () => mockLocalDataSource.getLastCachedUser(),
        ).thenAnswer((_) async => tUserModel);

        final result = await repository.getCurrentUser();

        expect(result, const Right(tUserModel));
        verify(() => mockLocalDataSource.getLastCachedUser()).called(1);
      },
    );
  });

  group('signOut', () {
    test('debería cerrar sesión remotamente y limpiar cache', () async {
      when(() => mockRemoteDataSource.signOut()).thenAnswer((_) async => {});
      when(() => mockLocalDataSource.clearCache()).thenAnswer((_) async => {});

      final result = await repository.signOut();

      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.signOut()).called(1);
      verify(() => mockLocalDataSource.clearCache()).called(1);
    });
  });
}
