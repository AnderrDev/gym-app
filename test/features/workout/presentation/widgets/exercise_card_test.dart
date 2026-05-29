import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/auth/domain/entities/user.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_event.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_card.dart';
import 'package:mocktail/mocktail.dart';

class MockActiveWorkoutBloc extends Mock implements ActiveWorkoutBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockActiveWorkoutBloc mockActiveWorkoutBloc;
  late MockAuthBloc mockAuthBloc;

  final tExercise = const Exercise(
    id: 'e1',
    routineDayId: 'd1',
    name: 'Press Banca',
    targetMuscle: 'Pecho',
    targetSets: 3,
    targetReps: 10,
    targetWeight: 60,
    restTimerSeconds: 1,
  );

  final tUser = const User(
    id: 'u1',
    email: 'test@test.com',
    fullName: 'Test User',
  );

  setUpAll(() {
    registerFallbackValue(
      const UpdateActiveExerciseTarget(
        exerciseId: 'e1',
        targetWeight: 70,
        targetReps: 12,
      ),
    );
    registerFallbackValue(
      const SaveActiveSetLog(
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
    mockActiveWorkoutBloc = MockActiveWorkoutBloc();
    mockAuthBloc = MockAuthBloc();

    when(
      () => mockActiveWorkoutBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockActiveWorkoutBloc.close()).thenAnswer((_) async {});
    when(() => mockAuthBloc.state).thenReturn(Authenticated(tUser));
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget createWidgetUnderTest({
    Exercise? exercise,
    String sessionId = 's1',
    List<SetLog> initialCompletedSets = const [],
    SetLog? lastPerformance,
    bool readOnly = false,
    void Function(SetLog)? onSetAdded,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: SizedBox(
              width: 1000,
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<ActiveWorkoutBloc>.value(
                    value: mockActiveWorkoutBloc,
                  ),
                  BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                ],
                child: ExerciseCard(
                  exercise: exercise ?? tExercise,
                  sessionId: sessionId,
                  initialCompletedSets: initialCompletedSets,
                  lastPerformance: lastPerformance,
                  readOnly: readOnly,
                  onSetAdded: onSetAdded,
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

  testWidgets(
    'debe permitir registrar una serie con un tap (inputs siempre visibles)',
    (tester) async {
      SetLog? captured;
      await tester.pumpWidget(
        createWidgetUnderTest(onSetAdded: (log) => captured = log),
      );

      // Los inputs usan `TextInputType.none` por defecto (tap → chips,
      // sin teclado del sistema). Pero `enterText` simula entrada vía la
      // conexión de input directamente, así que funciona sin tocar ✎.
      await tester.enterText(
        find.byKey(const ValueKey('weight_e1_1')),
        '65',
      );
      await tester.enterText(
        find.byKey(const ValueKey('reps_e1_1')),
        '12',
      );

      await tester.tap(find.byKey(const ValueKey('save_e1_1')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(captured, isNotNull);
      expect(captured!.actualWeight, 65);
      expect(captured!.actualReps, 12);
      expect(captured!.setIndex, 1);

      // La serie 2 sigue editable e independiente.
      expect(find.byKey(const ValueKey('save_e1_2')), findsOneWidget);

      // Drenar el Future.delayed del live advice (8s).
      await tester.pump(const Duration(seconds: 9));
    },
  );

  testWidgets('debe mostrar record histórico si existe', (tester) async {
    final lastPerf = const SetLog(
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

  testWidgets('abre el bottom sheet de objetivo remoto', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createWidgetUnderTest());

    // Las acciones del header viven ahora en un PopupMenu (⋯).
    // pumpAndSettle no termina por el _pulseController repeat — pumpeo
    // varios frames para que la animación de apertura del popup termine y
    // se desactive el AbsorbPointer de la ruta.
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Cambiar objetivo'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('menu_target')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Cambiar objetivo remoto'), findsOneWidget);
    expect(find.text('Actualizar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Nuevo peso (kg)'.toUpperCase()), findsOneWidget);
    expect(find.text('Nuevas reps'.toUpperCase()), findsOneWidget);
  });
}
