import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_state.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_day/routine_day_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_day/routine_day_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_day/routine_day_state.dart';
import 'package:gym_flutter/core/notifications/notification_service.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_card.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/pages/routine_day_page.dart';
import 'package:gym_flutter/injection_container.dart' as di;
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

class MockRoutineDayBloc extends Mock implements RoutineDayBloc {}

class MockActiveWorkoutBloc extends Mock implements ActiveWorkoutBloc {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockRoutineDayBloc routineDayBloc;
  late MockActiveWorkoutBloc activeWorkoutBloc;
  late MockGoRouter mockGoRouter;
  late StreamController<RoutineDayState> routineStreamCtrl;
  late StreamController<ActiveWorkoutState> activeStreamCtrl;

  const tDay = RoutineDay(
    id: 'd1',
    routineId: 'r1',
    name: 'Pecho',
    dayOfWeek: 1,
    exercises: [],
  );

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

  final tSession = WorkoutSession(
    id: 's1',
    userId: 'u1',
    routineDayId: 'd1',
    sessionDate: DateTime(2023),
  );

  setUpAll(() {
    registerFallbackValue(
      LoadRoutineDay(
        userId: 'u1',
        routineDayId: 'd1',
        sessionDate: DateTime(2023),
      ),
    );
    registerFallbackValue(const ResetRoutineDay());
    registerFallbackValue(
      StartActiveWorkout(
        userId: 'u1',
        routineDayId: 'd1',
        sessionDate: DateTime(2023),
        routineDayName: 'Pecho',
      ),
    );
    registerFallbackValue(const ResetActiveWorkout());
    registerFallbackValue(
      const SaveActiveSetLog(
        SetLog(
          sessionId: '',
          exerciseId: '',
          actualWeight: 0,
          actualReps: 0,
          setIndex: 0,
        ),
      ),
    );
  });

  late MockNotificationService notificationService;

  setUp(() {
    routineDayBloc = MockRoutineDayBloc();
    activeWorkoutBloc = MockActiveWorkoutBloc();
    mockGoRouter = MockGoRouter();
    routineStreamCtrl = StreamController<RoutineDayState>.broadcast();
    activeStreamCtrl = StreamController<ActiveWorkoutState>.broadcast();
    notificationService = MockNotificationService();
    when(() => notificationService.requestPermission()).thenAnswer(
      (_) async => true,
    );
    if (di.sl.isRegistered<NotificationService>()) {
      di.sl.unregister<NotificationService>();
    }
    di.sl.registerSingleton<NotificationService>(notificationService);

    when(
      () => routineDayBloc.stream,
    ).thenAnswer((_) => routineStreamCtrl.stream);
    when(
      () => activeWorkoutBloc.stream,
    ).thenAnswer((_) => activeStreamCtrl.stream);
    when(() => routineDayBloc.close()).thenAnswer((_) async {});
    when(() => activeWorkoutBloc.close()).thenAnswer((_) async {});
    when(() => mockGoRouter.pop<Object?>(any())).thenReturn(null);
    when(() => mockGoRouter.pop<bool>(any())).thenReturn(null);
  });

  tearDown(() async {
    await routineStreamCtrl.close();
    await activeStreamCtrl.close();
    await di.sl.reset();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: InheritedGoRouter(
        goRouter: mockGoRouter,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<RoutineDayBloc>.value(value: routineDayBloc),
            BlocProvider<ActiveWorkoutBloc>.value(value: activeWorkoutBloc),
          ],
          child: RoutineDayPage(
            routineDay: tDay,
            userId: 'u1',
            sessionDate: DateTime(2023),
          ),
        ),
      ),
    );
  }

  testWidgets('initState dispara LoadRoutineDay', (tester) async {
    when(() => routineDayBloc.state).thenReturn(const RoutineDayState());
    when(() => activeWorkoutBloc.state).thenReturn(const ActiveWorkoutState());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    verify(
      () => routineDayBloc.add(any(that: isA<LoadRoutineDay>())),
    ).called(1);
  });

  testWidgets('estado ready prestart muestra el CTA de empezar', (
    tester,
  ) async {
    when(() => routineDayBloc.state).thenReturn(
      RoutineDayState(
        status: RoutineDayStatus.ready,
        userId: 'u1',
        routineDayId: 'd1',
        sessionDate: DateTime(2023),
        exercises: const [tExercise],
      ),
    );
    when(() => activeWorkoutBloc.state).thenReturn(const ActiveWorkoutState());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('EMPEZAR ENTRENAMIENTO'), findsOneWidget);
    expect(find.text('Press Banca'), findsOneWidget);
  });

  testWidgets('tap en INICIAR dispara StartActiveWorkout', (tester) async {
    when(() => routineDayBloc.state).thenReturn(
      RoutineDayState(
        status: RoutineDayStatus.ready,
        userId: 'u1',
        routineDayId: 'd1',
        sessionDate: DateTime(2023),
        exercises: const [tExercise],
      ),
    );
    when(() => activeWorkoutBloc.state).thenReturn(const ActiveWorkoutState());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('EMPEZAR ENTRENAMIENTO'));
    // _onStartWorkout `await`-ea NotificationService.requestPermission()
    // antes de despachar StartActiveWorkout. Esperamos el microtask para
    // que el dispatch ocurra antes del verify.
    await tester.pumpAndSettle();

    verify(
      () => activeWorkoutBloc.add(any(that: isA<StartActiveWorkout>())),
    ).called(1);
  });

  testWidgets('estado running renderiza ExerciseCard y FINALIZAR', (
    tester,
  ) async {
    when(() => routineDayBloc.state).thenReturn(const RoutineDayState());
    when(() => activeWorkoutBloc.state).thenReturn(
      ActiveWorkoutState(
        status: ActiveWorkoutStatus.running,
        session: tSession,
        exercises: const [tExercise],
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byType(ExerciseCard), findsOneWidget);
    expect(find.text('FINALIZAR'), findsOneWidget);
  });

  testWidgets('al guardar set arranca el timer 1:30', (tester) async {
    when(() => routineDayBloc.state).thenReturn(const RoutineDayState());
    when(() => activeWorkoutBloc.state).thenReturn(
      ActiveWorkoutState(
        status: ActiveWorkoutStatus.running,
        session: tSession,
        exercises: const [tExercise],
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    final exerciseCard = tester.widget<ExerciseCard>(find.byType(ExerciseCard));
    exerciseCard.onSetAdded!(
      SetLog(
        sessionId: 's1',
        exerciseId: 'e1',
        setIndex: 1,
        actualWeight: 60,
        actualReps: 10,
        createdAt: DateTime.now(),
      ),
    );
    await tester.pump();

    verify(
      () => activeWorkoutBloc.add(any(that: isA<SaveActiveSetLog>())),
    ).called(1);
    expect(find.text('1:30'), findsOneWidget);
  });

  testWidgets('al pasar a status finished pop con true', (tester) async {
    when(() => routineDayBloc.state).thenReturn(const RoutineDayState());
    when(() => activeWorkoutBloc.state).thenReturn(
      ActiveWorkoutState(
        status: ActiveWorkoutStatus.running,
        session: tSession,
        exercises: const [tExercise],
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    when(() => activeWorkoutBloc.state).thenReturn(
      const ActiveWorkoutState(status: ActiveWorkoutStatus.finished),
    );
    activeStreamCtrl.add(
      const ActiveWorkoutState(status: ActiveWorkoutStatus.finished),
    );
    await tester.pump();

    verify(() => mockGoRouter.pop<bool>(true)).called(1);
  });
}
