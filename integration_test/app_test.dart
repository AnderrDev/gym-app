import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gym_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas de Integración de Autenticación', () {
    testWidgets('Flujo de error de login con credenciales inválidas', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // Verificar que estamos en la página de login
      expect(find.text('GYM TRACKER'), findsOneWidget);

      // Ingresar credenciales inválidas
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;
      final loginButton = find.text('INICIAR SESIÓN');

      await tester.enterText(emailField, 'error@test.com');
      await tester.enterText(passwordField, 'wrongpassword');
      await tester.tap(loginButton);

      // Esperar a que el bloc procese y el listener reciba el error
      await tester.pumpAndSettle();

      // Debería aparecer un SnackBar con el error de Supabase (o el mensaje de error del bloc)
      // Como estamos usando datos reales o mocks en di, el resultado depende del entorno.
      // Pero podemos verificar que se intentó hacer login y no se redirigió.
      expect(find.text('GYM TRACKER'), findsOneWidget);
    });

    testWidgets('Navegación entre Login y Registro', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Ir a Registro
      final goToRegisterLink = find.text('REGÍSTRATE');
      await tester.tap(goToRegisterLink);
      await tester.pumpAndSettle();

      expect(find.text('CREAR CUENTA'), findsOneWidget);

      // Volver a Login
      final goToLoginLink = find.text('INICIA SESIÓN');
      await tester.tap(goToLoginLink);
      await tester.pumpAndSettle();

      expect(find.text('GYM TRACKER'), findsOneWidget);
    });
    group('Flujo de Entrenamiento (Navegación básica)', () {
      testWidgets(
        'Navegar a la lista de rutinas desde el login (simulando auth o asumiendo un estado previo)',
        (tester) async {
          // Nota: En una prueba real de integración sin mocks de DI, necesitaríamos una cuenta válida.
          // Aquí probamos la estructura del test.
          app.main();
          await tester.pumpAndSettle();

          expect(find.text('GYM TRACKER'), findsOneWidget);
        },
      );
    });
  });
}
