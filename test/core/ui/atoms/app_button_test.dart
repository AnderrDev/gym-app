import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/core/ui/atoms/app_button.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  group('AppButton', () {
    testWidgets('primary muestra label en uppercase', (tester) async {
      await tester.pumpWidget(
        _wrap(AppButton(label: 'guardar', onPressed: () {})),
      );
      expect(find.text('GUARDAR'), findsOneWidget);
    });

    testWidgets('isLoading muestra spinner y deshabilita tap', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrap(
          AppButton(
            label: 'submit',
            onPressed: () => pressed = true,
            isLoading: true,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(pressed, isFalse);
    });

    testWidgets('onPressed null deshabilita el botón', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppButton(label: 'disabled', onPressed: null)),
      );
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('icon se renderiza junto al label', (tester) async {
      await tester.pumpWidget(
        _wrap(AppButton(label: 'save', onPressed: () {}, icon: Icons.save)),
      );
      expect(find.byIcon(Icons.save), findsOneWidget);
      expect(find.text('SAVE'), findsOneWidget);
    });

    testWidgets('variante destructive usa color error', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppButton(
            label: 'delete',
            onPressed: () {},
            variant: AppButtonVariant.destructive,
          ),
        ),
      );
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('DELETE'), findsOneWidget);
    });

    testWidgets('variante secondary usa OutlinedButton', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppButton(
            label: 'cancel',
            onPressed: () {},
            variant: AppButtonVariant.secondary,
          ),
        ),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('variante ghost usa TextButton', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppButton(
            label: 'maybe',
            onPressed: () {},
            variant: AppButtonVariant.ghost,
          ),
        ),
      );
      expect(find.byType(TextButton), findsOneWidget);
    });
  });
}
