import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/core/ui/molecules/app_form_field.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  group('AppFormField', () {
    testWidgets('renderiza label en uppercase y valor inicial', (tester) async {
      await tester.pumpWidget(
        _wrap(AppFormField(
          label: 'email',
          value: 'foo@bar.com',
          onChanged: (_) {},
        )),
      );
      expect(find.text('EMAIL'), findsOneWidget);
      expect(find.text('foo@bar.com'), findsOneWidget);
    });

    testWidgets('onChanged se invoca al tipear', (tester) async {
      var captured = '';
      await tester.pumpWidget(
        _wrap(AppFormField(
          label: 'name',
          value: '',
          onChanged: (v) => captured = v,
        )),
      );
      await tester.enterText(find.byType(TextField), 'Ander');
      expect(captured, 'Ander');
    });

    testWidgets('errorText se propaga al InputDecoration', (tester) async {
      await tester.pumpWidget(
        _wrap(AppFormField(
          label: 'password',
          value: 'x',
          errorText: 'demasiado corta',
          onChanged: (_) {},
        )),
      );
      expect(find.text('demasiado corta'), findsOneWidget);
    });

    testWidgets('obscureText muestra suffix icon de visibility', (tester) async {
      await tester.pumpWidget(
        _wrap(AppFormField(
          label: 'password',
          value: 'secret',
          obscureText: true,
          onChanged: (_) {},
        )),
      );
      expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_rounded));
      await tester.pump();
      // Tras togglear el ojito cambia al icono opuesto.
      expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);
    });

    testWidgets('actualizar value desde fuera sincroniza el controller',
        (tester) async {
      Widget build(String v) => _wrap(AppFormField(
            label: 'name',
            value: v,
            onChanged: (_) {},
          ));
      await tester.pumpWidget(build('inicial'));
      expect(find.text('inicial'), findsOneWidget);
      await tester.pumpWidget(build('actualizado'));
      expect(find.text('actualizado'), findsOneWidget);
      expect(find.text('inicial'), findsNothing);
    });

    testWidgets('enabled=false deshabilita el TextField', (tester) async {
      await tester.pumpWidget(
        _wrap(AppFormField(
          label: 'x',
          value: 'foo',
          enabled: false,
          onChanged: (_) {},
        )),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
    });
  });
}
