import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_history_session.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_state.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

void main() {
  late ExerciseStatsBloc exerciseStatsBloc;
  late MockWorkoutRepository mockWorkoutRepository;

  setUp(() {
    mockWorkoutRepository = MockWorkoutRepository();
    exerciseStatsBloc = ExerciseStatsBloc(repository: mockWorkoutRepository);
  });

  tearDown(() {
    exerciseStatsBloc.close();
  });

  const tUserId = 'u1';
  const tExerciseId = 'e1';
  final tHistory = [
    ExerciseHistorySession(
      sessionDate: DateTime(2026, 4, 1),
      logs: [
        SetLog(
          id: 'l1',
          sessionId: 's1',
          exerciseId: tExerciseId,
          actualWeight: 50,
          actualReps: 10,
          setIndex: 0,
          createdAt: DateTime(2026, 4, 1),
        ),
      ],
    ),
  ];

  group('LoadExerciseStats', () {
    blocTest<ExerciseStatsBloc, ExerciseStatsState>(
      'debe emitir [ExerciseStatsLoading, ExerciseStatsLoaded] cuando es exitoso',
      build: () {
        when(
          () => mockWorkoutRepository.getExerciseLogsHistory(any(), any()),
        ).thenAnswer((_) async => Right(tHistory));
        return exerciseStatsBloc;
      },
      act: (bloc) => bloc.add(
        const LoadExerciseStats(userId: tUserId, exerciseId: tExerciseId),
      ),
      expect: () => [
        isA<ExerciseStatsLoading>(),
        ExerciseStatsLoaded(history: tHistory),
      ],
    );

    blocTest<ExerciseStatsBloc, ExerciseStatsState>(
      'debe emitir [ExerciseStatsLoading, ExerciseStatsError] cuando falla',
      build: () {
        when(
          () => mockWorkoutRepository.getExerciseLogsHistory(any(), any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Error stats')));
        return exerciseStatsBloc;
      },
      act: (bloc) => bloc.add(
        const LoadExerciseStats(userId: tUserId, exerciseId: tExerciseId),
      ),
      expect: () => [
        isA<ExerciseStatsLoading>(),
        const ExerciseStatsError(message: 'Error stats'),
      ],
    );
  });
}
