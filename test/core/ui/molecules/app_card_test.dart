import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_flutter/core/theme/app_palette.dart';
import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/core/ui/molecules/app_card.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  home: Scaffold(body: child),
);

void main() {
  group('AppCard', () {
    testWidgets('pinta surface sólida con Material + InkWell', (tester) async {
      await tester.pumpWidget(_wrap(const AppCard(child: Text('contenido'))));
      expect(find.text('contenido'), findsOneWidget);
      final material = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('contenido'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, AppPalette.dark().surface);
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('onTap invoca callback al tappear', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          AppCard(
            onTap: () => taps++,
            child: const SizedBox(width: 100, height: 100, child: Text('tap')),
          ),
        ),
      );
      await tester.tap(find.text('tap'));
      await tester.pump();
      expect(taps, 1);
    });
  });
}
