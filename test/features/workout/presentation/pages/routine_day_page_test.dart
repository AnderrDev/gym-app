import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_flutter/core/ui/molecules/app_error_state.dart';
import 'package:gym_flutter/core/utils/clock.dart';
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
import 'package:gym_flutter/core/notifications/active_workout_notifier.dart';
import 'package:gym_flutter/core/notifications/live_activities_bridge.dart';
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
      const StartActiveWorkout(
        userId: 'u1',
        routineDayId: 'd1',
        routineDayName: 'Pecho',
      ),
    );
    registerFallbackValue(const ResetActiveWorkout());
    // Necesario para los `any(named: 'duration')` del mock de
    // ActiveWorkoutNotifier — sin él, mocktail tira `Bad state`
    // cuando este test corre después de otros en el batch.
    registerFallbackValue(Duration.zero);
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
    registerFallbackValue(Duration.zero);
  });

  late MockNotificationService notificationService;
  late MockActiveWorkoutNotifier activeWorkoutNotifier;
  late MockLiveActivitiesBridge liveActivitiesBridge;

  setUp(() {
    routineDayBloc = MockRoutineDayBloc();
    activeWorkoutBloc = MockActiveWorkoutBloc();
    mockGoRouter = MockGoRouter();
    routineStreamCtrl = StreamController<RoutineDayState>.broadcast();
    activeStreamCtrl = StreamController<ActiveWorkoutState>.broadcast();
    notificationService = MockNotificationService();
    activeWorkoutNotifier = MockActiveWorkoutNotifier();
    liveActivitiesBridge = MockLiveActivitiesBridge();
    when(() => liveActivitiesBridge.isAvailable).thenReturn(false);
    when(
      () => notificationService.requestPermission(),
    ).thenAnswer((_) async => true);
    when(
      () =>
          activeWorkoutNotifier.onRestStarted(duration: any(named: 'duration')),
    ).thenAnswer((_) async {});
    when(() => activeWorkoutNotifier.onRestEnded()).thenAnswer((_) async {});
    if (di.sl.isRegistered<NotificationService>()) {
      di.sl.unregister<NotificationService>();
    }
    if (di.sl.isRegistered<ActiveWorkoutNotifier>()) {
      di.sl.unregister<ActiveWorkoutNotifier>();
    }
    if (di.sl.isRegistered<LiveActivitiesBridge>()) {
      di.sl.unregister<LiveActivitiesBridge>();
    }
    di.sl.registerSingleton<NotificationService>(notificationService);
    di.sl.registerSingleton<ActiveWorkoutNotifier>(activeWorkoutNotifier);
    di.sl.registerSingleton<LiveActivitiesBridge>(liveActivitiesBridge);
    if (!di.sl.isRegistered<Clock>()) {
      di.sl.registerSingleton<Clock>(const SystemClock());
    }

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

  testWidgets('Reintentar tras fallar el inicio limpia el error y recarga', (
    tester,
  ) async {
    when(() => routineDayBloc.state).thenReturn(const RoutineDayState());
    when(() => activeWorkoutBloc.state).thenReturn(
      const ActiveWorkoutState(
        status: ActiveWorkoutStatus.failure,
        errorMessage: 'No se pudo iniciar el entrenamiento',
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    clearInteractions(routineDayBloc);

    tester.widget<AppErrorState>(find.byType(AppErrorState)).onRetry!();
    await tester.pump();

    verify(
      () => activeWorkoutBloc.add(any(that: isA<ResetActiveWorkout>())),
    ).called(1);
    verifyInOrder([
      () => routineDayBloc.add(any(that: isA<ResetRoutineDay>())),
      () => routineDayBloc.add(any(that: isA<LoadRoutineDay>())),
    ]);
  });

  for (final continuePrevious in [true, false]) {
    testWidgets(
      'sesión de otra fecha requiere confirmar: continuar=$continuePrevious',
      (tester) async {
        when(() => routineDayBloc.state).thenReturn(const RoutineDayState());
        when(
          () => activeWorkoutBloc.state,
        ).thenReturn(const ActiveWorkoutState());
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        final previous = tSession.copyWith(sessionDate: DateTime(2022, 12, 31));
        final ready = RoutineDayState(
          status: RoutineDayStatus.ready,
          userId: 'u1',
          routineDayId: 'd1',
          sessionDate: DateTime(2023),
          exercises: const [tExercise],
          existingSession: previous,
        );
        when(() => routineDayBloc.state).thenReturn(ready);
        routineStreamCtrl.add(ready);
        await tester.pumpAndSettle();
        expect(
          find.text('Tienes una sesión anterior pendiente'),
          findsOneWidget,
        );
        expect(find.textContaining('31 dic 2022'), findsOneWidget);
        verifyNever(
          () => activeWorkoutBloc.add(any(that: isA<ResumeActiveWorkout>())),
        );
        await tester.tap(
          find.text(continuePrevious ? 'Continuar sesión anterior' : 'Volver'),
        );
        await tester.pumpAndSettle();
        if (continuePrevious) {
          final event =
              verify(
                    () => activeWorkoutBloc.add(
                      captureAny(that: isA<ResumeActiveWorkout>()),
                    ),
                  ).captured.single
                  as ResumeActiveWorkout;
          expect(event.session, previous);
        } else {
          verifyNever(
            () => activeWorkoutBloc.add(any(that: isA<ResumeActiveWorkout>())),
          );
          verifyNever(
            () => activeWorkoutBloc.add(any(that: isA<StartActiveWorkout>())),
          );
          verify(() => mockGoRouter.pop<Object?>()).called(1);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'abrir una sesión pendiente con su propia fecha también pide confirmación',
    (tester) async {
      when(() => routineDayBloc.state).thenReturn(const RoutineDayState());
      when(
        () => activeWorkoutBloc.state,
      ).thenReturn(const ActiveWorkoutState());
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      final ready = RoutineDayState(
        status: RoutineDayStatus.ready,
        userId: 'u1',
        routineDayId: 'd1',
        sessionDate: tSession.sessionDate,
        exercises: const [tExercise],
        existingSession: tSession,
      );
      when(() => routineDayBloc.state).thenReturn(ready);
      routineStreamCtrl.add(ready);
      await tester.pumpAndSettle();
      expect(find.text('Tienes una sesión anterior pendiente'), findsOneWidget);
      verifyNever(
        () => activeWorkoutBloc.add(any(that: isA<ResumeActiveWorkout>())),
      );
    },
  );

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

    expect(find.text('Iniciar entrenamiento'), findsOneWidget);
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

    await tester.tap(find.text('Iniciar entrenamiento'));
    await tester.pump();

    verify(
      () => activeWorkoutBloc.add(any(that: isA<StartActiveWorkout>())),
    ).called(1);
  });

  for (final status in [
    ActiveWorkoutStatus.idle,
    ActiveWorkoutStatus.starting,
  ]) {
    testWidgets('carga ocupa toda la pantalla: $status', (tester) async {
      when(() => routineDayBloc.state).thenReturn(const RoutineDayState());
      when(
        () => activeWorkoutBloc.state,
      ).thenReturn(ActiveWorkoutState(status: status));
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      expect(find.byType(SliverAppBar), findsNothing);
      expect(
        find.text(
          status == ActiveWorkoutStatus.starting
              ? 'Iniciando entrenamiento…'
              : 'Cargando entrenamiento…',
        ),
        findsOneWidget,
      );
      expect(find.text('Iniciar entrenamiento'), findsNothing);
    });
  }

  testWidgets('inicio bloquea el segundo toque mientras pide permisos', (
    tester,
  ) async {
    final permission = Completer<bool>();
    when(
      () => notificationService.requestPermission(),
    ).thenAnswer((_) => permission.future);
    when(() => routineDayBloc.state).thenReturn(
      const RoutineDayState(
        status: RoutineDayStatus.ready,
        exercises: [tExercise],
      ),
    );
    when(() => activeWorkoutBloc.state).thenReturn(const ActiveWorkoutState());
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.tap(find.text('Iniciar entrenamiento'));
    await tester.pump();
    expect(find.text('Iniciando entrenamiento…'), findsOneWidget);
    expect(find.text('Iniciar entrenamiento'), findsNothing);
    permission.complete(true);
    await tester.pump();
    verify(
      () => activeWorkoutBloc.add(any(that: isA<StartActiveWorkout>())),
    ).called(1);
  });

  testWidgets(
    'sesión cerrada muestra todos los ejercicios y series sin modo de edición',
    (tester) async {
      when(() => routineDayBloc.state).thenReturn(const RoutineDayState());
      when(() => activeWorkoutBloc.state).thenReturn(
        ActiveWorkoutState(
          status: ActiveWorkoutStatus.running,
          session: tSession.copyWith(completedAt: DateTime(2023, 1, 1, 12)),
          exercises: [
            tExercise,
            tExercise.copyWith(id: 'e2', name: 'Aperturas'),
          ],
          setLogs: const [
            SetLog(
              sessionId: 's1',
              exerciseId: 'e1',
              setIndex: 1,
              actualWeight: 65,
              actualReps: 9,
            ),
          ],
        ),
      );
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      expect(find.text('Entrenamiento finalizado'), findsOneWidget);
      expect(find.text('Press Banca'), findsOneWidget);
      expect(find.text('Aperturas'), findsOneWidget);
      expect(find.text('Serie 1 · 65 kg × 9 reps'), findsOneWidget);
      expect(find.text('Sin series registradas'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(find.text('Finalizar'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('estado running renderiza ExerciseCard y Finalizar', (
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
    expect(find.text('Finalizar'), findsOneWidget);
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

  testWidgets('el descanso usa el configurado en el ejercicio', (tester) async {
    when(() => routineDayBloc.state).thenReturn(const RoutineDayState());
    when(() => activeWorkoutBloc.state).thenReturn(
      ActiveWorkoutState(
        status: ActiveWorkoutStatus.running,
        session: tSession,
        exercises: [tExercise.copyWith(restTimerSeconds: 45)],
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    tester.widget<ExerciseCard>(find.byType(ExerciseCard)).onSetAdded!(
      const SetLog(
        sessionId: 's1',
        exerciseId: 'e1',
        setIndex: 1,
        actualWeight: 60,
        actualReps: 10,
      ),
    );
    await tester.pump();

    expect(find.text('0:45'), findsOneWidget);
  });

  testWidgets('editar una serie ya registrada no arranca descanso', (
    tester,
  ) async {
    const saved = SetLog(
      sessionId: 's1',
      exerciseId: 'e1',
      setIndex: 1,
      actualWeight: 60,
      actualReps: 10,
    );
    when(() => routineDayBloc.state).thenReturn(const RoutineDayState());
    when(() => activeWorkoutBloc.state).thenReturn(
      ActiveWorkoutState(
        status: ActiveWorkoutStatus.running,
        session: tSession,
        exercises: const [tExercise],
        setLogs: const [saved],
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    tester.widget<ExerciseCard>(find.byType(ExerciseCard)).onSetAdded!(
      saved.copyWith(actualWeight: 62.5),
    );
    await tester.pump();

    verify(
      () => activeWorkoutBloc.add(any(that: isA<SaveActiveSetLog>())),
    ).called(1);
    expect(find.text('1:30'), findsNothing);
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
