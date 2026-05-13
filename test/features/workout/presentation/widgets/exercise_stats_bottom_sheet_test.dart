import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_history_session.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_state.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_stats_bottom_sheet.dart';
import 'package:mocktail/mocktail.dart';

class MockExerciseStatsBloc extends Mock implements ExerciseStatsBloc {}

void main() {
  late MockExerciseStatsBloc mockExerciseStatsBloc;

  setUpAll(() {
    initializeDateFormatting('es');
    registerFallbackValue(
      const LoadExerciseStats(userId: 'u1', exerciseId: 'e1'),
    );
  });

  setUp(() {
    mockExerciseStatsBloc = MockExerciseStatsBloc();
    when(
      () => mockExerciseStatsBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockExerciseStatsBloc.close()).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<ExerciseStatsBloc>.value(
          value: mockExerciseStatsBloc,
          child: const ExerciseStatsBottomSheet(
            userId: 'user123',
            exerciseId: 'exercise456',
            exerciseName: 'Bench Press',
          ),
        ),
      ),
    );
  }

  testWidgets('debe mostrar cargando al inicio', (tester) async {
    when(() => mockExerciseStatsBloc.state).thenReturn(ExerciseStatsLoading());

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('debe mostrar mensaje de error cuando falla la carga', (
    tester,
  ) async {
    const tMessage = 'Error de conexión';
    when(
      () => mockExerciseStatsBloc.state,
    ).thenReturn(const ExerciseStatsError(message: tMessage));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text(tMessage), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('debe mostrar estado vacío cuando no hay historial', (
    tester,
  ) async {
    when(
      () => mockExerciseStatsBloc.state,
    ).thenReturn(const ExerciseStatsLoaded(history: []));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Aún no hay datos para este ejercicio'), findsOneWidget);
  });

  testWidgets('debe mostrar gráficos e historial cuando hay datos', (
    tester,
  ) async {
    final tHistory = [
      ExerciseHistorySession(
        sessionDate: DateTime(2023, 1, 10),
        logs: const [
          SetLog(
            id: 'l1',
            sessionId: 's1',
            exerciseId: 'e1',
            setIndex: 0,
            actualReps: 10,
            actualWeight: 60,
          ),
        ],
      ),
    ];

    when(
      () => mockExerciseStatsBloc.state,
    ).thenReturn(ExerciseStatsLoaded(history: tHistory));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('BENCH PRESS'), findsOneWidget);
    expect(find.text('PESO MÁXIMO'), findsOneWidget);
    expect(find.text('1RM ESTIMADO'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('VOLUMEN TOTAL'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('VOLUMEN TOTAL'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('HISTORIAL DETALLADO'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('HISTORIAL DETALLADO'), findsOneWidget);
    expect(find.textContaining('60kg x 10'), findsOneWidget);
  });
}
