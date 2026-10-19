import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/error_mapper.dart';
import 'package:gym_flutter/core/error/exceptions.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  group('mapToFailure', () {
    test('AuthException (domain) → AuthFailure', () {
      final f = mapToFailure(AuthException('bad creds'));
      expect(f, isA<AuthFailure>());
      expect(f.message, 'bad creds');
    });

    test('supabase.AuthException → AuthFailure con texto en español', () {
      final f = mapToFailure(
        const supabase.AuthException(
          'Invalid login credentials',
          code: 'invalid_credentials',
        ),
      );
      expect(f, isA<AuthFailure>());
      expect(f.message, 'Email o contraseña incorrectos.');
    });

    test('AuthRetryableFetchException (sin red) → NetworkFailure', () {
      final f = mapToFailure(
        supabase.AuthRetryableFetchException(message: 'ClientException'),
      );
      expect(f, isA<NetworkFailure>());
      expect(f.message, isNot(contains('ClientException')));
    });

    test('PostgrestException with PGRST116 → NotFoundFailure', () {
      final f = mapToFailure(
        const supabase.PostgrestException(message: 'no rows', code: 'PGRST116'),
      );
      expect(f, isA<NotFoundFailure>());
      expect(f.message, isNot('no rows'));
    });

    test('PostgrestException with 23505 → ConflictFailure', () {
      final f = mapToFailure(
        const supabase.PostgrestException(message: 'dup', code: '23505'),
      );
      expect(f, isA<ConflictFailure>());
    });

    test('PostgrestException unknown code → ServerFailure', () {
      final f = mapToFailure(
        const supabase.PostgrestException(message: 'boom', code: 'X1'),
      );
      expect(f, isA<ServerFailure>());
      // El texto técnico de Postgres no llega a la UI.
      expect(f.message, isNot(contains('boom')));
    });

    test('PostgrestException 42501 (RLS) → AuthFailure sin permiso', () {
      final f = mapToFailure(
        const supabase.PostgrestException(message: 'denied', code: '42501'),
      );
      expect(f, isA<AuthFailure>());
      expect(f.message, 'No tienes permiso para hacer esto.');
    });

    test('SocketException → NetworkFailure', () {
      final f = mapToFailure(const SocketException('no conn'));
      expect(f, isA<NetworkFailure>());
    });

    test('TimeoutException → NetworkFailure', () {
      final f = mapToFailure(TimeoutException('slow'));
      expect(f, isA<NetworkFailure>());
    });

    test('ServerException → ServerFailure', () {
      final f = mapToFailure(ServerException('500'));
      expect(f, isA<ServerFailure>());
      expect(f.message, '500');
    });

    test('NotFoundException → NotFoundFailure', () {
      final f = mapToFailure(NotFoundException('missing'));
      expect(f, isA<NotFoundFailure>());
    });

    test('ConflictException → ConflictFailure', () {
      final f = mapToFailure(ConflictException('dup'));
      expect(f, isA<ConflictFailure>());
    });

    test('ValidationException → ValidationFailure', () {
      final f = mapToFailure(ValidationException('bad input'));
      expect(f, isA<ValidationFailure>());
    });

    test('NetworkException → NetworkFailure', () {
      final f = mapToFailure(NetworkException());
      expect(f, isA<NetworkFailure>());
    });

    test('passthrough Failure', () {
      const original = AuthFailure('already mapped');
      final f = mapToFailure(original);
      expect(identical(f, original), isTrue);
    });

    test('unknown error → ServerFailure genérico, sin el texto crudo', () {
      final f = mapToFailure(StateError('unexpected'));
      expect(f, isA<ServerFailure>());
      expect(f.message, isNot(contains('unexpected')));
    });
  });

  group('guard', () {
    test('Right on success', () async {
      final result = await guard<int>(() async => 42);
      expect(result, const Right<Failure, int>(42));
    });

    test('Left(NetworkFailure) when SocketException is thrown', () async {
      final result = await guard<int>(
        () async => throw const SocketException('down'),
      );
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('Left(AuthFailure) when supabase.AuthException is thrown', () async {
      final result = await guard<int>(
        () async => throw const supabase.AuthException(
          'expired',
          code: 'session_expired',
        ),
      );
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'Tu sesión expiró. Vuelve a iniciar sesión.');
      }, (_) => fail('expected Left'));
    });
  });
}
