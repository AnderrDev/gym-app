import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/core/ui/feedback/app_dialog.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(body: child),
);

void main() {
  group('AppDialog.confirm', () {
    testWidgets('renderiza title y message; confirmar devuelve true', (
      tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await AppDialog.confirm(
                  ctx,
                  title: '¿Borrar?',
                  message: 'No se puede deshacer.',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('¿Borrar?'), findsOneWidget);
      expect(find.text('No se puede deshacer.'), findsOneWidget);

      await tester.tap(find.text('CONFIRMAR'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('cancelar devuelve false', (tester) async {
      bool? result;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await AppDialog.confirm(ctx, title: 'X', message: 'Y');
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });
}
