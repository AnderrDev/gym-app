import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_flutter/core/presentation/widgets/glass_container.dart';
import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/core/ui/molecules/app_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: child),
    );

void main() {
  group('AppCard', () {
    testWidgets('surface por defecto usa Material + InkWell + Container',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const AppCard(child: Text('contenido'))),
      );
      expect(find.text('contenido'), findsOneWidget);
      expect(find.byType(Material), findsWidgets);
      expect(find.byType(InkWell), findsOneWidget);
      expect(find.byType(GlassContainer), findsNothing);
    });

    testWidgets('glass usa GlassContainer en vez de Material', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppCard.glass(child: Text('translúcida'))),
      );
      expect(find.text('translúcida'), findsOneWidget);
      expect(find.byType(GlassContainer), findsOneWidget);
    });

    testWidgets('onTap invoca callback al tappear', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(AppCard(
          onTap: () => taps++,
          child: const SizedBox(width: 100, height: 100, child: Text('tap')),
        )),
      );
      await tester.tap(find.text('tap'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('glass sin onTap no envuelve en InkWell', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppCard.glass(child: Text('static'))),
      );
      // Glass-only branch: si no hay onTap el _wrapTap devuelve el child crudo.
      expect(find.byType(InkWell), findsNothing);
    });
  });
}
