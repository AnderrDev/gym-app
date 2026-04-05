import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_history_session.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_stats/routine_stats_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_stats/routine_stats_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_stats/routine_stats_state.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

void main() {
  late RoutineStatsBloc routineStatsBloc;
  late MockWorkoutRepository mockWorkoutRepository;

  setUp(() {
    mockWorkoutRepository = MockWorkoutRepository();
    routineStatsBloc = RoutineStatsBloc(repository: mockWorkoutRepository);
  });

  tearDown(() {
    routineStatsBloc.close();
  });

  const tUserId = 'u1';
  const tRoutineId = 'r1';
  final tStats = [
    RoutineHistorySession(
      sessionDate: DateTime(2026, 4, 1),
      routineDayId: 'd1',
      routineDayName: 'Day 1',
      totalVolume: 5000,
      totalReps: 100,
      exerciseCount: 5,
    ),
  ];

  group('FetchRoutineStats', () {
    blocTest<RoutineStatsBloc, RoutineStatsState>(
      'debe emitir [RoutineStatsLoading, RoutineStatsLoaded] cuando es exitoso',
      build: () {
        when(
          () => mockWorkoutRepository.getRoutineStats(any(), any()),
        ).thenAnswer((_) async => Right(tStats));
        return routineStatsBloc;
      },
      act: (bloc) => bloc.add(
        const FetchRoutineStats(userId: tUserId, routineId: tRoutineId),
      ),
      expect: () => [isA<RoutineStatsLoading>(), RoutineStatsLoaded(tStats)],
    );

    blocTest<RoutineStatsBloc, RoutineStatsState>(
      'debe emitir [RoutineStatsLoading, RoutineStatsError] cuando falla',
      build: () {
        when(
          () => mockWorkoutRepository.getRoutineStats(any(), any()),
        ).thenAnswer(
          (_) async => const Left(ServerFailure('Error routine stats')),
        );
        return routineStatsBloc;
      },
      act: (bloc) => bloc.add(
        const FetchRoutineStats(userId: tUserId, routineId: tRoutineId),
      ),
      expect: () => [
        isA<RoutineStatsLoading>(),
        const RoutineStatsError('Error routine stats'),
      ],
    );
  });
}
