import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/presentation/widgets/exercise_catalog_sheet.dart';

void main() {
  Widget createWidgetUnderTest({List<String> selectedExerciseIds = const []}) {
    return MaterialApp(
      home: Scaffold(
        body: ExerciseCatalogSheet(selectedExerciseIds: selectedExerciseIds),
      ),
    );
  }

  testWidgets('debe mostrar el título y la lista de ejercicios', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Press de Banca Plano'), findsOneWidget);

    // Filtrar para encontrar uno que esté mas abajo
    await tester.enterText(find.byType(TextField), 'Sentadilla');
    await tester.pump();
    expect(find.text('Sentadilla Libre'), findsOneWidget);
  });

  testWidgets('debe filtrar ejercicios por búsqueda', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(find.byType(TextField), 'Sentadilla');
    await tester.pump();

    expect(find.text('Sentadilla Libre'), findsOneWidget);
    expect(find.text('Press de Banca Plano'), findsNothing);
  });

  testWidgets('debe filtrar ejercicios por categoría', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Usar find.descendant para ser específicos con el ChoiceChip
    final categoryChip = find.widgetWithText(ChoiceChip, 'Pecho');
    await tester.tap(categoryChip);
    await tester.pump();

    expect(find.text('Press de Banca Plano'), findsOneWidget);
    expect(find.text('Sentadilla Libre'), findsNothing);
  });

  testWidgets('debe permitir seleccionar ejercicios y mostrar contador', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('0 seleccionados'), findsOneWidget);

    await tester.tap(find.text('Press de Banca Plano'));
    await tester.pump();

    expect(find.text('1 seleccionados'), findsOneWidget);
    expect(find.text('Añadir 1 ejercicios'), findsOneWidget);

    await tester.tap(find.text('Press Inclinado Manc.'));
    await tester.pump();

    expect(find.text('2 seleccionados'), findsOneWidget);
    expect(find.text('Añadir 2 ejercicios'), findsOneWidget);
  });

  testWidgets('debe deshabilitar ejercicios ya presentes en la rutina', (
    tester,
  ) async {
    await tester.pumpWidget(
      createWidgetUnderTest(selectedExerciseIds: ['Press de Banca Plano']),
    );

    expect(find.text('Ya en tu rutina'), findsOneWidget);

    // Al tocar no debería aumentar el contador
    await tester.tap(find.text('Press de Banca Plano'));
    await tester.pump();

    expect(find.text('0 seleccionados'), findsOneWidget);
  });

  testWidgets(
    'debe retornar la lista seleccionada al presionar el botón de añadir',
    (tester) async {
      List<Map<String, String>>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result =
                      await showModalBottomSheet<List<Map<String, String>>>(
                        context: context,
                        builder: (_) => const ExerciseCatalogSheet(),
                      );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Press de Banca Plano'));
      await tester.pump();

      await tester.tap(find.text('Añadir 1 ejercicios'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result![0]['name'], 'Press de Banca Plano');
    },
  );
}
