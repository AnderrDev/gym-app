import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_catalog_item.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_catalog_sheet.dart';

void main() {
  const catalog = <ExerciseCatalogItem>[
    ExerciseCatalogItem(
      id: 'e1',
      name: 'Press de Banca Plano',
      muscleGroup: 'Pecho',
    ),
    ExerciseCatalogItem(
      id: 'e2',
      name: 'Press Inclinado Manc.',
      muscleGroup: 'Pecho',
    ),
    ExerciseCatalogItem(
      id: 'e3',
      name: 'Sentadilla Libre',
      muscleGroup: 'Pierna',
    ),
  ];

  Widget createWidgetUnderTest({Set<String> alreadySelectedIds = const {}}) {
    return MaterialApp(
      home: Scaffold(
        body: ExerciseCatalogSheet(
          catalog: catalog,
          alreadySelectedIds: alreadySelectedIds,
        ),
      ),
    );
  }

  testWidgets('debe mostrar el título y la lista de ejercicios', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Press de Banca Plano'), findsOneWidget);

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

  testWidgets(
    'debe deshabilitar ejercicios ya presentes en la rutina',
    (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(alreadySelectedIds: const {'e1'}),
      );

      expect(find.text('Ya en tu rutina'), findsOneWidget);

      await tester.tap(find.text('Press de Banca Plano'));
      await tester.pump();

      expect(find.text('0 seleccionados'), findsOneWidget);
    },
  );

  testWidgets(
    'debe retornar la lista seleccionada al presionar el botón de añadir',
    (tester) async {
      List<ExerciseCatalogItem>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showModalBottomSheet<List<ExerciseCatalogItem>>(
                    context: context,
                    builder: (_) => const ExerciseCatalogSheet(catalog: catalog),
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
      expect(result![0].name, 'Press de Banca Plano');
    },
  );
}
