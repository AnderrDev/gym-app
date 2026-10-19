import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_catalog_item.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_exercises_catalog.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/session_exercise_sheet.dart';

class MockCatalog extends Mock implements GetExercisesCatalog {}

void main() {
  late MockCatalog catalog;
  const items = [
    ExerciseCatalogItem(id: 'a', name: 'Sentadilla', muscleGroup: 'Piernas'),
    ExerciseCatalogItem(id: 'b', name: 'Remo', muscleGroup: 'Espalda'),
  ];
  setUp(() {
    catalog = MockCatalog();
    when(
      () => catalog(search: any(named: 'search')),
    ).thenAnswer((_) async => const Right(items));
  });

  Future<void> open(
    WidgetTester tester, {
    Set<String> excluded = const {},
    ValueChanged<SessionExerciseSelection?>? onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await SessionExerciseSheet.show(
                  context,
                  getCatalog: catalog,
                  excludedExerciseIds: excluded,
                );
                onResult?.call(result);
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'returns selected catalog id and confirmed targets including comma decimal',
    (tester) async {
      SessionExerciseSelection? result;
      await open(tester, onResult: (value) => result = value);
      await tester.tap(find.text('Remo'));
      await tester.enterText(find.widgetWithText(TextField, 'Series'), '4');
      await tester.enterText(
        find.widgetWithText(TextField, 'Repeticiones'),
        '12',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Peso (kg)'),
        '22,5',
      );
      await tester.ensureVisible(find.text('Añadir ejercicio extra').last);
      await tester.tap(find.text('Añadir ejercicio extra').last);
      await tester.pumpAndSettle();
      expect(result?.exerciseId, 'b');
      expect(result?.targetSets, 4);
      expect(result?.targetReps, 12);
      expect(result?.targetWeight, 22.5);
    },
  );

  testWidgets('excludes exercises already in session', (tester) async {
    await open(tester, excluded: {'a'});
    expect(find.text('Sentadilla'), findsNothing);
    expect(find.text('Remo'), findsOneWidget);
  });

  testWidgets(
    'invalid numeric targets prevent confirmation and cancel returns null',
    (tester) async {
      var returned = false;
      await open(
        tester,
        onResult: (value) {
          returned = true;
          expect(value, isNull);
        },
      );
      await tester.tap(find.text('Remo'));
      for (final value in ['-1', 'NaN', 'Infinity', '10001', '']) {
        await tester.enterText(
          find.widgetWithText(TextField, 'Peso (kg)'),
          value,
        );
        await tester.pump();
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
      }
      await tester.enterText(find.widgetWithText(TextField, 'Peso (kg)'), '0');
      await tester.enterText(find.widgetWithText(TextField, 'Series'), '101');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.enterText(find.widgetWithText(TextField, 'Series'), '3');
      await tester.enterText(
        find.widgetWithText(TextField, 'Repeticiones'),
        '0',
      );
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text('Cancelar'));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(returned, isTrue);
    },
  );

  testWidgets('catalog failure offers retry', (tester) async {
    when(
      () => catalog(search: any(named: 'search')),
    ).thenAnswer((_) async => const Left(ServerFailure('fallo')));
    await open(tester);
    expect(find.text('Reintentar'), findsOneWidget);
    when(
      () => catalog(search: any(named: 'search')),
    ).thenAnswer((_) async => const Right(items));
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Remo'), findsOneWidget);
  });

  testWidgets('search debounces requests and ignores stale responses', (
    tester,
  ) async {
    final stale = Completer<Either<Failure, List<ExerciseCatalogItem>>>();
    when(() => catalog(search: 'old')).thenAnswer((_) => stale.future);
    when(
      () => catalog(search: 'new'),
    ).thenAnswer((_) async => Right([items[1]]));
    await open(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Buscar ejercicio'),
      'old',
    );
    await tester.pump(const Duration(milliseconds: 260));
    await tester.enterText(
      find.widgetWithText(TextField, 'Buscar ejercicio'),
      'new',
    );
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump();
    stale.complete(Right([items[0]]));
    await tester.pumpAndSettle();
    expect(find.text('Remo'), findsOneWidget);
    expect(find.text('Sentadilla'), findsNothing);
  });

  testWidgets(
    'replacement uses remaining sets and fresh weight on narrow viewport',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SessionExerciseSelection? result;
      const original = Exercise(
        id: 'a',
        routineDayId: 'day',
        name: 'Sentadilla',
        targetMuscle: 'Piernas',
        targetWeight: 80,
        targetReps: 6,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await SessionExerciseSheet.show(
                    context,
                    getCatalog: catalog,
                    excludedExerciseIds: {'a'},
                    replacing: original,
                    remainingSets: 2,
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remo'));
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(result?.targetSets, 2);
      expect(result?.targetReps, 10);
      expect(result?.targetWeight, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
