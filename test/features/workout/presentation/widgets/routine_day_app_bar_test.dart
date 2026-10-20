import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_app_bar.dart';

void main() {
  testWidgets('en sesión activa "Añadir ejercicio extra" vive en el menú ⋮', (
    tester,
  ) async {
    var added = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              RoutineDayAppBar(
                routineDay: const RoutineDay(
                  id: 'd1',
                  routineId: 'r1',
                  dayOfWeek: 1,
                  name: 'Pecho',
                ),
                dateLabel: '20 oct 2026',
                lastSession: null,
                lastLogs: const [],
                exercises: const [],
                isActive: true,
                onClose: () {},
                onShowLastSessionDetails: (_, _, _) {},
                onFinish: () {},
                onDiscard: () {},
                onAddExercise: () => added++,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Finalizar'), findsOneWidget);
    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();
    expect(find.text('Descartar entrenamiento'), findsOneWidget);
    await tester.tap(find.text('Añadir ejercicio extra'));
    await tester.pumpAndSettle();
    expect(added, 1);
  });
}
