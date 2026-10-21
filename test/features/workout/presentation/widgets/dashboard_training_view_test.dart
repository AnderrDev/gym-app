import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_weekly_view.dart';

void main() {
  Widget view(
    List<RoutineDay> days,
    void Function(RoutineDay, DateTime) onOpen,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return MaterialApp(
      home: Scaffold(
        body: DashboardWeeklyView(
          days: days,
          weekStart: today.subtract(Duration(days: today.weekday - 1)),
          selectedRoutine: const Routine(
            id: 'r1',
            name: 'Fuerza',
            exerciseCount: 3,
          ),
          insights: null,
          insightsError: null,
          onPreviousWeek: () {},
          onNextWeek: () {},
          onOpenSelectedRoutineStats: () {},
          onOpenDay: onOpen,
        ),
      ),
    );
  }

  testWidgets('historial usa la fecha realizada y no el día programado', (
    tester,
  ) async {
    final now = DateTime.now();
    final actual = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    DateTime? opened;
    await tester.pumpWidget(
      view([
        RoutineDay(
          id: 'd1',
          routineId: 'r1',
          dayOfWeek: 1,
          name: 'Pecho',
          status: WorkoutDayStatus.completed,
          lastSessionDate: actual,
        ),
      ], (_, date) => opened = date),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Realizado el'), findsOneWidget);
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text('Entrenar hoy'), findsNothing);
    await tester.tap(find.text('Ver sesión'));
    expect(opened, actual);
  });

  testWidgets('móvil con nombres largos mantiene el botón accesible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      view(const [
        RoutineDay(
          id: 'd1',
          routineId: 'r1',
          dayOfWeek: 1,
          name: 'Pecho, hombros y tríceps — entrenamiento de fuerza',
          exerciseNamesPreview: [
            'Press de banca con mancuernas',
            'Extensión de tríceps en polea alta',
          ],
        ),
      ], (_, _) {}),
    );
    await tester.pumpAndSettle();
    expect(find.text('Entrenar hoy').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rutina vacía muestra instrucciones en lugar de cargar indefinidamente',
    (tester) async {
      await tester.pumpWidget(view(const [], (_, _) {}));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('todavía no tiene entrenamientos'),
        findsOneWidget,
      );
    },
  );
  testWidgets('entrenar una rutina de lunes abre la fecha real de hoy', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardWeeklyView(
            days: const [
              RoutineDay(
                id: 'd1',
                routineId: 'r1',
                dayOfWeek: 1,
                name: 'Pecho y tríceps',
              ),
            ],
            weekStart: today.subtract(Duration(days: today.weekday - 1)),
            selectedRoutine: const Routine(
              id: 'r1',
              name: 'Fuerza',
              exerciseCount: 3,
            ),
            insights: null,
            insightsError: null,
            onPreviousWeek: () {},
            onNextWeek: () {},
            onOpenSelectedRoutineStats: () {},
            onOpenDay: (_, date) => opened = date,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Descanso'), findsNothing);
    expect(find.text('Entrenar hoy'), findsOneWidget);
    await tester.tap(find.text('Entrenar hoy'));
    expect(opened, today);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con todos los días hechos muestra "semana completada"', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await tester.pumpWidget(
      view([
        RoutineDay(
          id: 'd1',
          routineId: 'r1',
          dayOfWeek: 1,
          name: 'Pecho',
          status: WorkoutDayStatus.completed,
          lastSessionDate: today,
        ),
      ], (_, _) {}),
    );
    await tester.pumpAndSettle();
    expect(find.text('¡Semana completada!'), findsOneWidget);
    expect(find.text('TE TOCA HOY'), findsNothing);
  });

  testWidgets('pinta las métricas de la semana cuando hay sesiones', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardWeeklyView(
            days: const [
              RoutineDay(id: 'd1', routineId: 'r1', dayOfWeek: 1, name: 'A'),
            ],
            weekStart: weekStart,
            selectedRoutine: const Routine(
              id: 'r1',
              name: 'Fuerza',
              exerciseCount: 3,
            ),
            insights: WeeklyInsights(
              weekStart: weekStart,
              weekEnd: weekStart.add(const Duration(days: 6)),
              plannedDays: 4,
              completedDays: 2,
              completedSessions: 2,
              adherenceRate: 50,
              totalVolume: 12345,
              previousWeekVolume: 10000,
              volumeTrendPercent: 23.4,
              personalRecords: 1,
            ),
            insightsError: null,
            onPreviousWeek: () {},
            onNextWeek: () {},
            onOpenSelectedRoutineStats: () {},
            onOpenDay: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('12.345 kg'), findsOneWidget);
    expect(find.text('+23 %'), findsOneWidget);
    expect(find.text('50 %'), findsOneWidget);
  });

  testWidgets('un plan de otra semana vuelve solo a la semana actual', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastWeek = today.subtract(Duration(days: today.weekday - 1 + 7));
    var refreshes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardWeeklyView(
            days: const [
              RoutineDay(id: 'd1', routineId: 'r1', dayOfWeek: 1, name: 'A'),
            ],
            weekStart: lastWeek,
            selectedRoutine: null,
            insights: null,
            insightsError: null,
            onPreviousWeek: () {},
            onNextWeek: () {},
            onOpenSelectedRoutineStats: () {},
            onOpenDay: (_, _) {},
            onCurrentWeek: () => refreshes++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump();
    expect(refreshes, 1);
  });
}
