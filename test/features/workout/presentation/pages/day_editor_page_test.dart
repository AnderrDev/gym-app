import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_flutter/features/auth/domain/entities/user.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/pages/day_editor_page.dart';
import 'package:mocktail/mocktail.dart';

class MockRoutineManagementBloc extends Mock implements RoutineManagementBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockRoutineManagementBloc bloc;
  late MockAuthBloc mockAuthBloc;
  late MockGoRouter mockGoRouter;

  const tExercise = Exercise(
    id: 'e1',
    routineDayId: 'd1',
    name: 'Press Banca',
    targetMuscle: 'Pecho',
    targetSets: 3,
    targetReps: 10,
    targetWeight: 60,
    restTimerSeconds: 90,
  );

  const tDay = RoutineDay(
    id: 'd1',
    routineId: 'r1',
    name: 'Pecho y Triceps',
    dayOfWeek: 1,
    exercises: [tExercise],
  );

  setUpAll(() {
    registerFallbackValue(
      const SaveDay(userId: 'u1', routineId: 'r1', day: tDay),
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
      const RemoveExerciseFromDayEvent(
        userId: 'u1',
        routineId: 'r1',
        dayId: 'd1',
        exerciseId: 'e1',
      ),
    );
  });

  setUp(() {
    bloc = MockRoutineManagementBloc();
    mockAuthBloc = MockAuthBloc();
    mockGoRouter = MockGoRouter();
    when(() => mockAuthBloc.state).thenReturn(
      const Authenticated(
        User(id: 'u1', email: 'test@test.com', fullName: 'Tester'),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.close()).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: InheritedGoRouter(
        goRouter: mockGoRouter,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<RoutineManagementBloc>.value(value: bloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: const DayEditorPage(routineId: 'r1', day: tDay),
        ),
      ),
    );
  }

  testWidgets('muestra el nombre del día y la lista de ejercicios', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(const RoutineManagementState());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('PRESS BANCA'), findsOneWidget);
    // El nombre del día ahora vive en un TextField (sin uppercase).
    expect(find.text('Pecho y Triceps'), findsOneWidget);
  });

  testWidgets('GUARDAR dispara SaveDay cuando hay cambios', (tester) async {
    // El botón GUARDAR ahora se habilita solo cuando isDirty=true.
    when(() => bloc.state).thenReturn(const RoutineManagementState(isDirty: true));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('GUARDAR'));
    await tester.pump();

    verify(() => bloc.add(any(that: isA<SaveDay>()))).called(1);
  });

  testWidgets('sin ejercicios muestra empty state con CTA', (tester) async {
    const emptyDay = RoutineDay(
      id: 'd1',
      routineId: 'r1',
      name: 'Vacío',
      dayOfWeek: 1,
      exercises: [],
    );
    when(() => bloc.state).thenReturn(const RoutineManagementState());

    await tester.pumpWidget(
      MaterialApp(
        home: InheritedGoRouter(
          goRouter: mockGoRouter,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<RoutineManagementBloc>.value(value: bloc),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: const DayEditorPage(routineId: 'r1', day: emptyDay),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sin ejercicios'), findsOneWidget);
    expect(find.text('BUSCAR EJERCICIOS'), findsOneWidget);
  });
}
