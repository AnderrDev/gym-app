import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/routes/app_router.dart';

void main() {
  group('safeRedirectTarget', () {
    test('acepta rutas internas con query', () {
      expect(safeRedirectTarget('/progress'), '/progress');
      expect(
        safeRedirectTarget('/routine-editor?id=r1'),
        '/routine-editor?id=r1',
      );
    });

    test('rechaza redirecciones externas', () {
      expect(safeRedirectTarget('https://evil.com'), isNull);
      expect(safeRedirectTarget('//evil.com/x'), isNull);
      expect(safeRedirectTarget('evil.com'), isNull);
    });

    test('rechaza login/registro y rutas que necesitan extra', () {
      expect(safeRedirectTarget('/login'), isNull);
      expect(safeRedirectTarget('/register'), isNull);
      expect(safeRedirectTarget('/routine-day'), isNull);
      expect(safeRedirectTarget('/day-editor'), isNull);
      expect(safeRedirectTarget(null), isNull);
    });
  });
}
