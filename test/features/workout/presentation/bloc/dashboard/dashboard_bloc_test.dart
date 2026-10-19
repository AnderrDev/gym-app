import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_assigned_routines.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_weekly_plan.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/dashboard/dashboard_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/mocks.dart';

class _MockGetAssignedRoutines extends Mock implements GetAssignedRoutines {}

class _MockGetWeeklyPlan extends Mock implements GetWeeklyPlan {}

void main() {
  late _MockGetAssignedRoutines getAssignedRoutines;
  late _MockGetWeeklyPlan getWeeklyPlan;
  late MockWorkoutRepository repository;

  const userId = 'u1';
  const routineA = Routine(id: 'r1', name: 'Push/Pull', exerciseCount: 6);
  const routineB = Routine(id: 'r2', name: 'Full body', exerciseCount: 4);
  final mondayThisWeek = DateTime(2026, 5, 4); // un lunes
  final monday = DateTime(2026, 5, 4); // mismo lunes ya normalizado

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    getAssignedRoutines = _MockGetAssignedRoutines();
    getWeeklyPlan = _MockGetWeeklyPlan();
    repository = MockWorkoutRepository();
    when(
      () => repository.getWeekSessions(any(), any(), any()),
    ).thenAnswer((_) async => const Right(<WorkoutSession>[]));
  });

  DashboardBloc buildBloc() => DashboardBloc(
    getAssignedRoutines: getAssignedRoutines,
    getWeeklyPlan: getWeeklyPlan,
    repository: repository,
  );

  blocTest<DashboardBloc, DashboardState>(
    'una respuesta lenta de otra semana no pisa a la semana actual',
    build: () {
      const dayOld = RoutineDay(
        id: 'old',
        routineId: 'r1',
        dayOfWeek: 1,
        name: 'Vieja',
      );
      const dayNew = RoutineDay(
        id: 'new',
        routineId: 'r1',
        dayOfWeek: 1,
        name: 'Nueva',
      );
      final previousWeek = DateTime(2026, 4, 27);
      when(
        () => getWeeklyPlan(
          userId: any(named: 'userId'),
          routineId: any(named: 'routineId'),
          weekStart: any(named: 'weekStart'),
        ),
      ).thenAnswer((inv) async {
        final week = inv.namedArguments[#weekStart] as DateTime;
        if (week == previousWeek) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return const Right([dayOld]);
        }
        return const Right([dayNew]);
      });
      when(
        () => repository.getWeeklyInsights(
          routineId: any(named: 'routineId'),
          weekStart: any(named: 'weekStart'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure('x')));
      return buildBloc();
    },
    act: (b) {
      b.add(
        LoadWeeklyPlan(
          userId: userId,
          routine: routineA,
          weekStart: DateTime(2026, 4, 27),
        ),
      );
      b.add(
        LoadWeeklyPlan(userId: userId, routine: routineA, weekStart: monday),
      );
    },
    wait: const Duration(milliseconds: 200),
    verify: (b) {
      expect(b.state.weekStart, monday);
      expect(b.state.weeklyDays.single.id, 'new');
    },
  );

  group('cambio de rutina', () {
    blocTest<DashboardBloc, DashboardState>(
      'ClearSelectedRoutine vuelve al selector',
      build: buildBloc,
      seed: () => DashboardState(
        status: DashboardStatus.ready,
        routines: const [routineA, routineB],
        selectedRoutine: routineA,
        weekStart: monday,
      ),
      act: (b) => b.add(const ClearSelectedRoutine()),
      verify: (b) {
        expect(b.state.selectedRoutine, isNull);
        expect(b.state.hasWeeklyPlan, isFalse);
      },
    );

    blocTest<DashboardBloc, DashboardState>(
      'si la rutina elegida ya no está asignada se deja de mostrar',
      build: () {
        when(
          () => getAssignedRoutines(any()),
        ).thenAnswer((_) async => const Right([routineB]));
        when(
          () => getWeeklyPlan(
            userId: any(named: 'userId'),
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => const Right([]));
        when(
          () => repository.getWeeklyInsights(
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('x')));
        return buildBloc();
      },
      seed: () => DashboardState(
        status: DashboardStatus.ready,
        routines: const [routineA, routineB],
        selectedRoutine: routineA,
        weekStart: monday,
      ),
      act: (b) => b.add(const LoadAssignedRoutines(userId)),
      wait: const Duration(milliseconds: 50),
      verify: (b) => expect(b.state.selectedRoutine?.id, isNot(routineA.id)),
    );
  });

  group('LoadAssignedRoutines', () {
    blocTest<DashboardBloc, DashboardState>(
      'failure → DashboardStatus.failure con errorMessage',
      build: () {
        when(
          () => getAssignedRoutines(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('boom')));
        return buildBloc();
      },
      act: (b) => b.add(const LoadAssignedRoutines(userId)),
      expect: () => [
        isA<DashboardState>().having(
          (s) => s.status,
          'status',
          DashboardStatus.loadingRoutines,
        ),
        isA<DashboardState>()
            .having((s) => s.status, 'status', DashboardStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'boom'),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'múltiples rutinas → status ready, sin auto-load',
      build: () {
        when(
          () => getAssignedRoutines(any()),
        ).thenAnswer((_) async => const Right([routineA, routineB]));
        return buildBloc();
      },
      act: (b) => b.add(const LoadAssignedRoutines(userId)),
      expect: () => [
        isA<DashboardState>().having(
          (s) => s.status,
          'status',
          DashboardStatus.loadingRoutines,
        ),
        isA<DashboardState>()
            .having((s) => s.status, 'status', DashboardStatus.ready)
            .having((s) => s.routines.length, 'routines.length', 2),
      ],
      verify: (_) {
        verifyNever(
          () => getWeeklyPlan(
            userId: any(named: 'userId'),
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        );
      },
    );

    blocTest<DashboardBloc, DashboardState>(
      'una sola rutina → auto-load del plan semanal',
      build: () {
        when(
          () => getAssignedRoutines(any()),
        ).thenAnswer((_) async => const Right([routineA]));
        when(
          () => getWeeklyPlan(
            userId: any(named: 'userId'),
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => const Right(<RoutineDay>[]));
        when(
          () => repository.getWeeklyInsights(
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('nope')));
        return buildBloc();
      },
      act: (b) => b.add(const LoadAssignedRoutines(userId)),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(
          () => getWeeklyPlan(
            userId: userId,
            routineId: routineA.id,
            weekStart: any(named: 'weekStart'),
          ),
        ).called(1);
      },
    );
  });

  group('LoadWeeklyPlan', () {
    final insights = WeeklyInsights(
      weekStart: monday,
      weekEnd: monday.add(const Duration(days: 6)),
      plannedDays: 5,
      completedDays: 3,
      completedSessions: 3,
      adherenceRate: 0.6,
      totalVolume: 1000,
      previousWeekVolume: 900,
      volumeTrendPercent: 10,
      personalRecords: 1,
    );

    blocTest<DashboardBloc, DashboardState>(
      'éxito de days + insights → status ready con datos',
      build: () {
        when(
          () => getWeeklyPlan(
            userId: any(named: 'userId'),
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer(
          (_) async => Right<Failure, List<RoutineDay>>([
            RoutineDay(
              id: 'd1',
              routineId: routineA.id,
              dayOfWeek: 1,
              name: 'Día 1',
              exercises: const [],
            ),
          ]),
        );
        when(
          () => repository.getWeeklyInsights(
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => Right(insights));
        return buildBloc();
      },
      act: (b) => b.add(
        LoadWeeklyPlan(
          userId: userId,
          routine: routineA,
          weekStart: mondayThisWeek,
        ),
      ),
      expect: () => [
        isA<DashboardState>().having(
          (s) => s.status,
          'status',
          DashboardStatus.loadingWeeklyPlan,
        ),
        isA<DashboardState>()
            .having((s) => s.status, 'status', DashboardStatus.ready)
            .having((s) => s.weeklyDays.length, 'weeklyDays.length', 1)
            .having(
              (s) => s.selectedRoutine?.id,
              'selectedRoutine.id',
              routineA.id,
            )
            .having((s) => s.insights, 'insights', insights),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'falla days → status failure',
      build: () {
        when(
          () => getWeeklyPlan(
            userId: any(named: 'userId'),
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('week down')));
        when(
          () => repository.getWeeklyInsights(
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('insights down')));
        return buildBloc();
      },
      act: (b) => b.add(
        LoadWeeklyPlan(
          userId: userId,
          routine: routineA,
          weekStart: mondayThisWeek,
        ),
      ),
      expect: () => [
        isA<DashboardState>().having(
          (s) => s.status,
          'status',
          DashboardStatus.loadingWeeklyPlan,
        ),
        isA<DashboardState>()
            .having((s) => s.status, 'status', DashboardStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'week down'),
      ],
    );
  });
}
