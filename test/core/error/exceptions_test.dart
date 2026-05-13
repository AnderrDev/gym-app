import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/error/exceptions.dart';

void main() {
  group('Exceptions', () {
    test('ServerException con mensaje', () {
      final e = ServerException('boom');
      expect(e.message, 'boom');
      expect(e.toString(), contains('boom'));
    });

    test('AuthException expone mensaje', () {
      final e = AuthException('credenciales inválidas');
      expect(e.message, 'credenciales inválidas');
      expect(e.toString(), contains('credenciales'));
    });

    test('ValidationException expone mensaje', () {
      final e = ValidationException('campo requerido');
      expect(e.message, 'campo requerido');
    });

    test('NotFoundException y ConflictException son lanzables', () {
      expect(NotFoundException('rutina X'), isA<Exception>());
      expect(ConflictException('día duplicado'), isA<Exception>());
    });
  });
}
