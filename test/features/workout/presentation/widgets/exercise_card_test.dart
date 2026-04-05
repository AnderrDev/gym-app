import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/auth/domain/entities/user.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_event.dart';
import 'package:gym_flutter/features/workout/presentation/widgets/exercise_card.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkoutBloc extends Mock implements WorkoutBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockWorkoutBloc mockWorkoutBloc;
  late MockAuthBloc mockAuthBloc;

  final tExercise = Exercise(
    id: 'e1',
    routineDayId: 'd1',
    name: 'Press Banca',
    targetMuscle: 'Pecho',
    targetSets: 3,
    targetReps: 10,
    targetWeight: 60,
    restTimerSeconds: 1,
  );

  final tUser = User(id: 'u1', email: 'test@test.com', fullName: 'Test User');

  setUpAll(() {
    registerFallbackValue(
      const UpdateExerciseTarget(
        exerciseId: 'e1',
        targetWeight: 70,
        targetReps: 12,
      ),
    );
    registerFallbackValue(
      AddSetLogEvent(
        SetLog(
          sessionId: 's1',
          exerciseId: 'e1',
          actualWeight: 60,
          actualReps: 10,
          setIndex: 1,
        ),
      ),
    );
  });

  setUp(() {
    mockWorkoutBloc = MockWorkoutBloc();
    mockAuthBloc = MockAuthBloc();

    when(() => mockWorkoutBloc.stream).thenAnswer((_) => Stream.empty());
    when(() => mockWorkoutBloc.close()).thenAnswer((_) async {});
    when(() => mockAuthBloc.state).thenReturn(Authenticated(tUser));
    when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.empty());
  });

  Widget createWidgetUnderTest({
    Exercise? exercise,
    String sessionId = 's1',
    List<SetLog> initialCompletedSets = const [],
    SetLog? lastPerformance,
    bool readOnly = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: SizedBox(
              width: 1000,
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<WorkoutBloc>.value(value: mockWorkoutBloc),
                  BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                ],
                child: ExerciseCard(
                  exercise: exercise ?? tExercise,
                  sessionId: sessionId,
                  initialCompletedSets: initialCompletedSets,
                  lastPerformance: lastPerformance,
                  readOnly: readOnly,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('debe mostrar el nombre del ejercicio y objetivos', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.text('Press Banca'), findsOneWidget);
    expect(find.textContaining('TARGET: 60kg x 10'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
  });

  testWidgets('debe expandirse y contraerse al tocar el header', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byKey(const ValueKey('sets_list')), findsOneWidget);

    await tester.tap(find.text('Press Banca'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('sets_list')), findsNothing);

    await tester.tap(find.text('Press Banca'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('sets_list')), findsOneWidget);
  });

  testWidgets('debe permitir registrar una serie y activar el descanso', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(find.widgetWithText(TextField, 'Peso (kg)'), '65');
    await tester.enterText(find.widgetWithText(TextField, 'Reps'), '12');

    await tester.tap(find.byIcon(Icons.check));
    await tester.pump(const Duration(milliseconds: 100));

    verify(
      () => mockWorkoutBloc.add(any(that: isA<AddSetLogEvent>())),
    ).called(1);

    expect(find.text('DESCANSO'), findsOneWidget);
    expect(find.byKey(const ValueKey('rest_timer')), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('debe permitir saltar el descanso', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.byIcon(Icons.check));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('DESCANSO'), findsOneWidget);

    await tester.tap(find.text('Saltar descanso'));
    // El widget usa AnimatedSwitcher y Timer.periodic
    // Bombeamos lo suficiente para procesar el callback del timer o el skip
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('DESCANSO'), findsNothing);
    expect(find.text('Serie 2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('debe mostrar record histórico si existe', (tester) async {
    final lastPerf = SetLog(
      sessionId: 'old_s',
      exerciseId: 'e1',
      actualWeight: 70,
      actualReps: 8,
      setIndex: 1,
    );

    // Configurar viewport del tester explícitamente
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest(lastPerformance: lastPerf));
    await tester.pump();

    expect(find.textContaining('Record: 70kg x 8'), findsOneWidget);
  });

  testWidgets('debe mostrar diálogo de cambio de objetivo remoto', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.byIcon(Icons.settings_remote));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Cambiar Objetivo Remoto'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nuevo Peso (kg)'),
      '75',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Nuevas Reps'), '15');

    await tester.tap(find.text('Actualizar'));
    await tester.pump(const Duration(milliseconds: 500));

    verify(
      () => mockWorkoutBloc.add(
        const UpdateExerciseTarget(
          exerciseId: 'e1',
          targetWeight: 75,
          targetReps: 15,
        ),
      ),
    ).called(1);
  });
}
