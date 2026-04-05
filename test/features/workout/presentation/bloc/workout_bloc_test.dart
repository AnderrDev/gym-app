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

class MockGetAssignedRoutines extends Mock implements GetAssignedRoutines {}

class MockGetWeeklyPlan extends Mock implements GetWeeklyPlan {}

class MockSaveSetLog extends Mock implements SaveSetLog {}

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

class MockActiveSessionService extends Mock implements ActiveSessionService {}

class MockAssignRoutine extends Mock implements AssignRoutine {}

class MockGetAllRoutines extends Mock implements GetAllRoutines {}

void main() {
  late WorkoutBloc workoutBloc;
  late MockGetAssignedRoutines mockGetAssignedRoutines;
  late MockGetWeeklyPlan mockGetWeeklyPlan;
  late MockSaveSetLog mockSaveSetLog;
  late MockWorkoutRepository mockWorkoutRepository;
  late MockActiveSessionService mockActiveSessionService;
  late MockAssignRoutine mockAssignRoutine;
  late MockGetAllRoutines mockGetAllRoutines;

  const tUserId = 'u1';
  const tRoutineId = 'r1';
  const tRoutine = Routine(id: tRoutineId, name: 'Test', exerciseCount: 0);
  final tDate = DateTime(2026, 4, 5);

  setUpAll(() {
    registerFallbackValue(DateTime.now());
    registerFallbackValue(
      const SetLog(
        sessionId: '',
        exerciseId: '',
        actualWeight: 0,
        actualReps: 0,
        setIndex: 0,
      ),
    );
    registerFallbackValue(const Routine(id: '', name: '', exerciseCount: 0));
    registerFallbackValue(
      const RoutineDay(
        id: '',
        routineId: '',
        dayOfWeek: 1,
        name: '',
        exercises: [],
      ),
    );
  });

  setUp(() {
    mockGetAssignedRoutines = MockGetAssignedRoutines();
    mockGetWeeklyPlan = MockGetWeeklyPlan();
    mockSaveSetLog = MockSaveSetLog();
    mockWorkoutRepository = MockWorkoutRepository();
    mockActiveSessionService = MockActiveSessionService();
    mockAssignRoutine = MockAssignRoutine();
    mockGetAllRoutines = MockGetAllRoutines();

    workoutBloc = WorkoutBloc(
      getAssignedRoutines: mockGetAssignedRoutines,
      getWeeklyPlan: mockGetWeeklyPlan,
      saveSetLog: mockSaveSetLog,
      repository: mockWorkoutRepository,
      activeSessionService: mockActiveSessionService,
      assignRoutine: mockAssignRoutine,
      getAllRoutines: mockGetAllRoutines,
    );
  });

  tearDown(() {
    workoutBloc.close();
  });

  group('FetchAssignedRoutines', () {
    blocTest<WorkoutBloc, WorkoutState>(
      'debe emitir [WorkoutLoading, RoutinesLoaded] cuando es exitoso',
      build: () {
        when(
          () => mockGetAssignedRoutines(any()),
        ).thenAnswer((_) async => const Right(<Routine>[]));
        return workoutBloc;
      },
      act: (bloc) => bloc.add(const FetchAssignedRoutines(tUserId)),
      expect: () => [isA<WorkoutLoading>(), isA<RoutinesLoaded>()],
    );
  });

  group('FetchWeeklyPlan', () {
    final tInsights = WeeklyInsights(
      weekStart: tDate,
      weekEnd: tDate,
      plannedDays: 5,
      completedDays: 3,
      completedSessions: 3,
      adherenceRate: 0.6,
      totalVolume: 1000,
      previousWeekVolume: 900,
      volumeTrendPercent: 10,
      personalRecords: 1,
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'debe emitir [WorkoutLoading, WeeklyPlanLoaded] cuando es exitoso',
      build: () {
        when(
          () => mockGetWeeklyPlan(
            userId: any(named: 'userId'),
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => const Right(<RoutineDay>[]));
        when(
          () => mockWorkoutRepository.getWeeklyInsights(
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => Right(tInsights));
        when(
          () => mockWorkoutRepository.getRoutineById(any()),
        ).thenAnswer((_) async => const Right(tRoutine));
        return workoutBloc;
      },
      act: (bloc) => bloc.add(
        FetchWeeklyPlan(
          userId: tUserId,
          routineId: tRoutineId,
          weekStart: tDate,
        ),
      ),
      expect: () => [isA<WorkoutLoading>(), isA<WeeklyPlanLoaded>()],
    );
  });

  group('LoadDayInfo', () {
    blocTest<WorkoutBloc, WorkoutState>(
      'debe emitir [WorkoutLoading, DayInfoLoaded] cuando no hay sesión activa',
      build: () {
        when(
          () => mockWorkoutRepository.getExercisesForDay(any()),
        ).thenAnswer((_) async => const Right(<Exercise>[]));
        when(
          () => mockWorkoutRepository.getExistingSession(any(), any(), any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockWorkoutRepository.getRecentSessionsForDay(
            any(),
            any(),
            any(),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(<WorkoutSession>[]));
        when(
          () => mockWorkoutRepository.getActiveSessionForUser(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockWorkoutRepository.getSetLogsForSessions(any()),
        ).thenAnswer((_) async => const Right(<String, List<SetLog>>{}));
        when(
          () => mockWorkoutRepository.getLastExercisePerformances(any()),
        ).thenAnswer((_) async => const Right(<String, SetLog?>{}));
        return workoutBloc;
      },
      act: (bloc) => bloc.add(
        LoadDayInfo(userId: tUserId, routineDayId: 'd1', sessionDate: tDate),
      ),
      expect: () => [isA<WorkoutLoading>(), isA<DayInfoLoaded>()],
    );
  });

  group('ConfirmStartWorkout', () {
    final tSession = WorkoutSession(
      id: 's1',
      userId: tUserId,
      routineDayId: 'd1',
      sessionDate: tDate,
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'debe iniciar sesión y emitir DayWorkoutStarted',
      build: () {
        when(
          () => mockWorkoutRepository.startWorkoutForDay(any(), any(), any()),
        ).thenAnswer((_) async => Right(tSession));
        when(
          () => mockWorkoutRepository.getExercisesForDay(any()),
        ).thenAnswer((_) async => const Right(<Exercise>[]));
        when(
          () => mockWorkoutRepository.getRecentSessionsForDay(
            any(),
            any(),
            any(),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(<WorkoutSession>[]));
        when(
          () => mockWorkoutRepository.getSessionSetLogs(any()),
        ).thenAnswer((_) async => const Right(<SetLog>[]));
        when(
          () => mockWorkoutRepository.getSetLogsForSessions(any()),
        ).thenAnswer((_) async => const Right(<String, List<SetLog>>{}));
        when(
          () => mockWorkoutRepository.getLastExercisePerformances(any()),
        ).thenAnswer((_) async => const Right(<String, SetLog?>{}));
        when(
          () => mockActiveSessionService.save(
            sessionId: any(named: 'sessionId'),
            routineDayId: any(named: 'routineDayId'),
            userId: any(named: 'userId'),
            sessionDate: any(named: 'sessionDate'),
            routineDayName: any(named: 'routineDayName'),
          ),
        ).thenAnswer((_) async => Future.value());
        return workoutBloc;
      },
      act: (bloc) => bloc.add(
        ConfirmStartWorkout(
          userId: tUserId,
          routineDayId: 'd1',
          sessionDate: tDate,
          routineDayName: 'Day 1',
        ),
      ),
      expect: () => [isA<WorkoutLoading>(), isA<DayWorkoutStarted>()],
    );
  });

  group('AddSetLogEvent', () {
    final tSetLog = SetLog(
      id: 'l1',
      sessionId: 's1',
      exerciseId: 'e1',
      actualReps: 10,
      actualWeight: 50,
      setIndex: 0,
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'debe guardar el log y actualizar el estado',
      build: () {
        when(
          () => mockWorkoutRepository.saveSetLog(any()),
        ).thenAnswer((_) async => const Right(null));
        return workoutBloc;
      },
      seed: () => DayWorkoutStarted(
        WorkoutSession(
          id: 's1',
          userId: tUserId,
          routineDayId: 'd1',
          sessionDate: tDate,
        ),
        const [],
        setLogs: const [],
        lastPerformances: const {},
        recentSessions: const [],
        recentSessionsLogs: const {},
      ),
      act: (bloc) => bloc.add(AddSetLogEvent(tSetLog)),
      expect: () => [
        isA<DayWorkoutStarted>().having(
          (s) => s.setLogs.length,
          'logs count',
          1,
        ),
      ],
    );
  });

  group('FinishWorkoutSession', () {
    blocTest<WorkoutBloc, WorkoutState>(
      'debe finalizar sesión y emitir WorkoutFinishedSuccess',
      build: () {
        when(
          () => mockWorkoutRepository.finishWorkoutSession(
            any(),
            coachingAnalysis: any(named: 'coachingAnalysis'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockActiveSessionService.clear(),
        ).thenAnswer((_) async => Future.value());
        return workoutBloc;
      },
      act: (bloc) => bloc.add(const FinishWorkoutSession('s1')),
      expect: () => [isA<WorkoutLoading>(), isA<WorkoutFinishedSuccess>()],
    );
  });

  group('UpdateExerciseTarget', () {
    const tExerciseId = 'e1';
    final tExercise = Exercise(
      id: tExerciseId,
      routineDayId: 'd1',
      name: 'Push up',
      targetMuscle: 'Chest',
      targetReps: 10,
      targetWeight: 0,
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'debe actualizar el objetivo del ejercicio',
      build: () {
        when(
          () => mockWorkoutRepository.updateExerciseTarget(
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async => const Right(null));
        return workoutBloc;
      },
      seed: () => DayWorkoutStarted(
        WorkoutSession(
          id: 's1',
          userId: tUserId,
          routineDayId: 'd1',
          sessionDate: tDate,
        ),
        [tExercise],
        setLogs: const [],
        lastPerformances: const {},
        recentSessions: const [],
        recentSessionsLogs: const {},
      ),
      act: (bloc) => bloc.add(
        const UpdateExerciseTarget(
          exerciseId: tExerciseId,
          targetWeight: 10,
          targetReps: 12,
        ),
      ),
      expect: () => [
        isA<DayWorkoutStarted>().having(
          (s) => s.exercises.first.targetWeight,
          'target weight',
          10.0,
        ),
      ],
    );
  });

  group('Routine Management', () {
    blocTest<WorkoutBloc, WorkoutState>(
      'AssignRoutineEvent: debe activar rutina y refrescar lista',
      build: () {
        when(
          () => mockAssignRoutine(any(), any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetAssignedRoutines(any()),
        ).thenAnswer((_) async => const Right(<Routine>[]));
        return workoutBloc;
      },
      act: (bloc) => bloc.add(
        const AssignRoutineEvent(userId: tUserId, routineId: tRoutineId),
      ),
      expect: () => [
        isA<WorkoutLoading>(),
        isA<ManagementSuccess>(),
        isA<WorkoutLoading>(),
        isA<RoutinesLoaded>(),
      ],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'DeleteRoutine: debe eliminar rutina y refrescar lista',
      build: () {
        when(
          () => mockWorkoutRepository.deleteRoutine(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetAssignedRoutines(any()),
        ).thenAnswer((_) async => const Right(<Routine>[]));
        return workoutBloc;
      },
      act: (bloc) =>
          bloc.add(const DeleteRoutine(userId: tUserId, routineId: tRoutineId)),
      expect: () => [isA<WorkoutLoading>(), isA<RoutinesLoaded>()],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'CreateOrUpdateRoutine: debe guardar y refrescar',
      build: () {
        when(
          () => mockWorkoutRepository.saveRoutine(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetAssignedRoutines(any()),
        ).thenAnswer((_) async => const Right(<Routine>[]));
        return workoutBloc;
      },
      act: (bloc) =>
          bloc.add(const CreateOrUpdateRoutine(userId: tUserId, name: 'New')),
      expect: () => [isA<WorkoutLoading>(), isA<RoutinesLoaded>()],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'SaveRoutineDay: debe guardar día y refrescar plan',
      build: () {
        when(
          () => mockWorkoutRepository.saveRoutineDay(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetWeeklyPlan(
            userId: any(named: 'userId'),
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => const Right(<RoutineDay>[]));
        when(
          () => mockWorkoutRepository.getWeeklyInsights(
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer(
          (_) async => Right(
            WeeklyInsights(
              weekStart: tDate,
              weekEnd: tDate,
              plannedDays: 0,
              completedDays: 0,
              completedSessions: 0,
              adherenceRate: 0,
              totalVolume: 0,
              previousWeekVolume: 0,
              volumeTrendPercent: 0,
              personalRecords: 0,
            ),
          ),
        );
        when(
          () => mockWorkoutRepository.getRoutineById(any()),
        ).thenAnswer((_) async => const Right(tRoutine));
        return workoutBloc;
      },
      act: (bloc) => bloc.add(
        const SaveRoutineDay(
          userId: tUserId,
          routineId: tRoutineId,
          day: RoutineDay(
            id: 'd1',
            routineId: tRoutineId,
            dayOfWeek: 1,
            name: 'D1',
            exercises: [],
          ),
        ),
      ),
      expect: () => [
        isA<WorkoutLoading>(),
        isA<ManagementSuccess>(),
        isA<WorkoutLoading>(),
        isA<WeeklyPlanLoaded>(),
      ],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'ReorderExercises: debe reordenar y refrescar',
      build: () {
        when(
          () => mockWorkoutRepository.reorderExercisesInDay(any(), any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetWeeklyPlan(
            userId: any(named: 'userId'),
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => const Right(<RoutineDay>[]));
        when(
          () => mockWorkoutRepository.getWeeklyInsights(
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer(
          (_) async => Right(
            WeeklyInsights(
              weekStart: tDate,
              weekEnd: tDate,
              plannedDays: 0,
              completedDays: 0,
              completedSessions: 0,
              adherenceRate: 0,
              totalVolume: 0,
              previousWeekVolume: 0,
              volumeTrendPercent: 0,
              personalRecords: 0,
            ),
          ),
        );
        when(
          () => mockWorkoutRepository.getRoutineById(any()),
        ).thenAnswer((_) async => const Right(tRoutine));
        return workoutBloc;
      },
      act: (bloc) => bloc.add(
        const ReorderExercises(
          userId: tUserId,
          routineId: tRoutineId,
          dayId: 'd1',
          exerciseIds: ['e2'],
        ),
      ),
      expect: () => [
        isA<ManagementSuccess>(),
        isA<WorkoutLoading>(),
        isA<WeeklyPlanLoaded>(),
      ],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'CheckActiveSession: debe detectar sesión activa',
      build: () {
        final tSession = WorkoutSession(
          id: 's1',
          userId: tUserId,
          routineDayId: 'd1',
          sessionDate: tDate,
        );
        when(() => mockActiveSessionService.getContext()).thenReturn(null);
        when(
          () => mockWorkoutRepository.getActiveSessionForUser(any()),
        ).thenAnswer((_) async => Right(tSession));
        when(
          () => mockWorkoutRepository.getRoutineDayNameById(any()),
        ).thenAnswer((_) async => const Right('Day 1'));
        when(
          () => mockActiveSessionService.save(
            sessionId: any(named: 'sessionId'),
            routineDayId: any(named: 'routineDayId'),
            userId: any(named: 'userId'),
            sessionDate: any(named: 'sessionDate'),
            routineDayName: any(named: 'routineDayName'),
          ),
        ).thenAnswer((_) async => Future.value());
        return workoutBloc;
      },
      act: (bloc) => bloc.add(const CheckActiveSession(tUserId)),
      expect: () => [
        isA<ActiveSessionDetected>().having(
          (s) => s.sessionId,
          'sessionId',
          's1',
        ),
      ],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'FetchAllRoutines: debe cargar catálogo',
      build: () {
        when(
          () => mockGetAllRoutines(),
        ).thenAnswer((_) async => const Right(<Routine>[]));
        return workoutBloc;
      },
      act: (bloc) => bloc.add(const FetchAllRoutines()),
      expect: () => [isA<WorkoutLoading>(), isA<AllRoutinesLoaded>()],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'FetchWeeklyPlan: debe emitir [WorkoutLoading, WorkoutError] cuando falla',
      build: () {
        when(
          () => mockGetWeeklyPlan(
            userId: any(named: 'userId'),
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('Plan error')));
        when(
          () => mockWorkoutRepository.getWeeklyInsights(
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('Insights error')));
        when(
          () => mockWorkoutRepository.getRoutineById(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Routine error')));
        return workoutBloc;
      },
      act: (bloc) => bloc.add(
        FetchWeeklyPlan(
          userId: tUserId,
          routineId: tRoutineId,
          weekStart: tDate,
        ),
      ),
      expect: () => [
        isA<WorkoutLoading>(),
        isA<WorkoutError>().having(
          (e) => e.message,
          'message',
          contains('Plan error'),
        ),
      ],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'LoadDayInfo: debe emitir DayWorkoutStarted si ya existe sesión',
      build: () {
        final tSession = WorkoutSession(
          id: 's1',
          userId: tUserId,
          routineDayId: 'd1',
          sessionDate: tDate,
        );
        when(
          () => mockWorkoutRepository.getExercisesForDay(any()),
        ).thenAnswer((_) async => const Right(<Exercise>[]));
        when(
          () => mockWorkoutRepository.getExistingSession(any(), any(), any()),
        ).thenAnswer((_) async => Right(tSession));
        when(
          () => mockWorkoutRepository.getRecentSessionsForDay(
            any(),
            any(),
            any(),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(<WorkoutSession>[]));
        when(
          () => mockWorkoutRepository.getActiveSessionForUser(any()),
        ).thenAnswer((_) async => Right(tSession));
        when(
          () => mockWorkoutRepository.getSessionSetLogs(any()),
        ).thenAnswer((_) async => const Right(<SetLog>[]));
        when(
          () => mockWorkoutRepository.getSetLogsForSessions(any()),
        ).thenAnswer((_) async => const Right(<String, List<SetLog>>{}));
        when(
          () => mockWorkoutRepository.getLastExercisePerformances(any()),
        ).thenAnswer((_) async => const Right(<String, SetLog?>{}));
        return workoutBloc;
      },
      act: (bloc) => bloc.add(
        LoadDayInfo(userId: tUserId, routineDayId: 'd1', sessionDate: tDate),
      ),
      expect: () => [isA<WorkoutLoading>(), isA<DayWorkoutStarted>()],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'LoadDayInfo: debe detectar si hay otra sesión activa',
      build: () {
        final tOtherSession = WorkoutSession(
          id: 's_other',
          userId: tUserId,
          routineDayId: 'd_other',
          sessionDate: tDate,
        );
        when(
          () => mockWorkoutRepository.getExercisesForDay(any()),
        ).thenAnswer((_) async => const Right(<Exercise>[]));
        when(
          () => mockWorkoutRepository.getExistingSession(any(), any(), any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockWorkoutRepository.getRecentSessionsForDay(
            any(),
            any(),
            any(),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(<WorkoutSession>[]));
        when(
          () => mockWorkoutRepository.getActiveSessionForUser(any()),
        ).thenAnswer((_) async => Right(tOtherSession));
        when(
          () => mockWorkoutRepository.getRoutineDayNameById(any()),
        ).thenAnswer((_) async => const Right('Other Day'));
        when(
          () => mockWorkoutRepository.getSetLogsForSessions(any()),
        ).thenAnswer((_) async => const Right(<String, List<SetLog>>{}));
        when(
          () => mockWorkoutRepository.getLastExercisePerformances(any()),
        ).thenAnswer((_) async => const Right(<String, SetLog?>{}));
        return workoutBloc;
      },
      act: (bloc) => bloc.add(
        LoadDayInfo(userId: tUserId, routineDayId: 'd1', sessionDate: tDate),
      ),
      expect: () => [
        isA<WorkoutLoading>(),
        isA<DayInfoLoaded>().having(
          (s) => s.hasAnotherActiveSession,
          'hasAnotherActiveSession',
          true,
        ),
      ],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'ConfirmStartWorkout: debe manejar sesión conflictiva y redirigir',
      build: () {
        final tActiveSession = WorkoutSession(
          id: 's_active',
          userId: tUserId,
          routineDayId: 'd_active',
          sessionDate: tDate,
        );
        when(
          () => mockWorkoutRepository.startWorkoutForDay(any(), any(), any()),
        ).thenAnswer((_) async => Right(tActiveSession));
        when(
          () => mockWorkoutRepository.getExercisesForDay(any()),
        ).thenAnswer((_) async => const Right(<Exercise>[]));
        when(
          () => mockWorkoutRepository.getRecentSessionsForDay(
            any(),
            any(),
            any(),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(<WorkoutSession>[]));
        when(
          () => mockWorkoutRepository.getSessionSetLogs(any()),
        ).thenAnswer((_) async => const Right(<SetLog>[]));
        when(
          () => mockWorkoutRepository.getRoutineDayNameById(any()),
        ).thenAnswer((_) async => const Right('Active Day'));
        when(
          () => mockWorkoutRepository.getSetLogsForSessions(any()),
        ).thenAnswer((_) async => const Right(<String, List<SetLog>>{}));
        when(
          () => mockWorkoutRepository.getLastExercisePerformances(any()),
        ).thenAnswer((_) async => const Right(<String, SetLog?>{}));
        return workoutBloc;
      },
      act: (bloc) => bloc.add(
        ConfirmStartWorkout(
          userId: tUserId,
          routineDayId: 'd_requested',
          sessionDate: tDate,
          routineDayName: 'Requested Day',
        ),
      ),
      expect: () => [
        isA<WorkoutLoading>(),
        isA<DayInfoLoaded>().having(
          (s) => s.hasAnotherActiveSession,
          'hasAnotherActiveSession',
          true,
        ),
      ],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'ToggleExerciseInDay: debe alternar ejercicio y refrescar plan',
      build: () {
        when(
          () => mockWorkoutRepository.toggleExerciseInDay(any(), any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetWeeklyPlan(
            userId: any(named: 'userId'),
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => const Right(<RoutineDay>[]));
        when(
          () => mockWorkoutRepository.getWeeklyInsights(
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer(
          (_) async => Right(
            WeeklyInsights(
              weekStart: tDate,
              weekEnd: tDate,
              plannedDays: 0,
              completedDays: 0,
              completedSessions: 0,
              adherenceRate: 0,
              totalVolume: 0,
              previousWeekVolume: 0,
              volumeTrendPercent: 0,
              personalRecords: 0,
            ),
          ),
        );
        when(
          () => mockWorkoutRepository.getRoutineById(any()),
        ).thenAnswer((_) async => const Right(tRoutine));
        return workoutBloc;
      },
      act: (bloc) => bloc.add(
        const ToggleExerciseInDay(
          userId: tUserId,
          routineId: tRoutineId,
          dayId: 'd1',
          exerciseId: 'e1',
        ),
      ),
      expect: () => [
        isA<ManagementSuccess>(),
        isA<WorkoutLoading>(),
        isA<WeeklyPlanLoaded>(),
      ],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'ResetWorkout: debe volver al estado inicial',
      build: () => workoutBloc,
      act: (bloc) => bloc.add(ResetWorkout()),
      expect: () => [isA<WorkoutInitial>()],
    );
  });
}
