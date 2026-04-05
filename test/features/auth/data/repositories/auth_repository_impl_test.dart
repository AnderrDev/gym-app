import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/exceptions.dart';
import 'package:gym_flutter/core/error/failures.dart';
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
  const tFullName = 'Test User';
  const tUserModel = UserModel(id: '1', email: tEmail, fullName: tFullName);

  setUpAll(() {
    registerFallbackValue(tUserModel);
  });

  group('signInWithEmail', () {
    test(
      'debería retornar el usuario y cachearlo cuando el login es exitoso',
      () async {
        // arrange
        when(
          () => mockRemoteDataSource.signInWithEmail(any(), any()),
        ).thenAnswer((_) async => tUserModel);
        when(
          () => mockLocalDataSource.cacheUser(any()),
        ).thenAnswer((_) async => Future.value());

        // act
        final result = await repository.signInWithEmail(tEmail, tPassword);

        // assert
        expect(result, const Right(tUserModel));
        verify(
          () => mockRemoteDataSource.signInWithEmail(tEmail, tPassword),
        ).called(1);
        verify(() => mockLocalDataSource.cacheUser(tUserModel)).called(1);
      },
    );

    test(
      'debería retornar ServerFailure cuando el login falla en el remote con ServerException',
      () async {
        // arrange
        when(
          () => mockRemoteDataSource.signInWithEmail(any(), any()),
        ).thenThrow(ServerException('Invalid credentials'));

        // act
        final result = await repository.signInWithEmail(tEmail, tPassword);

        // assert
        expect(result, const Left(ServerFailure('Invalid credentials')));
        verify(
          () => mockRemoteDataSource.signInWithEmail(tEmail, tPassword),
        ).called(1);
        verifyNever(() => mockLocalDataSource.cacheUser(any()));
      },
    );
  });

  group('signUpWithEmail', () {
    test(
      'debería retornar el usuario y cachearlo cuando el registro es exitoso',
      () async {
        // arrange
        when(
          () => mockRemoteDataSource.signUpWithEmail(any(), any(), any()),
        ).thenAnswer((_) async => tUserModel);
        when(
          () => mockLocalDataSource.cacheUser(any()),
        ).thenAnswer((_) async => Future.value());

        // act
        final result = await repository.signUpWithEmail(
          tEmail,
          tPassword,
          tFullName,
        );

        // assert
        expect(result, const Right(tUserModel));
        verify(
          () => mockRemoteDataSource.signUpWithEmail(
            tEmail,
            tPassword,
            tFullName,
          ),
        ).called(1);
        verify(() => mockLocalDataSource.cacheUser(tUserModel)).called(1);
      },
    );
  });

  group('signOut', () {
    test(
      'debería limpiar el cache y retornar void cuando el logout es exitoso',
      () async {
        // arrange
        when(
          () => mockRemoteDataSource.signOut(),
        ).thenAnswer((_) async => Future.value());
        when(
          () => mockLocalDataSource.clearCache(),
        ).thenAnswer((_) async => Future.value());

        // act
        final result = await repository.signOut();

        // assert
        expect(result, const Right(null));
        verify(() => mockRemoteDataSource.signOut()).called(1);
        verify(() => mockLocalDataSource.clearCache()).called(1);
      },
    );
  });

  group('getCurrentUser', () {
    test(
      'debería retornar el usuario del remote y cachearlo cuando está disponible',
      () async {
        // arrange
        when(
          () => mockRemoteDataSource.getCurrentUser(),
        ).thenAnswer((_) async => tUserModel);
        when(
          () => mockLocalDataSource.cacheUser(any()),
        ).thenAnswer((_) async => Future.value());

        // act
        final result = await repository.getCurrentUser();

        // assert
        expect(result, const Right(tUserModel));
        verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
        verify(() => mockLocalDataSource.cacheUser(tUserModel)).called(1);
      },
    );

    test(
      'debería retornar el usuario cacheado cuando el remote falla',
      () async {
        // arrange
        when(
          () => mockRemoteDataSource.getCurrentUser(),
        ).thenThrow(Exception());
        when(
          () => mockLocalDataSource.getLastCachedUser(),
        ).thenAnswer((_) async => tUserModel);

        // act
        final result = await repository.getCurrentUser();

        // assert
        expect(result, const Right(tUserModel));
        verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
        verify(() => mockLocalDataSource.getLastCachedUser()).called(1);
      },
    );
  });
}
