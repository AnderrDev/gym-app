import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/core/ui/molecules/app_empty_state.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  home: Scaffold(body: child),
);

void main() {
  group('AppEmptyState', () {
    testWidgets('renderiza icon, title y subtitle', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppEmptyState(
            icon: Icons.inbox,
            title: 'Sin datos',
            subtitle: 'Aún no hay nada por aquí',
          ),
        ),
      );
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('Sin datos'), findsOneWidget);
      expect(find.text('Aún no hay nada por aquí'), findsOneWidget);
    });

    testWidgets('CTA primario dispara onPrimaryAction', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          AppEmptyState(
            icon: Icons.inbox,
            title: 'Sin datos',
            primaryActionLabel: 'recargar',
            onPrimaryAction: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.text('RECARGAR'));
      expect(tapped, isTrue);
    });

    testWidgets('sin CTA no muestra botones', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppEmptyState(icon: Icons.inbox, title: 'Sin datos')),
      );
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });
  });
}
