import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_history_session.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_assigned_routines.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/test_fixtures.dart';

class _MockGetAssignedRoutines extends Mock implements GetAssignedRoutines {}

void main() {
  late _MockGetAssignedRoutines getAssignedRoutines;
  late MockWorkoutRepository repository;

  const userId = 'u1';
  const routineA = Routine(id: 'r1', name: 'Push/Pull', exerciseCount: 6);
  const routineB = Routine(id: 'r2', name: 'Full body', exerciseCount: 4);
  final monday = DateTime(2026, 5, 11); // un lunes

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    getAssignedRoutines = _MockGetAssignedRoutines();
    repository = MockWorkoutRepository();
    when(
      () => repository.getRoutineDays(any()),
    ).thenAnswer((_) async => const Right(<RoutineDay>[]));
    when(
      () => repository.getRoutineStats(any(), any()),
    ).thenAnswer((_) async => const Right(<RoutineHistorySession>[]));
  });

  ProgressBloc buildBloc() => ProgressBloc(
    getAssignedRoutines: getAssignedRoutines,
    repository: repository,
  );

  group('LoadProgress', () {
    blocTest<ProgressBloc, ProgressState>(
      'éxito de routines + insights → Ready con los insights sumados',
      build: () {
        when(
          () => getAssignedRoutines(any()),
        ).thenAnswer((_) async => const Right([routineA, routineB]));
        when(
          () => repository.getWeeklyInsights(
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => Right(testWeeklyInsights));
        return buildBloc();
      },
      act: (b) => b.add(LoadProgress(userId, weekStart: monday)),
      expect: () => [
        isA<ProgressLoading>(),
        isA<ProgressReady>()
            .having((s) => s.routines.length, 'routines.length', 2)
            .having((s) => s.insights?.plannedDays, 'plannedDays', 10)
            .having((s) => s.insightsError, 'insightsError', isNull),
      ],
      verify: (_) {
        // "Esta semana" suma todas las rutinas asignadas, no sólo la primera.
        for (final r in [routineA, routineB]) {
          verify(
            () => repository.getWeeklyInsights(
              routineId: r.id,
              weekStart: any(named: 'weekStart'),
            ),
          ).called(1);
        }
      },
    );

    blocTest<ProgressBloc, ProgressState>(
      'fallo de routines → Loading → ProgressFailure (terminal)',
      build: () {
        when(
          () => getAssignedRoutines(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('boom')));
        return buildBloc();
      },
      act: (b) => b.add(LoadProgress(userId, weekStart: monday)),
      expect: () => [
        isA<ProgressLoading>(),
        isA<ProgressFailure>().having((s) => s.message, 'message', 'boom'),
      ],
      verify: (_) {
        // Si las rutinas fallan no se llega a pedir insights.
        verifyNever(
          () => repository.getWeeklyInsights(
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        );
      },
    );

    blocTest<ProgressBloc, ProgressState>(
      'fallo de insights → Ready con insightsError (no es terminal)',
      build: () {
        when(
          () => getAssignedRoutines(any()),
        ).thenAnswer((_) async => const Right([routineA]));
        when(
          () => repository.getWeeklyInsights(
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('insights nope')));
        return buildBloc();
      },
      act: (b) => b.add(LoadProgress(userId, weekStart: monday)),
      expect: () => [
        isA<ProgressLoading>(),
        isA<ProgressReady>()
            .having((s) => s.routines.length, 'routines.length', 1)
            .having((s) => s.insights, 'insights', isNull)
            .having((s) => s.insightsError, 'insightsError', 'insights nope'),
      ],
    );

    blocTest<ProgressBloc, ProgressState>(
      'sin rutinas asignadas → Ready con insights=null y sin pedir insights',
      build: () {
        when(
          () => getAssignedRoutines(any()),
        ).thenAnswer((_) async => const Right(<Routine>[]));
        return buildBloc();
      },
      act: (b) => b.add(LoadProgress(userId, weekStart: monday)),
      expect: () => [
        isA<ProgressLoading>(),
        isA<ProgressReady>()
            .having((s) => s.routines, 'routines', isEmpty)
            .having((s) => s.insights, 'insights', isNull)
            .having((s) => s.insightsError, 'insightsError', isNull),
      ],
      verify: (_) {
        verifyNever(
          () => repository.getWeeklyInsights(
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        );
      },
    );
  });

  group('RefreshProgress', () {
    blocTest<ProgressBloc, ProgressState>(
      'NO emite Loading; va directo a Ready',
      build: () {
        when(
          () => getAssignedRoutines(any()),
        ).thenAnswer((_) async => const Right([routineA]));
        when(
          () => repository.getWeeklyInsights(
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => Right(testWeeklyInsights));
        return buildBloc();
      },
      act: (b) => b.add(RefreshProgress(userId, weekStart: monday)),
      expect: () => [
        isA<ProgressReady>()
            .having((s) => s.routines.length, 'routines.length', 1)
            .having((s) => s.insights, 'insights', testWeeklyInsights),
      ],
    );

    blocTest<ProgressBloc, ProgressState>(
      'falla en refresh → ProgressFailure (sin Loading previo)',
      build: () {
        when(
          () => getAssignedRoutines(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('refresh-boom')));
        return buildBloc();
      },
      act: (b) => b.add(RefreshProgress(userId, weekStart: monday)),
      expect: () => [
        isA<ProgressFailure>().having(
          (s) => s.message,
          'message',
          'refresh-boom',
        ),
      ],
    );
  });

  blocTest<ProgressBloc, ProgressState>(
    'Ready incluye los ejercicios de las rutinas, sin repetir y por nombre',
    build: () {
      const press = Exercise(
        id: 'e1',
        routineDayId: 'd1',
        name: 'Press banca',
        targetMuscle: 'Pecho',
        targetWeight: 60,
        targetReps: 8,
      );
      const curl = Exercise(
        id: 'e2',
        routineDayId: 'd2',
        name: 'Curl',
        targetMuscle: 'Bíceps',
        targetWeight: 12,
        targetReps: 10,
      );
      when(
        () => getAssignedRoutines(any()),
      ).thenAnswer((_) async => const Right([routineA, routineB]));
      when(
        () => repository.getWeeklyInsights(
          routineId: any(named: 'routineId'),
          weekStart: any(named: 'weekStart'),
        ),
      ).thenAnswer((_) async => Right(testWeeklyInsights));
      when(() => repository.getRoutineDays('r1')).thenAnswer(
        (_) async => const Right([
          RoutineDay(
            id: 'd1',
            routineId: 'r1',
            dayOfWeek: 1,
            name: 'A',
            exercises: [press, curl],
          ),
        ]),
      );
      when(() => repository.getRoutineDays('r2')).thenAnswer(
        (_) async => const Right([
          RoutineDay(
            id: 'd2',
            routineId: 'r2',
            dayOfWeek: 1,
            name: 'B',
            exercises: [curl],
          ),
        ]),
      );
      return buildBloc();
    },
    act: (b) => b.add(LoadProgress(userId, weekStart: monday)),
    verify: (b) {
      final state = b.state as ProgressReady;
      expect(state.exercises.map((e) => e.name), ['Curl', 'Press banca']);
    },
  );

  group('combineWeeklyInsights', () {
    WeeklyInsights week({
      required int planned,
      required int done,
      required double volume,
      required double previous,
    }) => testWeeklyInsights.copyWithForTest(
      plannedDays: planned,
      completedDays: done,
      completedSessions: done,
      totalVolume: volume,
      previousWeekVolume: previous,
    );

    test('suma totales y recalcula adherencia y tendencia', () {
      final c = combineWeeklyInsights([
        week(planned: 4, done: 2, volume: 3000, previous: 2000),
        week(planned: 2, done: 1, volume: 1000, previous: 2000),
      ]);
      expect(c.plannedDays, 6);
      expect(c.completedDays, 3);
      expect(c.completedSessions, 3);
      expect(c.totalVolume, 4000);
      expect(c.adherenceRate, 50);
      expect(c.volumeTrendPercent, 0);
    });

    test('una sola rutina se devuelve tal cual', () {
      expect(combineWeeklyInsights([testWeeklyInsights]), testWeeklyInsights);
    });
  });
}

extension on WeeklyInsights {
  WeeklyInsights copyWithForTest({
    required int plannedDays,
    required int completedDays,
    required int completedSessions,
    required double totalVolume,
    required double previousWeekVolume,
  }) => WeeklyInsights(
    weekStart: weekStart,
    weekEnd: weekEnd,
    plannedDays: plannedDays,
    completedDays: completedDays,
    completedSessions: completedSessions,
    adherenceRate: 0,
    totalVolume: totalVolume,
    previousWeekVolume: previousWeekVolume,
    volumeTrendPercent: 0,
    personalRecords: 0,
  );
}
