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
        onSetAdded: (_) {},
        onAddExercise: add ?? () {},
        onReplaceExercise: replace ?? (_) {},
      ),
    ),
  );

  testWidgets(
    'permite elegir sustitución y añadir un extra durante la sesión',
    (tester) async {
      var added = false;
      Exercise? replaced;
      await tester.pumpWidget(
        view(add: () => added = true, replace: (ex) => replaced = ex),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sustituir ejercicio'));
      expect(replaced, exercise);
      await tester.tap(find.text('Añadir ejercicio extra'));
      expect(added, true);
      expect(tester.takeException(), isNull);
    },
  );

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
}
