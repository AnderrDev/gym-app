import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/auth/domain/usecases/get_current_user.dart';
import 'package:gym_flutter/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:gym_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:gym_flutter/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_fixtures.dart';

class MockSignInWithEmail extends Mock implements SignInWithEmail {}

class MockSignUpWithEmail extends Mock implements SignUpWithEmail {}

class MockSignOut extends Mock implements SignOut {}

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

void main() {
  late MockSignInWithEmail mockSignInWithEmail;
  late MockSignUpWithEmail mockSignUpWithEmail;
  late MockSignOut mockSignOut;
  late MockGetCurrentUser mockGetCurrentUser;

  setUp(() {
    mockSignInWithEmail = MockSignInWithEmail();
    mockSignUpWithEmail = MockSignUpWithEmail();
    mockSignOut = MockSignOut();
    mockGetCurrentUser = MockGetCurrentUser();
  });

  AuthBloc buildBloc() {
    return AuthBloc(
      signInWithEmail: mockSignInWithEmail,
      signUpWithEmail: mockSignUpWithEmail,
      signOut: mockSignOut,
      getCurrentUser: mockGetCurrentUser,
      authStateChanges: const Stream.empty(),
    );
  }

  blocTest<AuthBloc, AuthState>(
    'emite [AuthLoading] cuando AppStarted es disparado',
    build: buildBloc,
    act: (bloc) => bloc.add(AppStarted()),
    expect: () => [AuthLoading()],
  );

  blocTest<AuthBloc, AuthState>(
    'emite [Authenticated] cuando AuthStateChanged indica autenticado',
    build: buildBloc,
    setUp: () {
      when(
        () => mockGetCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
    },
    act: (bloc) => bloc.add(const AuthStateChanged(isAuthenticated: true)),
    expect: () => [const Authenticated(testUser)],
    verify: (_) => verify(() => mockGetCurrentUser()).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    'emite [Unauthenticated] cuando AuthStateChanged indica no autenticado',
    build: buildBloc,
    act: (bloc) => bloc.add(const AuthStateChanged(isAuthenticated: false)),
    expect: () => [Unauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'emite [AuthSubmitting, Authenticated] al iniciar sesion con exito',
    build: buildBloc,
    setUp: () {
      when(
        () => mockSignInWithEmail('test@example.com', 'password'),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockGetCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
    },
    act: (bloc) =>
        bloc.add(const SignInRequested('test@example.com', 'password')),
    expect: () => [AuthSubmitting(), const Authenticated(testUser)],
  );

  blocTest<AuthBloc, AuthState>(
    'emite [AuthSubmitting, AuthError] si login falla',
    build: buildBloc,
    setUp: () {
      when(
        () => mockSignInWithEmail('test@example.com', 'password'),
      ).thenAnswer((_) async => const Left(ServerFailure('boom')));
    },
    act: (bloc) =>
        bloc.add(const SignInRequested('test@example.com', 'password')),
    expect: () => [AuthSubmitting(), const AuthError('boom')],
  );

  blocTest<AuthBloc, AuthState>(
    'emite [AuthSubmitting, Authenticated] al registrarse con exito',
    build: buildBloc,
    setUp: () {
      when(
        () => mockSignUpWithEmail('test@example.com', 'password', 'Test User'),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockGetCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
    },
    act: (bloc) => bloc.add(
      const SignUpRequested('test@example.com', 'password', 'Test User'),
    ),
    expect: () => [AuthSubmitting(), const Authenticated(testUser)],
  );

  blocTest<AuthBloc, AuthState>(
    'emite [AuthSubmitting, AuthError] si registro falla',
    build: buildBloc,
    setUp: () {
      when(
        () => mockSignUpWithEmail('test@example.com', 'password', 'Test User'),
      ).thenAnswer((_) async => const Left(ServerFailure('boom')));
    },
    act: (bloc) => bloc.add(
      const SignUpRequested('test@example.com', 'password', 'Test User'),
    ),
    expect: () => [AuthSubmitting(), const AuthError('boom')],
  );

  blocTest<AuthBloc, AuthState>(
    'emite [AuthSubmitting, Unauthenticated] al cerrar sesion con exito',
    build: buildBloc,
    setUp: () {
      when(() => mockSignOut()).thenAnswer((_) async => const Right(null));
    },
    act: (bloc) => bloc.add(SignOutRequested()),
    expect: () => [AuthSubmitting(), Unauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'emite [AuthSubmitting, AuthError] si logout falla',
    build: buildBloc,
    setUp: () {
      when(
        () => mockSignOut(),
      ).thenAnswer((_) async => const Left(ServerFailure('boom')));
    },
    act: (bloc) => bloc.add(SignOutRequested()),
    expect: () => [AuthSubmitting(), const AuthError('boom')],
  );
}
