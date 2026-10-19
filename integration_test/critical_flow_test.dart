// Integration test del flujo crítico: login → dashboard → start day → save 3 sets
// → finish → ver insights.
//
// Necesita:
//   1) Cuenta de prueba en el Supabase del .env con al menos una rutina asignada
//      y un día con un ejercicio.
//   2) Credenciales vía `--dart-define`:
//        TEST_EMAIL=...   TEST_PASSWORD=...
//      Sin ellas, el test se `markTestSkipped` y CI sigue verde.
//
// Comando:
//   flutter test integration_test/critical_flow_test.dart \
//     --dart-define-from-file=.env \
//     --dart-define=TEST_EMAIL=qa@example.com \
//     --dart-define=TEST_PASSWORD=...

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gym_flutter/main.dart' as app;

const _testEmail = String.fromEnvironment('TEST_EMAIL');
const _testPassword = String.fromEnvironment('TEST_PASSWORD');

bool get _hasCredentials => _testEmail.isNotEmpty && _testPassword.isNotEmpty;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flujo crítico — login → workout → insights', () {
    setUpAll(() {
      if (!_hasCredentials) {
        // ignore: avoid_print
        print(
          '[critical_flow_test] TEST_EMAIL/TEST_PASSWORD no definidos. '
          'Skip — defínelos vía --dart-define para correr el flujo real.',
        );
      }
    });

    testWidgets('login + start workout + save 3 sets + finish', (tester) async {
      if (!_hasCredentials) {
        markTestSkipped('Faltan TEST_EMAIL/TEST_PASSWORD');
        return;
      }

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 1) Login
      expect(find.text('GYM TRACKER'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, _testEmail);
      await tester.enterText(find.byType(TextField).last, _testPassword);
      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 2) Dashboard — debería existir el header con "HOY".
      expect(find.text('HOY'), findsWidgets);

      // 3) Tappar la day card de hoy (asume rutina seeded).
      //    El day card concreto depende del usuario de prueba, por lo que
      //    buscamos el primer botón de "EMPEZAR" / "CONTINUAR" disponible.
      final startBtn = find.textContaining(RegExp(r'EMPEZAR|CONTINUAR'));
      if (startBtn.evaluate().isEmpty) {
        fail(
          'El usuario de prueba no tiene rutina asignada con día hoy. '
          'Asignar una antes de correr el test.',
        );
      }
      await tester.tap(startBtn.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 4) RoutineDay: marcar 3 sets como completados.
      //    El sets-row tiene un check button — buscamos los primeros 3.
      final checks = find.byIcon(Icons.check_rounded);
      expect(checks, findsAtLeastNWidgets(1), reason: 'no hay set rows');
      for (var i = 0; i < 3 && i < checks.evaluate().length; i++) {
        await tester.tap(checks.at(i));
        await tester.pump(const Duration(milliseconds: 500));
      }

      // 5) Finalizar workout.
      final finishBtn = find.textContaining(RegExp(r'FINALIZAR|TERMINAR'));
      if (finishBtn.evaluate().isNotEmpty) {
        await tester.tap(finishBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      // 6) Volver al dashboard y verificar que las insights cargan
      //    (sólo verificamos que el shell sigue navegable).
      expect(find.text('GYM TRACKER'), findsNothing);
    });
  });
}
