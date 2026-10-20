import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/ui/atoms/app_button.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/complete_set_sheet.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    ValueChanged<CompleteSetResult?>? onResult,
    double weight = 0,
    int reps = 10,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await CompleteSetSheet.show(
                  context,
                  exerciseName: 'Flexiones',
                  setNumber: 1,
                  targetSets: 3,
                  targetWeight: 0,
                  targetReps: 10,
                  initialWeight: weight,
                  initialReps: reps,
                  isDone: false,
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

  Finder getConfirm() => find.byKey(const ValueKey('complete_set_confirm'));

  testWidgets('confirms bodyweight set with zero kg and ten reps', (
    tester,
  ) async {
    CompleteSetResult? result;
    await open(tester, onResult: (value) => result = value);
    expect(tester.widget<AppButton>(getConfirm()).onPressed, isNotNull);
    await tester.ensureVisible(getConfirm());
    await tester.tap(getConfirm());
    await tester.pumpAndSettle();
    expect(result, isA<CompleteSetSave>());
    expect((result as CompleteSetSave).weight, 0);
    expect((result as CompleteSetSave).reps, 10);
  });

  testWidgets('empty weight and targets outside bounds cannot be confirmed', (
    tester,
  ) async {
    await open(tester);
    for (final value in ['', '10001']) {
      await tester.enterText(
        find.byKey(const ValueKey('complete_set_weight')),
        value,
      );
      await tester.pump();
      expect(tester.widget<AppButton>(getConfirm()).onPressed, isNull);
    }
    await tester.enterText(
      find.byKey(const ValueKey('complete_set_weight')),
      '0',
    );
    for (final value in ['0', '1001']) {
      await tester.enterText(
        find.byKey(const ValueKey('complete_set_reps')),
        value,
      );
      await tester.pump();
      expect(tester.widget<AppButton>(getConfirm()).onPressed, isNull);
    }
  });

  for (final invalid in [double.nan, double.infinity, -1.0]) {
    testWidgets('rejects invalid initial weight $invalid', (tester) async {
      await open(tester, weight: invalid);
      expect(tester.widget<AppButton>(getConfirm()).onPressed, isNull);
    });
  }

  testWidgets('objetivo sin carga se muestra como peso corporal', (
    tester,
  ) async {
    await open(tester);
    expect(find.textContaining('Peso corporal'), findsOneWidget);
    expect(find.textContaining('0 kg'), findsNothing);
  });

  testWidgets('"Hecho" en el teclado de repeticiones confirma la serie', (
    tester,
  ) async {
    CompleteSetResult? result;
    await open(tester, onResult: (value) => result = value);
    await tester.tap(find.byKey(const ValueKey('complete_set_reps')));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(result, isA<CompleteSetSave>());
  });
}
