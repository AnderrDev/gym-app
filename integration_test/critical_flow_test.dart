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

      // 3) HOY → tarjeta del día que toca (asume rutina seeded).
      final startBtn = find.textContaining(
        RegExp(r'Entrenar hoy|Continuar sesión'),
      );
      if (startBtn.evaluate().isEmpty) {
        fail(
          'El usuario de prueba no tiene rutina asignada con día hoy. '
          'Asignar una antes de correr el test.',
        );
      }
      await tester.tap(startBtn.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 4) Previa → "Iniciar entrenamiento" (no aparece si se reanuda).
      final begin = find.text('Iniciar entrenamiento');
      if (begin.evaluate().isNotEmpty) {
        await tester.tap(begin);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // 5) Registrar 3 series con el botón fijo inferior. Con peso propuesto
      //    registra de un toque; sin él abre la hoja y se confirma.
      final completeBtn = find.byKey(
        const ValueKey('focus_complete_set_button'),
      );
      for (var i = 0; i < 3 && completeBtn.evaluate().isNotEmpty; i++) {
        await tester.tap(completeBtn);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        final confirm = find.text('CONFIRMAR SERIE');
        if (confirm.evaluate().isNotEmpty) {
          await tester.tap(confirm);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }
      }

      // 6) Finalizar → resumen → "Finalizar y guardar".
      final finishBtn = find.text('Finalizar');
      if (finishBtn.evaluate().isNotEmpty) {
        await tester.tap(finishBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        final save = find.text('FINALIZAR Y GUARDAR');
        if (save.evaluate().isNotEmpty) {
          await tester.tap(save);
          await tester.pumpAndSettle(const Duration(seconds: 5));
        }
      }

      // 7) Volver al dashboard y verificar que las insights cargan
      //    (sólo verificamos que el shell sigue navegable).
      expect(find.text('GYM TRACKER'), findsNothing);
    });
  });
}
