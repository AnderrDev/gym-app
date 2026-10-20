import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_active_focus_view.dart';

void main() {
  const exercise = Exercise(
    id: 'e1',
    routineDayId: 'd1',
    name: 'Press banca',
    targetMuscle: 'Pecho',
    targetWeight: 60,
    targetReps: 10,
  );
  Widget view({
    List<Exercise> exercises = const [exercise],
    List<SetLog> logs = const [],
    bool readOnly = false,
    bool busy = false,
    VoidCallback? add,
    ValueChanged<Exercise>? replace,
    ValueChanged<SetLog>? onAdded,
    void Function(String exerciseId, int setIndex)? onRemoved,
    VoidCallback? onUndone,
  }) => MaterialApp(
    home: Scaffold(
      body: RoutineDayActiveFocusView(
        sessionId: 's1',
        exercises: exercises,
        completedLogs: logs,
        lastPerformances: const {},
        coachingAnalyses: const {},
        effectiveReadOnly: readOnly,
        isAdapting: busy,
        onSetAdded: onAdded ?? (_) {},
        onSetRemoved: onRemoved,
        onQuickSetUndone: onUndone,
        onAddExercise: add ?? () {},
        onReplaceExercise: replace ?? (_) {},
      ),
    ),
  );

  testWidgets('sustituir el ejercicio está en el menú ⋮ de la tarjeta', (
    tester,
  ) async {
    Exercise? replaced;
    await tester.pumpWidget(view(replace: (ex) => replaced = ex));
    await tester.pumpAndSettle();
    // Fuera del espacio principal: ni "Sustituir" ni "Añadir extra" a la vista.
    expect(find.text('Sustituir ejercicio'), findsNothing);
    expect(find.text('Añadir ejercicio extra'), findsNothing);
    await tester.tap(find.byTooltip('Opciones del ejercicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sustituir ejercicio'));
    await tester.pumpAndSettle();
    expect(replaced, exercise);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'series conservadas muestran sus índices reales aunque haya huecos',
    (tester) async {
      await tester.pumpWidget(
        view(
          exercises: [
            exercise.copyWith(
              targetSets: 2,
              replacedByExerciseName: 'Press máquina',
            ),
          ],
          logs: const [
            SetLog(
              sessionId: 's1',
              exerciseId: 'e1',
              setIndex: 1,
              actualWeight: 60,
              actualReps: 10,
            ),
            SetLog(
              sessionId: 's1',
              exerciseId: 'e1',
              setIndex: 3,
              actualWeight: 65,
              actualReps: 8,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Serie 3 · 65.0 kg × 8'), findsOneWidget);
      expect(find.text('Sustituir ejercicio'), findsNothing);
    },
  );

  testWidgets('sesión cerrada no permite adaptar ejercicios', (tester) async {
    await tester.pumpWidget(view(readOnly: true));
    await tester.pumpAndSettle();
    expect(find.text('Sustituir ejercicio'), findsNothing);
    expect(find.text('Añadir ejercicio extra'), findsNothing);
  });

  testWidgets(
    'el botón fijo registra la serie siguiente de un toque y se puede deshacer',
    (tester) async {
      const ex = Exercise(
        id: 'e1',
        routineDayId: 'd1',
        name: 'Press banca',
        targetMuscle: 'Pecho',
        targetWeight: 60,
        targetReps: 10,
        targetSets: 3,
      );
      final added = <SetLog>[];
      final removed = <int>[];
      var undone = 0;
      await tester.pumpWidget(
        view(
          exercises: const [ex],
          logs: const [
            SetLog(
              sessionId: 's1',
              exerciseId: 'e1',
              actualWeight: 62.5,
              actualReps: 9,
              setIndex: 1,
            ),
          ],
          onAdded: added.add,
          onRemoved: (_, i) => removed.add(i),
          onUndone: () => undone++,
        ),
      );
      await tester.pumpAndSettle();

      final bar = find.byKey(const ValueKey('focus_complete_set_button'));
      // Propone lo de la serie anterior, no el objetivo.
      expect(find.text('Serie 2 hecha · 62.5 kg × 9'), findsOneWidget);
      // Sólo uno: el de dentro de la tarjeta ya no se pinta en esta vista.
      expect(
        find.byKey(const ValueKey('complete_set_button_e1')),
        findsNothing,
      );

      await tester.tap(bar);
      await tester.pumpAndSettle();
      expect(find.text('CONFIRMAR SERIE'), findsNothing);
      expect(added.single.setIndex, 2);
      expect(added.single.actualWeight, 62.5);
      expect(added.single.actualReps, 9);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(removed, [2]);
      expect(undone, 1);
    },
  );

  testWidgets('sin peso que proponer el botón abre la hoja para confirmar', (
    tester,
  ) async {
    const bodyweight = Exercise(
      id: 'e1',
      routineDayId: 'd1',
      name: 'Dominadas',
      targetMuscle: 'Espalda',
      targetWeight: 0,
      targetReps: 8,
    );
    final added = <SetLog>[];
    await tester.pumpWidget(
      view(exercises: const [bodyweight], onAdded: added.add),
    );
    await tester.pumpAndSettle();
    expect(find.text('Registrar serie 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('focus_complete_set_button')));
    await tester.pumpAndSettle();
    expect(find.text('CONFIRMAR SERIE'), findsOneWidget);
    expect(added, isEmpty);
  });

  testWidgets('en solo lectura no hay botón fijo', (tester) async {
    await tester.pumpWidget(view(readOnly: true));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('focus_complete_set_button')),
      findsNothing,
    );
  });
}
