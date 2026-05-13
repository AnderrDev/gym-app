import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/error/failures.dart';

void main() {
  group('Failures', () {
    test('AuthFailure default message en español', () {
      const f = AuthFailure();
      expect(f.message, 'Error de autenticación');
    });

    test('ValidationFailure custom message', () {
      const f = ValidationFailure('email inválido');
      expect(f.message, 'email inválido');
    });

    test('Failures con misma message son iguales (Equatable)', () {
      const a = ServerFailure('x');
      const b = ServerFailure('x');
      expect(a, equals(b));
    });

    test(
      'Failures de subclases distintas no son iguales aunque message sea igual',
      () {
        const auth = AuthFailure('x');
        const server = ServerFailure('x');
        expect(auth, isNot(equals(server)));
      },
    );
  });
}
