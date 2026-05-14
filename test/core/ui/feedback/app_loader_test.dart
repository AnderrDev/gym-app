import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/core/ui/feedback/app_loader.dart';
import 'package:gym_flutter/core/ui/feedback/barbell_loader.dart';

void main() {
  group('AppLoader', () {
    testWidgets('show abre el overlay con mensaje y spinner', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return ElevatedButton(
                  onPressed: () => AppLoader.show(ctx, message: 'Cargando…'),
                  child: const Text('show'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('show'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Cargando…'), findsOneWidget);
      // El indicador interno ahora es el BarbellLoader (custom painter
      // con AnimationController.repeat → nunca settla).
      expect(find.byType(BarbellLoader), findsOneWidget);

      // Cerrar programáticamente vía el contexto raíz.
      AppLoader.hide(capturedContext);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Cargando…'), findsNothing);
    });
  });
}
