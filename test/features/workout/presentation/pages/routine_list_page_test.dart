import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/auth/domain/entities/user.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/pages/routine_list_page.dart';
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
    registerFallbackValue(const FetchAllRoutines());
  });

  setUp(() {
    mockWorkoutBloc = MockWorkoutBloc();
    mockAuthBloc = MockAuthBloc();
    mockGoRouter = MockGoRouter();

    // Mock Auth state
    when(() => mockAuthBloc.state).thenReturn(
      const Authenticated(
        User(id: 'user123', email: 'test@test.com', fullName: 'Tester'),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.empty());
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
          child: const RoutineListPage(),
        ),
      ),
    );
  }

  final tRoutines = [
    Routine(
      id: 'r1',
      creatorId: 'user123',
      name: 'My Custom Routine',
      exerciseCount: 5,
      isPublic: false,
    ),
    Routine(
      id: 'r2',
      creatorId: 'other_user',
      name: 'Community Routine',
      exerciseCount: 8,
      isPublic: true,
    ),
  ];

  testWidgets(
    'debe mostrar cargando cuando no hay rutinas y está en WorkoutLoading',
    (tester) async {
      when(() => mockWorkoutBloc.state).thenReturn(WorkoutLoading());
      when(
        () => mockWorkoutBloc.stream,
      ).thenAnswer((_) => Stream.value(WorkoutLoading()));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      verify(() => mockWorkoutBloc.add(const FetchAllRoutines())).called(1);
    },
  );

  testWidgets('debe mostrar la lista de rutinas cuando AllRoutinesLoaded', (
    tester,
  ) async {
    when(() => mockWorkoutBloc.state).thenReturn(AllRoutinesLoaded(tRoutines));
    when(() => mockWorkoutBloc.stream).thenAnswer((_) => Stream.empty());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('MY CUSTOM ROUTINE'), findsOneWidget);
    expect(find.text('COMMUNITY ROUTINE'), findsOneWidget);
    expect(find.text('5 EJERCICIOS'), findsOneWidget);
    expect(find.text('8 EJERCICIOS'), findsOneWidget);
  });

  testWidgets('debe filtrar rutinas propias cuando se selecciona MIS RUTINAS', (
    tester,
  ) async {
    when(() => mockWorkoutBloc.state).thenReturn(AllRoutinesLoaded(tRoutines));
    when(() => mockWorkoutBloc.stream).thenAnswer((_) => Stream.empty());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap on MIS RUTINAS chip (specifically the one in the filter row)
    final misRutinasChip = find.descendant(
      of: find.byType(SingleChildScrollView),
      matching: find.text('MIS RUTINAS'),
    );
    await tester.tap(misRutinasChip);
    await tester.pump();

    expect(find.text('MY CUSTOM ROUTINE'), findsOneWidget);
    expect(find.text('COMMUNITY ROUTINE'), findsNothing);
  });

  testWidgets(
    'debe filtrar rutinas de la comunidad cuando se selecciona COMUNIDAD',
    (tester) async {
      when(
        () => mockWorkoutBloc.state,
      ).thenReturn(AllRoutinesLoaded(tRoutines));
      when(() => mockWorkoutBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap on COMUNIDAD chip (specifically the one in the filter row)
      final comunidadChip = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.text('COMUNIDAD'),
      );
      await tester.tap(comunidadChip);
      await tester.pump();

      expect(find.text('MY CUSTOM ROUTINE'), findsNothing);
      expect(find.text('COMMUNITY ROUTINE'), findsOneWidget);
    },
  );

  testWidgets('debe mostrar mensaje de éxito cuando ManagementSuccess', (
    tester,
  ) async {
    when(() => mockWorkoutBloc.state).thenReturn(AllRoutinesLoaded(tRoutines));
    // Simular que el bloc emite ManagementSuccess después de cargar
    when(() => mockWorkoutBloc.stream).thenAnswer(
      (_) => Stream.value(const ManagementSuccess('Rutina activada')),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Inicia el listener

    expect(find.text('Rutina activada'), findsOneWidget);
  });

  testWidgets('debe mostrar error cuando WorkoutError', (tester) async {
    const tMessage = 'Error al cargar rutinas';
    when(() => mockWorkoutBloc.state).thenReturn(const WorkoutError(tMessage));
    when(() => mockWorkoutBloc.stream).thenAnswer((_) => Stream.empty());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text(tMessage), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
