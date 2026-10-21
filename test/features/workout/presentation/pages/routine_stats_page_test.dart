import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_history_session.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_session_detail.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_history_bottom_sheet.dart';
import 'package:gym_flutter/features/workout/presentation/routine_stats/pages/routine_stats_page.dart';
import 'package:gym_flutter/features/workout/presentation/routine_stats/widgets/routine_session_card.dart';
import 'package:gym_flutter/injection_container.dart';

import '../../../../helpers/mocks.dart';

RoutineHistorySession _session(
  String id,
  DateTime date,
  String dayId,
  String dayName,
  double volume,
) => RoutineHistorySession(
  sessionId: id,
  sessionDate: date,
  routineDayId: dayId,
  routineDayName: dayName,
  totalVolume: volume,
  totalReps: 24,
  setCount: 3,
);

void main() {
  late MockWorkoutRepository repository;

  // Más reciente primero, como lo da el repositorio.
  final history = [
    _session('s3', DateTime(2026, 10, 15), 'pierna', 'Pierna', 9000),
    _session('s2', DateTime(2026, 10, 13), 'torso', 'Torso', 5000),
    _session('s1', DateTime(2026, 10, 6), 'torso', 'Torso', 4000),
  ];

  setUpAll(() => initializeDateFormatting('es'));

  setUp(() async {
    await sl.reset();
    repository = MockWorkoutRepository();
    sl
      ..registerLazySingleton<WorkoutRepository>(() => repository)
      ..registerLazySingleton(() => GetSessionDetail(sl()));
    when(
      () => repository.getRoutineStats('u1', 'r1'),
    ).thenAnswer((_) async => Right(history));
  });

  tearDown(sl.reset);

  Widget wrap() => MaterialApp(
    theme: AppTheme.dark(),
    home: const RoutineStatsPage(
      userId: 'u1',
      routineId: 'r1',
      routineName: 'Fuerza',
    ),
  );

  testWidgets('filtrar por día deja sólo sus sesiones y compara entre ellas', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('3 SESIONES'), findsOneWidget);
    expect(
      find.text('Peso × reps sumado de cada semana entrenada'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Torso'));
    await tester.pumpAndSettle();

    expect(find.text('2 SESIONES'), findsOneWidget);
    expect(
      find.text('Peso × reps sumado de cada sesión de Torso'),
      findsOneWidget,
    );
    // Torso de 4.000 a 5.000: la sesión de Pierna ya no cuenta.
    expect(find.text('+1.000 kg (+25 %)'), findsOneWidget);
    expect(find.text('Pierna'), findsOneWidget); // sólo el chip
  });

  testWidgets('tocar una sesión abre su detalle', (tester) async {
    when(() => repository.getSessionSetLogs('s3')).thenAnswer(
      (_) async => const Right([
        SetLog(
          id: 'l1',
          sessionId: 's3',
          exerciseId: 'e1',
          setIndex: 0,
          actualReps: 8,
          actualWeight: 100,
        ),
      ]),
    );
    when(() => repository.getSessionExercises('s3')).thenAnswer(
      (_) async => const Right([
        Exercise(
          id: 'e1',
          routineDayId: 'pierna',
          name: 'Sentadilla',
          targetMuscle: 'Piernas',
          targetWeight: 100,
          targetReps: 8,
        ),
      ]),
    );
    when(
      () => repository.getSessionCoaching('s3'),
    ).thenAnswer((_) async => const Right(<CoachingAnalysis>[]));

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final card = find.byType(RoutineSessionCard).first;
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutHistoryBottomSheet), findsOneWidget);
    expect(find.textContaining('Sentadilla'), findsWidgets);
  });
}
