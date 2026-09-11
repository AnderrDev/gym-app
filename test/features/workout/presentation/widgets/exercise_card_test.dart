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
    void Function(int)? onSetRemoved,
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
                  onSetRemoved: onSetRemoved,
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

  group('flujo "Completar serie"', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      void Function(SetLog)? onSetAdded,
      void Function(int)? onSetRemoved,
    }) async {
      await tester.binding.setSurfaceSize(const Size(1100, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        createWidgetUnderTest(
          onSetAdded: onSetAdded,
          onSetRemoved: onSetRemoved,
        ),
      );
    }

    Future<void> openNextSet(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('complete_set_button_e1')));
      await tester.pumpAndSettle();
    }

    String fieldText(WidgetTester tester, String key) =>
        tester.widget<TextField>(find.byKey(ValueKey(key))).controller!.text;

    Future<void> confirm(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('complete_set_confirm')));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'muestra el objetivo de cada serie y el botón de la siguiente',
      (tester) async {
        await pumpCard(tester);

        expect(find.text('60 kg × 10 reps'), findsNWidgets(3));
        expect(find.text('COMPLETAR SERIE 1'), findsOneWidget);
      },
    );

    testWidgets('el modal confirma peso y reps y registra la serie', (
      tester,
    ) async {
      SetLog? captured;
      await pumpCard(tester, onSetAdded: (log) => captured = log);

      await openNextSet(tester);
      expect(find.text('SERIE 1 DE 3'), findsOneWidget);
      expect(fieldText(tester, 'complete_set_weight'), '60');
      expect(fieldText(tester, 'complete_set_reps'), '10');

      await tester.enterText(
        find.byKey(const ValueKey('complete_set_weight')),
        '62.5',
      );
      await tester.pump();
      expect(find.text('+2.5 kg sobre el objetivo'), findsOneWidget);
      await confirm(tester);

      expect(captured, isNotNull);
      expect(captured!.actualWeight, 62.5);
      expect(captured!.actualReps, 10);
      expect(captured!.setIndex, 1);
      expect(find.text('62.5 kg × 10 reps'), findsOneWidget);
      expect(find.text('COMPLETAR SERIE 2'), findsOneWidget);

      // Drenar el timer del live advice (8s).
      await tester.pump(const Duration(seconds: 9));
    });

    testWidgets('subir el peso con menos reps no aconseja bajar el peso', (
      tester,
    ) async {
      await pumpCard(tester);

      await openNextSet(tester);
      await tester.enterText(
        find.byKey(const ValueKey('complete_set_weight')),
        '62',
      );
      await tester.enterText(
        find.byKey(const ValueKey('complete_set_reps')),
        '8',
      );
      await confirm(tester);

      expect(find.textContaining('Subiste +2 kg'), findsOneWidget);
      expect(find.textContaining('reduce el peso'), findsNothing);

      await tester.pump(const Duration(seconds: 9));
    });

    testWidgets('la serie siguiente arranca con el peso de la anterior', (
      tester,
    ) async {
      await pumpCard(tester);

      await openNextSet(tester);
      await tester.enterText(
        find.byKey(const ValueKey('complete_set_weight')),
        '65',
      );
      await confirm(tester);

      await openNextSet(tester);
      expect(find.text('SERIE 2 DE 3'), findsOneWidget);
      expect(fieldText(tester, 'complete_set_weight'), '65');

      await tester.pump(const Duration(seconds: 9));
    });

    testWidgets('desmarcar y volver a abrir conserva el peso editado', (
      tester,
    ) async {
      int? removedIndex;
      await pumpCard(tester, onSetRemoved: (i) => removedIndex = i);

      await openNextSet(tester);
      await tester.enterText(
        find.byKey(const ValueKey('complete_set_weight')),
        '65',
      );
      await tester.enterText(
        find.byKey(const ValueKey('complete_set_reps')),
        '8',
      );
      await confirm(tester);

      // Tocar la serie completada abre el modal en modo edición.
      await tester.tap(find.text('65 kg × 8 reps'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('complete_set_unsave')));
      await tester.pumpAndSettle();

      expect(removedIndex, 1);
      expect(find.text('COMPLETAR SERIE 1'), findsOneWidget);

      await openNextSet(tester);
      expect(fieldText(tester, 'complete_set_weight'), '65');
      expect(fieldText(tester, 'complete_set_reps'), '8');

      await tester.pump(const Duration(seconds: 9));
    });
  });

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
