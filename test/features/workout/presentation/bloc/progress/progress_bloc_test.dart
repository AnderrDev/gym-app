import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
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
  });

  ProgressBloc buildBloc() => ProgressBloc(
    getAssignedRoutines: getAssignedRoutines,
    repository: repository,
  );

  group('LoadProgress', () {
    blocTest<ProgressBloc, ProgressState>(
      'éxito de routines + insights → Loading → Ready con ambos',
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
            .having((s) => s.insights, 'insights', testWeeklyInsights)
            .having((s) => s.insightsError, 'insightsError', isNull),
      ],
      verify: (_) {
        // Insights se piden contra la PRIMERA rutina asignada.
        verify(
          () => repository.getWeeklyInsights(
            routineId: routineA.id,
            weekStart: any(named: 'weekStart'),
          ),
        ).called(1);
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
}
