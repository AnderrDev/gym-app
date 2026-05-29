import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/core/ui/molecules/app_error_state.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  home: Scaffold(body: child),
);

void main() {
  group('AppErrorState', () {
    testWidgets('renderiza el message', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppErrorState(message: 'Algo se rompió')),
      );
      expect(find.text('Algo se rompió'), findsOneWidget);
    });

    testWidgets('CTA Reintentar dispara onRetry', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(AppErrorState(message: 'falló', onRetry: () => tapped = true)),
      );
      await tester.tap(find.text('REINTENTAR'));
      expect(tapped, isTrue);
    });

    testWidgets('sin onRetry no muestra el botón', (tester) async {
      await tester.pumpWidget(_wrap(const AppErrorState(message: 'falló')));
      expect(find.text('REINTENTAR'), findsNothing);
    });
  });
}
