import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AppSpinner', () {
    testWidgets('renderiza SpinKitFadingCircle con semantics live', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const AppSpinner()));
      expect(find.byType(SpinKitFadingCircle), findsOneWidget);
      final semantics = tester.getSemantics(find.byType(AppSpinner));
      expect(semantics.label, 'Cargando');
    });

    testWidgets('.small mide 20', (tester) async {
      await tester.pumpWidget(_wrap(const AppSpinner.small()));
      final spinner = tester.widget<SpinKitFadingCircle>(
        find.byType(SpinKitFadingCircle),
      );
      expect(spinner.size, 20);
    });

    testWidgets('.medium mide 36', (tester) async {
      await tester.pumpWidget(_wrap(const AppSpinner.medium()));
      final spinner = tester.widget<SpinKitFadingCircle>(
        find.byType(SpinKitFadingCircle),
      );
      expect(spinner.size, 36);
    });

    testWidgets('.large mide 56', (tester) async {
      await tester.pumpWidget(_wrap(const AppSpinner.large()));
      final spinner = tester.widget<SpinKitFadingCircle>(
        find.byType(SpinKitFadingCircle),
      );
      expect(spinner.size, 56);
    });

    testWidgets('color custom se aplica al SpinKit', (tester) async {
      await tester.pumpWidget(_wrap(const AppSpinner(color: Colors.red)));
      final spinner = tester.widget<SpinKitFadingCircle>(
        find.byType(SpinKitFadingCircle),
      );
      expect(spinner.color, Colors.red);
    });

    testWidgets('semanticLabel custom se respeta', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppSpinner(semanticLabel: 'Sincronizando…')),
      );
      final semantics = tester.getSemantics(find.byType(AppSpinner));
      expect(semantics.label, 'Sincronizando…');
    });
  });
}
