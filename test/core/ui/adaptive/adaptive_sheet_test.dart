import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/core/ui/adaptive/adaptive_sheet.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  home: Scaffold(body: child),
);

void main() {
  group('AdaptiveSheet.show', () {
    testWidgets('renderiza title y child', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) {
              capturedContext = ctx;
              return ElevatedButton(
                onPressed: () => AdaptiveSheet.show<void>(
                  ctx,
                  title: 'Mi título',
                  child: const Text('Mi contenido'),
                ),
                child: const Text('open'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Mi título'), findsOneWidget);
      expect(find.text('Mi contenido'), findsOneWidget);
      // ignore: unnecessary_statements
      capturedContext;
    });

    testWidgets('close button cierra el sheet', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => AdaptiveSheet.show<void>(
                ctx,
                title: 'X',
                child: const Text('contenido'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('contenido'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('contenido'), findsNothing);
    });
  });

  group('AdaptiveSheet.showRaw', () {
    testWidgets('renderiza el child sin chrome', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => AdaptiveSheet.showRaw<void>(
                ctx,
                builder: (_) => Container(
                  height: 200,
                  color: Colors.amber,
                  child: const Center(child: Text('raw content')),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('raw content'), findsOneWidget);
      // No chrome rendered: no close icon
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });
  });
}
