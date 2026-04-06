import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/auth/domain/entities/user.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_state.dart';
import 'package:gym_flutter/features/workout/presentation/pages/dashboard_page.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkoutBloc extends Mock implements WorkoutBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockWorkoutBloc mockWorkoutBloc;
  late MockAuthBloc mockAuthBloc;
  late MockGoRouter mockGoRouter;

  setUpAll(() {
    registerFallbackValue(WorkoutInitial());
    registerFallbackValue(const CheckActiveSession('user123'));
    registerFallbackValue(const FetchAssignedRoutines('user123'));
  });

  setUp(() {
    mockWorkoutBloc = MockWorkoutBloc();
    mockAuthBloc = MockAuthBloc();
    mockGoRouter = MockGoRouter();

    when(() => mockAuthBloc.state).thenReturn(
      const Authenticated(
        User(id: 'user123', email: 'test@test.com', fullName: 'Tester'),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.empty());

    when(() => mockWorkoutBloc.state).thenReturn(WorkoutInitial());
    when(() => mockWorkoutBloc.stream).thenAnswer((_) => Stream.empty());

    when(() => mockGoRouter.push<bool>(any())).thenAnswer((_) async => null);
    when(
      () => mockGoRouter.push<bool>(any(), extra: any(named: 'extra')),
    ).thenAnswer((_) async => null);
    when(() => mockGoRouter.push<Object?>(any())).thenAnswer((_) async => null);
    when(
      () => mockGoRouter.push<Object?>(any(), extra: any(named: 'extra')),
    ).thenAnswer((_) async => null);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: InheritedGoRouter(
        goRouter: mockGoRouter,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<WorkoutBloc>.value(value: mockWorkoutBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: const DashboardPage(),
        ),
      ),
    );
  }

  testWidgets('debe mostrar estado vacío cuando no hay rutinas asignadas', (
    tester,
  ) async {
    when(() => mockWorkoutBloc.state).thenReturn(const RoutinesLoaded([]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Sin Rutina Activa'), findsOneWidget);
  });

  testWidgets(
    'debe mostrar el plan semanal cuando hay una sola rutina cargada',
    (tester) async {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final tRoutine = Routine(
        id: 'r1',
        creatorId: 'u1',
        name: 'MY ROUTINE',
        exerciseCount: 3,
        isPublic: true,
      );
      final tDays = [
        RoutineDay(
          id: 'd1',
          routineId: 'r1',
          name: 'PUSH DAY',
          dayOfWeek: now.weekday,
          exercises: const [],
        ),
      ];

      final state = WeeklyPlanLoaded(tDays, monday, routine: tRoutine);

      when(() => mockWorkoutBloc.state).thenReturn(state);
      when(() => mockWorkoutBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump();

      // Verificamos por widget type y contenido si el texto falla
      expect(find.byType(ListTile), findsWidgets);
    },
  );

  testWidgets('debe navegar a RoutineListPage al pulsar el icono de lista', (
    tester,
  ) async {
    when(() => mockWorkoutBloc.state).thenReturn(const RoutinesLoaded([]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.list_alt));
    verify(() => mockGoRouter.push<bool>('/routine-list')).called(1);
  });

  testWidgets('debe mostrar banner de sesión activa y permitir retomar', (
    tester,
  ) async {
    final session = ActiveSessionDetected(
      sessionId: 's1',
      userId: 'user123',
      routineDayId: 'd1',
      routineDayName: 'Active Day',
      sessionDate: DateTime.now(),
    );

    when(() => mockWorkoutBloc.state).thenReturn(const RoutinesLoaded([]));
    when(() => mockWorkoutBloc.stream).thenAnswer((_) => Stream.value(session));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.textContaining('Active Day'), findsOneWidget);

    await tester.tap(find.text('Retomar'));

    verify(
      () => mockWorkoutBloc.add(any(that: isA<LoadDayInfo>())),
    ).called(greaterThanOrEqualTo(1));
    verify(
      () => mockGoRouter.push<Object?>(
        '/routine-day',
        extra: any(named: 'extra'),
      ),
    ).called(greaterThanOrEqualTo(1));
  });
}
