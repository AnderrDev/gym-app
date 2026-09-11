import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_set_row.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

void main() {
  group('ExerciseSetRow — chip tap preserva foco (web bug)', () {
    testWidgets(
      'tap en chip +1 incrementa peso, mantiene foco y NO colapsa la fila',
      (tester) async {
        SetLog? saved;
        await tester.pumpWidget(
          _harness(
            ExerciseSetRow(
              setNumber: 1,
              targetReps: 10,
              targetWeight: 20,
              isDone: false,
              completedLog: null,
              lastPerformanceLog: null,
              sessionId: 's1',
              exerciseId: 'e1',
              readOnly: false,
              onSaved: (log) => saved = log,
            ),
          ),
        );

        // Localiza el campo de peso (suffix 'kg').
        final weightField = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.suffixText == 'kg',
        );
        expect(weightField, findsOneWidget);

        // Inicialmente la fila de chips NO está visible.
        expect(find.text('+1'), findsNothing);

        // Foco al campo de peso.
        await tester.tap(weightField);
        await tester.pumpAndSettle();

        // Ahora los chips deberían estar visibles.
        expect(find.text('+1'), findsOneWidget);
        expect(find.text('-1'), findsOneWidget);
        expect(find.text('+2.5'), findsOneWidget);
        expect(find.text('-2.5'), findsOneWidget);

        final weight = tester.widget<TextField>(weightField);
        final focusBefore = weight.focusNode!.hasFocus;
        expect(focusBefore, isTrue, reason: 'campo debe tener foco tras tap');

        // Tap en el chip +1.
        await tester.tap(find.text('+1'));
        await tester.pumpAndSettle();

        // El peso subió de 20 → 21.
        expect(weight.controller!.text, '21');

        // El foco se mantiene en el campo de peso.
        expect(
          weight.focusNode!.hasFocus,
          isTrue,
          reason: 'chip tap NO debe robar foco al TextField',
        );

        // La fila de chips sigue visible.
        expect(
          find.text('+1'),
          findsOneWidget,
          reason: 'chips deben permanecer mounted/visibles tras tap',
        );

        // Segundo tap: el peso sigue subiendo (chip todavía interactivo).
        await tester.tap(find.text('+1'));
        await tester.pumpAndSettle();
        expect(weight.controller!.text, '22');

        // Save no debió haberse disparado (no tocamos ✓).
        expect(saved, isNull);
      },
    );

    testWidgets(
      'tap fuera de la fila (área neutra) sí desfoca y oculta chips [web/desktop]',
      (tester) async {
        // En Flutter, TextField.onTapOutside por defecto solo desfoca en
        // plataformas tipo desktop (incluye web). Android/iOS dejan foco al
        // tocar fuera. Forzamos macOS para reflejar la conducta de web.
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

        await tester.pumpWidget(
          _harness(
            Column(
              children: [
                ExerciseSetRow(
                  setNumber: 1,
                  targetReps: 10,
                  targetWeight: 20,
                  isDone: false,
                  completedLog: null,
                  lastPerformanceLog: null,
                  sessionId: 's1',
                  exerciseId: 'e1',
                  readOnly: false,
                  onSaved: (_) {},
                ),
                const SizedBox(
                  key: ValueKey('outside_sink'),
                  height: 200,
                  child: Center(child: Text('zona neutra')),
                ),
              ],
            ),
          ),
        );

        final weightField = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.suffixText == 'kg',
        );

        await tester.tap(weightField);
        await tester.pumpAndSettle();
        expect(find.text('+1'), findsOneWidget);

        await tester.tap(find.text('zona neutra'));
        await tester.pumpAndSettle();

        final weight = tester.widget<TextField>(weightField);
        expect(weight.focusNode!.hasFocus, isFalse);
        expect(find.text('+1'), findsNothing);

        debugDefaultTargetPlatformOverride = null;
      },
    );
  });
}
