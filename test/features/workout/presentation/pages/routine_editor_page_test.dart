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
import 'package:gym_flutter/features/workout/presentation/routine_management/pages/routine_editor_page.dart';
import 'package:gym_flutter/core/presentation/widgets/kinetic_button.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkoutBloc extends Mock implements WorkoutBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockWorkoutBloc mockWorkoutBloc;
  late MockAuthBloc mockAuthBloc;
  late MockGoRouter mockGoRouter;
  final tNow = DateTime(2023, 1, 1);

  setUpAll(() {
    registerFallbackValue(
      FetchWeeklyPlan(userId: 'u1', routineId: 'r1', weekStart: DateTime.now()),
    );
    registerFallbackValue(
      const CreateOrUpdateRoutine(userId: 'u1', name: 'Test', isPublic: false),
    );
    registerFallbackValue(const DeleteRoutine(userId: 'u1', routineId: 'r1'));
    registerFallbackValue(
      SaveRoutineDay(
        userId: 'u1',
        routineId: 'r1',
        day: RoutineDay(
          id: '',
          routineId: 'r1',
          name: '',
          dayOfWeek: 1,
          exercises: const [],
        ),
      ),
    );
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

    when(() => mockWorkoutBloc.stream).thenAnswer((_) => Stream.empty());
  });

  Widget createWidgetUnderTest({String? routineId}) {
    return MaterialApp(
      home: InheritedGoRouter(
        goRouter: mockGoRouter,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<WorkoutBloc>.value(value: mockWorkoutBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: RoutineEditorPage(routineId: routineId),
        ),
      ),
    );
  }

  final tRoutine = Routine(
    id: 'r1',
    creatorId: 'user123',
    name: 'Full Body',
    exerciseCount: 2,
    isPublic: true,
  );

  final tDays = [
    RoutineDay(
      id: 'd1',
      routineId: 'r1',
      name: 'Lunes',
      dayOfWeek: 1,
      exercises: const [],
    ),
  ];

  testWidgets('debe cargar el plan semanal al iniciar si hay routineId', (
    tester,
  ) async {
    when(() => mockWorkoutBloc.state).thenReturn(WorkoutInitial());

    await tester.pumpWidget(createWidgetUnderTest(routineId: 'r1'));

    verify(
      () => mockWorkoutBloc.add(any(that: isA<FetchWeeklyPlan>())),
    ).called(1);
  });

  testWidgets('debe mostrar "NUEVA RUTINA" cuando no hay routineId', (
    tester,
  ) async {
    when(() => mockWorkoutBloc.state).thenReturn(WorkoutInitial());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('NUEVA RUTINA'), findsOneWidget);
  });

  testWidgets('debe pre-poblar campos cuando se carga una rutina existente', (
    tester,
  ) async {
    when(
      () => mockWorkoutBloc.state,
    ).thenReturn(WeeklyPlanLoaded(tDays, tNow, routine: tRoutine));

    await tester.pumpWidget(createWidgetUnderTest(routineId: 'r1'));
    await tester.pumpAndSettle();

    expect(find.text('FULL BODY'), findsOneWidget);
    expect(find.text('1 DÍAS'), findsOneWidget);
    expect(find.text('LUNES'), findsOneWidget);

    final switchWidget = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(switchWidget.value, isTrue);
  });

  testWidgets('debe disparar CreateOrUpdateRoutine al presionar GUARDAR', (
    tester,
  ) async {
    when(
      () => mockWorkoutBloc.state,
    ).thenReturn(WeeklyPlanLoaded(tDays, tNow, routine: tRoutine));

    await tester.pumpWidget(createWidgetUnderTest(routineId: 'r1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('GUARDAR'));
    await tester.pump();

    verify(
      () => mockWorkoutBloc.add(any(that: isA<CreateOrUpdateRoutine>())),
    ).called(1);
  });

  testWidgets('debe disparar SaveRoutineDay al presionar AÑADIR DÍA', (
    tester,
  ) async {
    when(
      () => mockWorkoutBloc.state,
    ).thenReturn(WeeklyPlanLoaded(tDays, tNow, routine: tRoutine));

    await tester.pumpWidget(createWidgetUnderTest(routineId: 'r1'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(KineticButton));
    await tester.tap(find.byType(KineticButton));
    await tester.pump();

    verify(
      () => mockWorkoutBloc.add(any(that: isA<SaveRoutineDay>())),
    ).called(1);
  });

  testWidgets('debe mostrar diálogo de confirmación y borrar al confirmar', (
    tester,
  ) async {
    when(
      () => mockWorkoutBloc.state,
    ).thenReturn(WeeklyPlanLoaded(tDays, tNow, routine: tRoutine));

    await tester.pumpWidget(createWidgetUnderTest(routineId: 'r1'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar Rutina?'), findsOneWidget);

    await tester.tap(find.text('ELIMINAR'));
    await tester.pump();

    verify(
      () => mockWorkoutBloc.add(any(that: isA<DeleteRoutine>())),
    ).called(1);
  });

  testWidgets('debe cerrar la página y mostrar snackbar en ManagementSuccess', (
    tester,
  ) async {
    when(
      () => mockWorkoutBloc.state,
    ).thenReturn(WeeklyPlanLoaded(tDays, tNow, routine: tRoutine));
    when(() => mockWorkoutBloc.stream).thenAnswer(
      (_) => Stream.value(const ManagementSuccess('Guardado correctamente')),
    );
    when(() => mockGoRouter.pop<bool>(any())).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest(routineId: 'r1'));
    await tester.pump(); // Listen to stream

    expect(find.text('Guardado correctamente'), findsOneWidget);
    verify(() => mockGoRouter.pop<bool>(false)).called(1);
  });
}
