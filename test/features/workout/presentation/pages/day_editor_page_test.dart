import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/auth/domain/entities/user.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/pages/day_editor_page.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_catalog_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkoutBloc extends Mock implements WorkoutBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockWorkoutBloc mockWorkoutBloc;
  late MockAuthBloc mockAuthBloc;
  late MockGoRouter mockGoRouter;

  final tExercise = Exercise(
    id: 'e1',
    routineDayId: 'd1',
    name: 'Press Banca',
    targetMuscle: 'Pecho',
    targetSets: 3,
    targetReps: 10,
    targetWeight: 60,
    restTimerSeconds: 90,
  );

  final tDay = RoutineDay(
    id: 'd1',
    routineId: 'r1',
    name: 'Pecho y Triceps',
    dayOfWeek: 1,
    exercises: [tExercise],
  );

  setUpAll(() {
    registerFallbackValue(
      SaveRoutineDay(userId: 'u1', routineId: 'r1', day: tDay),
    );
    registerFallbackValue(
      const ReorderExercises(
        userId: 'u1',
        routineId: 'r1',
        dayId: 'd1',
        exerciseIds: ['e1'],
      ),
    );
    registerFallbackValue(
      const ToggleExerciseInDay(
        userId: 'u1',
        routineId: 'r1',
        dayId: 'd1',
        exerciseId: 'e1',
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
    when(() => mockWorkoutBloc.close()).thenAnswer((_) async {});
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
          child: DayEditorPage(routineId: 'r1', day: tDay),
        ),
      ),
    );
  }

  testWidgets('debe mostrar el nombre del día y la lista de ejercicios', (
    tester,
  ) async {
    when(() => mockWorkoutBloc.state).thenReturn(WorkoutInitial());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('PECHO Y TRICEPS'), findsWidgets); // Titulo y TextField
    expect(find.text('PRESS BANCA'), findsOneWidget);
    expect(find.text('PECHO'), findsOneWidget);
  });

  testWidgets('debe disparar SaveRoutineDay al presionar GUARDAR', (
    tester,
  ) async {
    when(() => mockWorkoutBloc.state).thenReturn(WorkoutInitial());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('GUARDAR'));
    await tester.pump();

    verify(
      () => mockWorkoutBloc.add(any(that: isA<SaveRoutineDay>())),
    ).called(1);
  });

  testWidgets('debe mostrar el catálogo de ejercicios al presionar el FAB', (
    tester,
  ) async {
    when(() => mockWorkoutBloc.state).thenReturn(WorkoutInitial());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('CATÁLOGO'));
    await tester.pumpAndSettle();

    expect(find.byType(ExerciseCatalogSheet), findsOneWidget);
  });

  testWidgets(
    'debe disparar ToggleExerciseInDay al deslizar para eliminar un ejercicio',
    (tester) async {
      when(() => mockWorkoutBloc.state).thenReturn(WorkoutInitial());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Deslizar el ejercicio hacia la izquierda
      await tester.drag(find.text('PRESS BANCA'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      verify(
        () => mockWorkoutBloc.add(any(that: isA<ToggleExerciseInDay>())),
      ).called(1);
    },
  );

  testWidgets(
    'debe mostrar un mensaje de éxito cuando el estado es ManagementSuccess',
    (tester) async {
      final controller = StreamController<WorkoutState>.broadcast();
      when(() => mockWorkoutBloc.state).thenReturn(WorkoutInitial());
      when(() => mockWorkoutBloc.stream).thenAnswer((_) => controller.stream);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      controller.add(const ManagementSuccess('Día guardado'));
      await tester.pump(); // Listener
      await tester.pump(); // SnackBar animation start

      expect(find.text('Día guardado'), findsOneWidget);
      await controller.close();
    },
  );

  testWidgets(
    'debe mostrar un mensaje de error cuando el estado es WorkoutError',
    (tester) async {
      final controller = StreamController<WorkoutState>.broadcast();
      when(() => mockWorkoutBloc.state).thenReturn(WorkoutInitial());
      when(() => mockWorkoutBloc.stream).thenAnswer((_) => controller.stream);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      controller.add(const WorkoutError('Error al guardar'));
      await tester.pump(); // Listener
      await tester.pump(); // SnackBar animation start

      expect(find.text('Error: Error al guardar'), findsOneWidget);
      await controller.close();
    },
  );

  testWidgets('debe mostrar mensaje de lista vacía cuando no hay ejercicios', (
    tester,
  ) async {
    final emptyDay = tDay.copyWith(exercises: []);
    when(() => mockWorkoutBloc.state).thenReturn(WorkoutInitial());

    await tester.pumpWidget(
      MaterialApp(
        home: InheritedGoRouter(
          goRouter: mockGoRouter,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<WorkoutBloc>.value(value: mockWorkoutBloc),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: DayEditorPage(routineId: 'r1', day: emptyDay),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Dale a "+" para añadir ejercicios'), findsOneWidget);
  });
}
