import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_state.dart';
import 'package:gym_flutter/features/workout/presentation/pages/routine_day_page.dart';
import 'package:gym_flutter/features/workout/presentation/widgets/exercise_card.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkoutBloc extends Mock implements WorkoutBloc {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockWorkoutBloc mockWorkoutBloc;
  late MockGoRouter mockGoRouter;

  final tDay = RoutineDay(
    id: 'd1',
    routineId: 'r1',
    name: 'Pecho',
    dayOfWeek: 1,
    exercises: const [],
  );

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

  final tSession = WorkoutSession(
    id: 's1',
    userId: 'u1',
    routineDayId: 'd1',
    sessionDate: DateTime(2023, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(
      LoadDayInfo(
        userId: 'u1',
        routineDayId: 'd1',
        sessionDate: DateTime(2023, 1, 1),
      ),
    );
    registerFallbackValue(const ResetWorkout());
    registerFallbackValue(
      ConfirmStartWorkout(
        userId: 'u1',
        routineDayId: 'd1',
        sessionDate: DateTime(2023, 1, 1),
        routineDayName: 'Pecho',
      ),
    );
  });

  setUp(() {
    mockWorkoutBloc = MockWorkoutBloc();
    mockGoRouter = MockGoRouter();

    when(() => mockWorkoutBloc.stream).thenAnswer((_) => Stream.empty());
    when(() => mockWorkoutBloc.close()).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: InheritedGoRouter(
        goRouter: mockGoRouter,
        child: BlocProvider<WorkoutBloc>.value(
          value: mockWorkoutBloc,
          child: RoutineDayPage(
            routineDay: tDay,
            userId: 'u1',
            sessionDate: DateTime(2023, 1, 1),
          ),
        ),
      ),
    );
  }

  testWidgets('debe cargar info del día al iniciar', (tester) async {
    when(() => mockWorkoutBloc.state).thenReturn(WorkoutInitial());

    await tester.pumpWidget(createWidgetUnderTest());

    verify(() => mockWorkoutBloc.add(any(that: isA<LoadDayInfo>()))).called(1);
  });

  testWidgets('debe mostrar vista de pre-inicio cuando carga DayInfoLoaded', (
    tester,
  ) async {
    when(() => mockWorkoutBloc.state).thenReturn(
      DayInfoLoaded(
        exercises: [tExercise],
        recentSessions: const [],
        recentSessionsLogs: const {},
        lastPerformances: const {},
        userId: 'u1',
        routineDayId: 'd1',
        sessionDate: DateTime(2023, 1, 1),
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('INICIAR ENTRENAMIENTO'), findsOneWidget);
    expect(find.text('Press Banca'), findsOneWidget);
  });

  testWidgets('debe disparar ConfirmStartWorkout al presionar INICIAR', (
    tester,
  ) async {
    when(() => mockWorkoutBloc.state).thenReturn(
      DayInfoLoaded(
        exercises: [tExercise],
        recentSessions: const [],
        recentSessionsLogs: const {},
        lastPerformances: const {},
        userId: 'u1',
        routineDayId: 'd1',
        sessionDate: DateTime(2023, 1, 1),
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('INICIAR ENTRENAMIENTO'));
    await tester.pump();

    verify(
      () => mockWorkoutBloc.add(any(that: isA<ConfirmStartWorkout>())),
    ).called(1);
  });

  testWidgets(
    'debe mostrar la lista de ejercicios activos cuando carga DayWorkoutStarted',
    (tester) async {
      when(() => mockWorkoutBloc.state).thenReturn(
        DayWorkoutStarted(
          tSession,
          [tExercise],
          setLogs: const [],
          lastPerformances: const {},
          recentSessions: const [],
          recentSessionsLogs: const {},
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(ExerciseCard), findsOneWidget);
      expect(find.text('FINALIZAR'), findsOneWidget);
    },
  );

  testWidgets('debe mostrar el timer al registrar una serie', (tester) async {
    when(() => mockWorkoutBloc.state).thenReturn(
      DayWorkoutStarted(
        tSession,
        [tExercise],
        setLogs: const [],
        lastPerformances: const {},
        recentSessions: const [],
        recentSessionsLogs: const {},
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    final exerciseCard = tester.widget<ExerciseCard>(find.byType(ExerciseCard));
    exerciseCard.onSetAdded!(
      SetLog(
        id: '',
        sessionId: 's1',
        exerciseId: 'e1',
        setIndex: 1,
        actualWeight: 60,
        actualReps: 10,
        createdAt: DateTime.now(),
      ),
    );

    await tester.pump();

    expect(find.text('1:30'), findsOneWidget);
  });

  testWidgets('debe cerrar la página al recibir WorkoutFinishedSuccess', (
    tester,
  ) async {
    final controller = StreamController<WorkoutState>.broadcast();
    when(() => mockWorkoutBloc.state).thenReturn(
      DayWorkoutStarted(
        tSession,
        [tExercise],
        setLogs: const [],
        lastPerformances: const {},
        recentSessions: const [],
        recentSessionsLogs: const {},
      ),
    );
    when(() => mockWorkoutBloc.stream).thenAnswer((_) => controller.stream);
    when(() => mockGoRouter.pop<bool>(any())).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    controller.add(WorkoutFinishedSuccess());
    await tester.pump();

    verify(() => mockGoRouter.pop<bool>(true)).called(1);
    await controller.close();
  });
}
