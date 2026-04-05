import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/core/services/active_session_service.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';
import 'package:gym_flutter/features/workout/domain/usecases/assign_routine.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_all_routines.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_assigned_routines.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_weekly_plan.dart';
import 'package:gym_flutter/features/workout/domain/usecases/save_set_log.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_fixtures.dart';

class MockGetAssignedRoutines extends Mock implements GetAssignedRoutines {}

class MockGetWeeklyPlan extends Mock implements GetWeeklyPlan {}

class MockSaveSetLog extends Mock implements SaveSetLog {}

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

class MockActiveSessionService extends Mock implements ActiveSessionService {}

class MockAssignRoutine extends Mock implements AssignRoutine {}

class MockGetAllRoutines extends Mock implements GetAllRoutines {}

void main() {
  late MockGetAssignedRoutines mockGetAssignedRoutines;
  late MockGetWeeklyPlan mockGetWeeklyPlan;
  late MockSaveSetLog mockSaveSetLog;
  late MockWorkoutRepository mockRepository;
  late MockActiveSessionService mockActiveSessionService;
  late MockAssignRoutine mockAssignRoutine;
  late MockGetAllRoutines mockGetAllRoutines;

  setUp(() {
    mockGetAssignedRoutines = MockGetAssignedRoutines();
    mockGetWeeklyPlan = MockGetWeeklyPlan();
    mockSaveSetLog = MockSaveSetLog();
    mockRepository = MockWorkoutRepository();
    mockActiveSessionService = MockActiveSessionService();
    mockAssignRoutine = MockAssignRoutine();
    mockGetAllRoutines = MockGetAllRoutines();

    registerFallbackValue(testSessionDate);
  });

  WorkoutBloc buildBloc() {
    return WorkoutBloc(
      getAssignedRoutines: mockGetAssignedRoutines,
      getWeeklyPlan: mockGetWeeklyPlan,
      saveSetLog: mockSaveSetLog,
      repository: mockRepository,
      activeSessionService: mockActiveSessionService,
      assignRoutine: mockAssignRoutine,
      getAllRoutines: mockGetAllRoutines,
    );
  }

  group('FetchAssignedRoutines', () {
    blocTest<WorkoutBloc, WorkoutState>(
      'emite [WorkoutLoading, RoutinesLoaded] cuando tiene éxito',
      build: buildBloc,
      setUp: () {
        when(
          () => mockGetAssignedRoutines(any()),
        ).thenAnswer((_) async => const Right([testRoutine]));
      },
      act: (bloc) => bloc.add(const FetchAssignedRoutines('user-123')),
      expect: () => [
        WorkoutLoading(),
        const RoutinesLoaded([testRoutine]),
      ],
      verify: (_) {
        verify(() => mockGetAssignedRoutines('user-123')).called(1);
      },
    );
  });

  group('FetchWeeklyPlan', () {
    final now = DateTime(2026, 4, 6); // Lunes
    blocTest<WorkoutBloc, WorkoutState>(
      'emite [WorkoutLoading, WeeklyPlanLoaded] cuando tiene éxito',
      build: buildBloc,
      setUp: () {
        when(
          () => mockGetWeeklyPlan(
            userId: any(named: 'userId'),
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => const Right([testRoutineDay]));
        when(
          () => mockRepository.getWeeklyInsights(
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => Right(testWeeklyInsights));
        when(
          () => mockRepository.getRoutineById(any()),
        ).thenAnswer((_) async => Right(testRoutine));
      },
      act: (bloc) => bloc.add(
        FetchWeeklyPlan(
          userId: 'user-123',
          routineId: 'routine-123',
          weekStart: now,
        ),
      ),
      expect: () => [
        WorkoutLoading(),
        WeeklyPlanLoaded(
          const [testRoutineDay],
          now,
          routine: testRoutine,
          insights: testWeeklyInsights,
        ),
      ],
    );
  });

  group('LoadDayInfo', () {
    blocTest<WorkoutBloc, WorkoutState>(
      'emite [WorkoutLoading, DayInfoLoaded] cuando no hay sesión existente',
      build: buildBloc,
      setUp: () {
        when(
          () => mockRepository.getExercisesForDay(any()),
        ).thenAnswer((_) async => const Right(<Exercise>[]));
        when(
          () => mockRepository.getExistingSession(any(), any(), any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockRepository.getRecentSessionsForDay(
            any(),
            any(),
            any(),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(<WorkoutSession>[]));
        when(
          () => mockRepository.getActiveSessionForUser(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockRepository.getSetLogsForSessions(any()),
        ).thenAnswer((_) async => const Right(<String, List<SetLog>>{}));
        when(
          () => mockRepository.getLastExercisePerformances(any()),
        ).thenAnswer((_) async => const Right(<String, SetLog?>{}));
      },
      act: (bloc) => bloc.add(
        LoadDayInfo(
          userId: 'user-123',
          routineDayId: 'day-123',
          sessionDate: testSessionDate,
        ),
      ),
      expect: () => [
        WorkoutLoading(),
        DayInfoLoaded(
          exercises: const [],
          userId: 'user-123',
          routineDayId: 'day-123',
          sessionDate: testSessionDate,
          recentSessions: const [],
          recentSessionsLogs: const {},
          lastPerformances: const {},
        ),
      ],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'emite [WorkoutLoading, DayWorkoutStarted] cuando hay sesión existente',
      build: buildBloc,
      setUp: () {
        when(
          () => mockRepository.getExercisesForDay(any()),
        ).thenAnswer((_) async => const Right(<Exercise>[]));
        when(
          () => mockRepository.getExistingSession(any(), any(), any()),
        ).thenAnswer((_) async => Right(testWorkoutSession));
        when(
          () => mockRepository.getRecentSessionsForDay(
            any(),
            any(),
            any(),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(<WorkoutSession>[]));
        when(
          () => mockRepository.getActiveSessionForUser(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockRepository.getSetLogsForSessions(any()),
        ).thenAnswer((_) async => const Right(<String, List<SetLog>>{}));
        when(
          () => mockRepository.getLastExercisePerformances(any()),
        ).thenAnswer((_) async => const Right(<String, SetLog?>{}));
        when(
          () => mockRepository.getSessionSetLogs(any()),
        ).thenAnswer((_) async => const Right(<SetLog>[]));
      },
      act: (bloc) => bloc.add(
        LoadDayInfo(
          userId: 'user-123',
          routineDayId: 'day-1',
          sessionDate: testSessionDate,
        ),
      ),
      expect: () => [
        WorkoutLoading(),
        DayWorkoutStarted(
          testWorkoutSession,
          const [],
          setLogs: const [],
          lastPerformances: const {},
          recentSessions: const [],
          recentSessionsLogs: const {},
        ),
      ],
    );
  });

  group('ConfirmStartWorkout', () {
    blocTest<WorkoutBloc, WorkoutState>(
      'emite [WorkoutLoading, DayWorkoutStarted] y guarda en service al iniciar con éxito',
      build: buildBloc,
      setUp: () {
        when(
          () => mockRepository.startWorkoutForDay(any(), any(), any()),
        ).thenAnswer((_) async => Right(testWorkoutSession));
        when(
          () => mockRepository.getExercisesForDay(any()),
        ).thenAnswer((_) async => const Right(<Exercise>[]));
        when(
          () => mockRepository.getRecentSessionsForDay(
            any(),
            any(),
            any(),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(<WorkoutSession>[]));
        when(
          () => mockRepository.getSessionSetLogs(any()),
        ).thenAnswer((_) async => const Right(<SetLog>[]));
        when(
          () => mockRepository.getSetLogsForSessions(any()),
        ).thenAnswer((_) async => const Right(<String, List<SetLog>>{}));
        when(
          () => mockRepository.getLastExercisePerformances(any()),
        ).thenAnswer((_) async => const Right(<String, SetLog?>{}));
        when(
          () => mockActiveSessionService.save(
            sessionId: any(named: 'sessionId'),
            routineDayId: any(named: 'routineDayId'),
            userId: any(named: 'userId'),
            sessionDate: any(named: 'sessionDate'),
            routineDayName: any(named: 'routineDayName'),
          ),
        ).thenAnswer((_) async => {});
      },
      act: (bloc) => bloc.add(
        ConfirmStartWorkout(
          userId: 'user-123',
          routineDayId: 'day-1',
          sessionDate: testSessionDate,
          routineDayName: 'Monday Workout',
        ),
      ),
      expect: () => [
        WorkoutLoading(),
        DayWorkoutStarted(
          testWorkoutSession,
          const [],
          setLogs: const [],
          lastPerformances: const {},
          recentSessions: const [],
          recentSessionsLogs: const {},
        ),
      ],
      verify: (_) {
        verify(
          () => mockActiveSessionService.save(
            sessionId: testWorkoutSession.id,
            routineDayId: testWorkoutSession.routineDayId,
            userId: 'user-123',
            sessionDate: testSessionDate,
            routineDayName: 'Monday Workout',
          ),
        ).called(1);
      },
    );
  });

  group('FinishWorkoutSession', () {
    blocTest<WorkoutBloc, WorkoutState>(
      'emite [WorkoutLoading, WorkoutFinishedSuccess] y limpia service al finalizar',
      build: buildBloc,
      setUp: () {
        when(
          () => mockRepository.finishWorkoutSession(
            any(),
            coachingAnalysis: any(named: 'coachingAnalysis'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockActiveSessionService.clear(),
        ).thenAnswer((_) async => {});
      },
      act: (bloc) => bloc.add(const FinishWorkoutSession('session-123')),
      expect: () => [WorkoutLoading(), WorkoutFinishedSuccess()],
      verify: (_) {
        verify(() => mockActiveSessionService.clear()).called(1);
      },
    );
  });
}
