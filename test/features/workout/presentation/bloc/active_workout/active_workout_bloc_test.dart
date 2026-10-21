import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/notifications/active_workout_notifier.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/core/services/active_session_service.dart';
import 'package:gym_flutter/core/services/workout_draft_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_flutter/core/utils/clock.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/mocks.dart';

class _MockActiveSessionService extends Mock implements ActiveSessionService {}

class _MockActiveWorkoutNotifier extends Mock
    implements ActiveWorkoutNotifier {}

class _MockWorkoutDraftService extends Mock implements WorkoutDraftService {}

void main() {
  late MockWorkoutRepository repository;
  late _MockActiveSessionService activeSessionService;
  late _MockActiveWorkoutNotifier notifier;

  const userId = 'u1';
  const routineDayId = 'd1';
  const sessionId = 's1';
  final sessionDate = DateTime(2026, 5, 4);
  const exerciseA = Exercise(
    id: 'e1',
    routineDayId: routineDayId,
    name: 'Press',
    targetMuscle: 'Pecho',
    targetSets: 3,
    targetReps: 10,
    targetWeight: 80,
    restTimerSeconds: 60,
  );
  final session = WorkoutSession(
    id: sessionId,
    userId: userId,
    routineDayId: routineDayId,
    sessionDate: sessionDate,
  );

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(
      const SetLog(
        sessionId: '',
        exerciseId: '',
        actualWeight: 0,
        actualReps: 0,
        setIndex: 0,
      ),
    );
  });

  setUp(() {
    repository = MockWorkoutRepository();
    activeSessionService = _MockActiveSessionService();
    notifier = _MockActiveWorkoutNotifier();
    when(
      () => notifier.onPlanChanged(
        totalSets: any(named: 'totalSets'),
        completedSets: any(named: 'completedSets'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.getSessionExercises(
        any(),
        routineDayId: any(named: 'routineDayId'),
      ),
    ).thenAnswer((_) async => const Right([exerciseA]));
    when(
      () => repository.getLastExercisePerformances(any()),
    ).thenAnswer((_) async => const Right(<String, SetLog?>{}));
    when(
      () => repository.getSessionCoaching(any()),
    ).thenAnswer((_) async => const Right(<CoachingAnalysis>[]));
    when(
      () => activeSessionService.save(
        sessionId: any(named: 'sessionId'),
        routineDayId: any(named: 'routineDayId'),
        userId: any(named: 'userId'),
        sessionDate: any(named: 'sessionDate'),
        routineDayName: any(named: 'routineDayName'),
      ),
    ).thenAnswer((_) async {});
    when(() => activeSessionService.clear()).thenAnswer((_) async {});
    when(
      () => notifier.onStarted(
        dayName: any(named: 'dayName'),
        totalSets: any(named: 'totalSets'),
        sessionStartedAt: any(named: 'sessionStartedAt'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => notifier.onProgress(completedSets: any(named: 'completedSets')),
    ).thenAnswer((_) async {});
    when(() => notifier.onEnded()).thenAnswer((_) async {});
  });

  // Mediodía de un día distinto a `sessionDate`: el bloc debe fechar la
  // sesión con "hoy" (sin hora), no con la fecha del día abierto.
  final clock = FakeClock(DateTime(2026, 5, 6, 13, 45));

  ActiveWorkoutBloc buildBloc() => ActiveWorkoutBloc(
    repository: repository,
    activeSessionService: activeSessionService,
    notifier: notifier,
    clock: clock,
  );

  for (final succeeds in [true, false]) {
    test(
      'sustituir conserva series realizadas y sesión utilizable: éxito=$succeeds',
      () async {
        const log = SetLog(
          sessionId: sessionId,
          exerciseId: 'e1',
          setIndex: 1,
          actualWeight: 80,
          actualReps: 10,
        );
        final original = exerciseA.copyWith(
          targetSets: 1,
          replacedByExerciseName: 'Remo',
        );
        const replacement = Exercise(
          id: 'e2',
          routineDayId: routineDayId,
          name: 'Remo',
          targetMuscle: 'Espalda',
          targetSets: 2,
          targetWeight: 20,
          targetReps: 12,
          replacesExerciseName: 'Press',
        );
        when(
          () => repository.adaptSessionExercise(
            sessionId,
            'e2',
            targetSets: 2,
            targetReps: 12,
            targetWeight: 20,
            replaceExerciseId: 'e1',
          ),
        ).thenAnswer(
          (_) async => succeeds
              ? Right([original, replacement])
              : const Left(NetworkFailure()),
        );
        final bloc = buildBloc()
          ..emit(
            ActiveWorkoutState(
              status: ActiveWorkoutStatus.running,
              session: session,
              exercises: const [exerciseA],
              setLogs: const [log],
            ),
          );
        final finished = bloc.stream.firstWhere((s) => !s.isAdapting);
        bloc.add(
          const AdaptActiveWorkoutExercise(
            exerciseId: 'e2',
            targetSets: 2,
            targetReps: 12,
            targetWeight: 20,
            replaceExerciseId: 'e1',
          ),
        );
        final state = await finished;
        expect(state.isRunning, true);
        expect(state.setLogs, const [log]);
        expect(
          state.exercises,
          succeeds ? [original, replacement] : [exerciseA],
        );
        expect(
          state.actionError,
          succeeds ? isNull : contains('No se pudo adaptar'),
        );
        verifyNever(
          () => repository.updateExerciseTarget(any(), any(), any(), any()),
        );
        await bloc.close();
      },
    );
  }

  test('editar objetivo de un extra solo actualiza la sesión actual', () async {
    final changed = exerciseA.copyWith(targetWeight: 82.5);
    when(
      () => repository.updateSessionExerciseTarget(sessionId, 'e1', 82.5, 10),
    ).thenAnswer((_) async => Right([changed]));
    final bloc = buildBloc()
      ..emit(
        ActiveWorkoutState(
          status: ActiveWorkoutStatus.running,
          session: session,
          exercises: const [exerciseA],
        ),
      );
    final edited = bloc.stream.first;
    bloc.add(
      const UpdateActiveExerciseTarget(
        exerciseId: 'e1',
        targetWeight: 82.5,
        targetReps: 10,
      ),
    );
    expect((await edited).exercises.single.targetWeight, 82.5);
    verifyNever(
      () => repository.updateExerciseTarget(any(), any(), any(), any()),
    );
    await bloc.close();
  });

  test(
    'reanudar recupera extras del plan guardado, no de la rutina base',
    () async {
      const extra = Exercise(
        id: 'extra',
        routineDayId: routineDayId,
        name: 'Remo',
        targetMuscle: 'Espalda',
        targetWeight: 30,
        targetReps: 12,
        isExtra: true,
      );
      when(
        () => repository.getSessionExercises(
          sessionId,
          routineDayId: any(named: 'routineDayId'),
        ),
      ).thenAnswer((_) async => const Right([exerciseA, extra]));
      when(
        () => repository.getSessionSetLogs(sessionId),
      ).thenAnswer((_) async => const Right(<SetLog>[]));
      final bloc = buildBloc();
      final running = bloc.stream.firstWhere((s) => s.isRunning);
      bloc.add(
        ResumeActiveWorkout(
          session: session,
          exercises: const [exerciseA],
          lastPerformances: const {},
        ),
      );
      expect((await running).exercises.map((e) => e.id), ['e1', 'extra']);
      await bloc.close();
    },
  );

  blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
    'iniciar hoy no continúa silenciosamente una sesión anterior devuelta por el backend',
    build: () {
      when(
        () => repository.startWorkoutForDay(userId, routineDayId, any()),
      ).thenAnswer((_) async => Right(session));
      when(
        () => repository.getExercisesForDay(any()),
      ).thenAnswer((_) async => const Right([exerciseA]));
      when(
        () => repository.getSessionSetLogs(any()),
      ).thenAnswer((_) async => const Right(<SetLog>[]));
      when(
        () => repository.getLastExercisePerformances(any()),
      ).thenAnswer((_) async => const Right(<String, SetLog?>{}));
      when(
        () => repository.getRecentSessionsForDay(
          any(),
          any(),
          any(),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Right(<WorkoutSession>[]));
      when(
        () => repository.getSetLogsForSessions(any()),
      ).thenAnswer((_) async => const Right(<String, List<SetLog>>{}));
      return buildBloc();
    },
    act: (b) => b.add(
      const StartActiveWorkout(
        userId: userId,
        routineDayId: routineDayId,
        routineDayName: 'Pecho',
      ),
    ),
    expect: () => [
      isA<ActiveWorkoutState>().having(
        (s) => s.status,
        'status',
        ActiveWorkoutStatus.starting,
      ),
      isA<ActiveWorkoutState>()
          .having((s) => s.status, 'status', ActiveWorkoutStatus.failure)
          .having((s) => s.errorMessage, 'message', contains('anterior')),
    ],
  );

  test(
    'desmarcar, salir y reanudar conserva valores sin completar la serie ni cambiar la fecha',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const log = SetLog(
        sessionId: sessionId,
        exerciseId: 'e1',
        setIndex: 1,
        actualWeight: 82.5,
        actualReps: 8,
      );
      when(
        () => repository.deleteSetLog(
          sessionId: sessionId,
          exerciseId: 'e1',
          setIndex: 1,
        ),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => repository.getSessionSetLogs(sessionId),
      ).thenAnswer((_) async => const Right(<SetLog>[]));
      ActiveWorkoutBloc create() => ActiveWorkoutBloc(
        repository: repository,
        activeSessionService: activeSessionService,
        notifier: notifier,
        clock: clock,
        draftService: WorkoutDraftService(prefs),
      );
      final first = create()
        ..emit(
          ActiveWorkoutState(
            status: ActiveWorkoutStatus.running,
            session: session,
            setLogs: const [log],
          ),
        );
      final unmarked = first.stream.firstWhere(
        (s) => s.setLogs.isEmpty && s.setDrafts.isNotEmpty,
      );
      first.add(
        const UnsaveActiveSetLog(
          sessionId: sessionId,
          exerciseId: 'e1',
          setIndex: 1,
        ),
      );
      await unmarked;
      await first.close();
      await prefs.reload();
      final resumed = create();
      final running = resumed.stream.firstWhere((s) => s.isRunning);
      resumed.add(
        ResumeActiveWorkout(
          session: session,
          exercises: const [exerciseA],
          lastPerformances: const {},
        ),
      );
      final state = await running;
      expect(state.setLogs, isEmpty);
      expect(state.setDrafts.single.actualWeight, 82.5);
      expect(state.setDrafts.single.actualReps, 8);
      expect(state.session!.sessionDate, DateTime(2026, 5, 4));
      await resumed.close();
    },
  );

  test('dos desmarcados rápidos no restauran una serie eliminada', () async {
    final drafts = _MockWorkoutDraftService();
    when(() => drafts.save(any(), any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    when(
      () => repository.deleteSetLog(
        sessionId: any(named: 'sessionId'),
        exerciseId: any(named: 'exerciseId'),
        setIndex: any(named: 'setIndex'),
      ),
    ).thenAnswer((_) async => const Right(null));
    const firstLog = SetLog(
      sessionId: sessionId,
      exerciseId: 'e1',
      setIndex: 1,
      actualWeight: 82.5,
      actualReps: 8,
    );
    final bloc =
        ActiveWorkoutBloc(
          repository: repository,
          activeSessionService: activeSessionService,
          notifier: notifier,
          draftService: drafts,
        )..emit(
          ActiveWorkoutState(
            status: ActiveWorkoutStatus.running,
            session: session,
            setLogs: [firstLog, firstLog.copyWith(setIndex: 2)],
          ),
        );
    bloc.add(
      const UnsaveActiveSetLog(
        sessionId: sessionId,
        exerciseId: 'e1',
        setIndex: 1,
      ),
    );
    bloc.add(
      const UnsaveActiveSetLog(
        sessionId: sessionId,
        exerciseId: 'e1',
        setIndex: 2,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await bloc.close();
    expect(bloc.state.setLogs, isEmpty);
    expect(bloc.state.setDrafts, hasLength(2));
  });

  test(
    'fallo al conservar borrador restaura una lista nueva para resincronizar la tarjeta',
    () async {
      final drafts = _MockWorkoutDraftService();
      when(
        () => drafts.save(any(), any()),
      ).thenThrow(StateError('storage full'));
      const log = SetLog(
        sessionId: sessionId,
        exerciseId: 'e1',
        setIndex: 1,
        actualWeight: 82.5,
        actualReps: 8,
      );
      final original = <SetLog>[log];
      final bloc =
          ActiveWorkoutBloc(
            repository: repository,
            activeSessionService: activeSessionService,
            notifier: notifier,
            draftService: drafts,
          )..emit(
            ActiveWorkoutState(
              status: ActiveWorkoutStatus.running,
              session: session,
              setLogs: original,
            ),
          );
      final failed = bloc.stream.firstWhere((s) => s.actionError != null);
      bloc.add(
        const UnsaveActiveSetLog(
          sessionId: sessionId,
          exerciseId: 'e1',
          setIndex: 1,
        ),
      );
      final restored = await failed;
      expect(restored.setLogs, [log]);
      expect(identical(restored.setLogs, original), isFalse);
      verifyNever(
        () => repository.deleteSetLog(
          sessionId: any(named: 'sessionId'),
          exerciseId: any(named: 'exerciseId'),
          setIndex: any(named: 'setIndex'),
        ),
      );
      await bloc.close();
    },
  );

  test(
    'finalizar el entrenamiento limpia los borradores persistidos',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final drafts = WorkoutDraftService(prefs);
      const log = SetLog(
        sessionId: sessionId,
        exerciseId: 'e1',
        setIndex: 1,
        actualWeight: 82.5,
        actualReps: 8,
      );
      await drafts.save(userId, log);
      when(
        () =>
            repository.finishWorkoutSession(sessionId, coachingAnalysis: null),
      ).thenAnswer((_) async => const Right(null));
      final bloc =
          ActiveWorkoutBloc(
            repository: repository,
            activeSessionService: activeSessionService,
            notifier: notifier,
            draftService: drafts,
          )..emit(
            ActiveWorkoutState(
              status: ActiveWorkoutStatus.running,
              session: session,
              setDrafts: const [log],
            ),
          );
      final finished = bloc.stream.firstWhere(
        (s) => s.status == ActiveWorkoutStatus.finished,
      );
      bloc.add(const FinishActiveWorkout(sessionId: sessionId));
      expect((await finished).setDrafts, isEmpty);
      expect(drafts.load(userId, sessionId), isEmpty);
      await bloc.close();
    },
  );

  group('notificación de entreno activo', () {
    setUp(() {
      when(
        () => repository.getSessionSetLogs(any()),
      ).thenAnswer((_) async => const Right(<SetLog>[]));
    });

    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'consultar una sesión cerrada no la arranca',
      build: buildBloc,
      act: (b) => b.add(
        ResumeActiveWorkout(
          session: session.copyWith(completedAt: DateTime(2026, 5, 4, 20)),
          exercises: const [exerciseA],
          lastPerformances: const {},
        ),
      ),
      wait: const Duration(milliseconds: 50),
      verify: (_) => verifyNever(
        () => notifier.onStarted(
          dayName: any(named: 'dayName'),
          sessionStartedAt: any(named: 'sessionStartedAt'),
          totalSets: any(named: 'totalSets'),
        ),
      ),
    );

    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'salir con la sesión abierta no quita la notificación',
      build: () => buildBloc()
        ..emit(
          ActiveWorkoutState(
            status: ActiveWorkoutStatus.running,
            session: session,
            exercises: const [exerciseA],
          ),
        ),
      act: (b) => b.add(const ResetActiveWorkout()),
      wait: const Duration(milliseconds: 50),
      verify: (_) => verifyNever(() => notifier.onEnded()),
    );

    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'reset sin sesión abierta sí la quita',
      build: buildBloc,
      act: (b) => b.add(const ResetActiveWorkout()),
      wait: const Duration(milliseconds: 50),
      verify: (_) => verify(() => notifier.onEnded()).called(1),
    );
  });

  group('StartActiveWorkout', () {
    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'éxito → status running con session/exercises/setLogs',
      build: () {
        when(
          () => repository.startWorkoutForDay(any(), any(), any()),
        ).thenAnswer(
          (_) async =>
              Right(session.copyWith(sessionDate: DateTime(2026, 5, 6))),
        );
        when(
          () => repository.getExercisesForDay(any()),
        ).thenAnswer((_) async => const Right([exerciseA]));
        when(
          () => repository.getRecentSessionsForDay(
            any(),
            any(),
            any(),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(<WorkoutSession>[]));
        when(
          () => repository.getSessionSetLogs(any()),
        ).thenAnswer((_) async => const Right(<SetLog>[]));
        when(
          () => repository.getSetLogsForSessions(any()),
        ).thenAnswer((_) async => const Right(<String, List<SetLog>>{}));
        when(
          () => repository.getLastExercisePerformances(any()),
        ).thenAnswer((_) async => const Right(<String, SetLog?>{}));
        return buildBloc();
      },
      act: (b) => b.add(
        const StartActiveWorkout(
          userId: userId,
          routineDayId: routineDayId,
          routineDayName: 'Push Day',
        ),
      ),
      wait: const Duration(milliseconds: 100),
      verify: (b) {
        expect(b.state.status, ActiveWorkoutStatus.running);
        expect(b.state.session?.id, sessionId);
        expect(b.state.exercises, hasLength(1));
      },
    );

    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'crea la sesión con la fecha de hoy aunque se abra un día anterior',
      build: () {
        when(
          () => repository.startWorkoutForDay(any(), any(), any()),
        ).thenAnswer(
          (_) async =>
              Right(session.copyWith(sessionDate: DateTime(2026, 5, 6))),
        );
        when(
          () => repository.getExercisesForDay(any()),
        ).thenAnswer((_) async => const Right(<Exercise>[]));
        when(
          () => repository.getRecentSessionsForDay(
            any(),
            any(),
            any(),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(<WorkoutSession>[]));
        when(
          () => repository.getSessionSetLogs(any()),
        ).thenAnswer((_) async => const Right(<SetLog>[]));
        when(
          () => repository.getSetLogsForSessions(any()),
        ).thenAnswer((_) async => const Right(<String, List<SetLog>>{}));
        return buildBloc();
      },
      act: (b) => b.add(
        const StartActiveWorkout(
          userId: userId,
          routineDayId: routineDayId,
          routineDayName: 'Push Day',
        ),
      ),
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        verify(
          () => repository.startWorkoutForDay(
            userId,
            routineDayId,
            DateTime(2026, 5, 6),
          ),
        ).called(1);
      },
    );

    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'backend devuelve sesión de otro día → failure con mensaje',
      build: () {
        final otherSession = WorkoutSession(
          id: 's-other',
          userId: userId,
          routineDayId: 'd-other',
          sessionDate: sessionDate,
        );
        when(
          () => repository.startWorkoutForDay(any(), any(), any()),
        ).thenAnswer((_) async => Right(otherSession));
        return buildBloc();
      },
      act: (b) => b.add(
        const StartActiveWorkout(
          userId: userId,
          routineDayId: routineDayId,
          routineDayName: 'Push Day',
        ),
      ),
      wait: const Duration(milliseconds: 100),
      verify: (b) {
        expect(b.state.status, ActiveWorkoutStatus.failure);
        expect(b.state.errorMessage, contains('sesión activa en otro día'));
      },
    );
  });

  group('SaveActiveSetLog', () {
    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'agrega un nuevo log a la lista',
      build: () {
        when(
          () => repository.saveSetLog(any()),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc()..emit(
          ActiveWorkoutState(
            status: ActiveWorkoutStatus.running,
            session: session,
            exercises: const [exerciseA],
          ),
        );
      },
      act: (b) => b.add(
        const SaveActiveSetLog(
          SetLog(
            sessionId: sessionId,
            exerciseId: 'e1',
            actualWeight: 80,
            actualReps: 8,
            setIndex: 0,
          ),
        ),
      ),
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        expect(b.state.setLogs, hasLength(1));
        expect(b.state.setLogs.first.actualReps, 8);
      },
    );

    const pendingLog = SetLog(
      sessionId: sessionId,
      exerciseId: 'e1',
      actualWeight: 80,
      actualReps: 8,
      setIndex: 1,
    );

    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'si el guardado falla revierte el log y expone actionError',
      build: () {
        when(
          () => repository.saveSetLog(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('sin red')));
        return buildBloc()..emit(
          ActiveWorkoutState(
            status: ActiveWorkoutStatus.running,
            session: session,
            exercises: const [exerciseA],
          ),
        );
      },
      act: (b) => b.add(const SaveActiveSetLog(pendingLog)),
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        expect(b.state.setLogs, isEmpty);
        expect(b.state.actionError, contains('sin red'));
        // La sesión sigue viva: no se cae a failure.
        expect(b.state.status, ActiveWorkoutStatus.running);
      },
    );
  });

  group('UnsaveActiveSetLog', () {
    const savedLog = SetLog(
      sessionId: sessionId,
      exerciseId: 'e1',
      actualWeight: 80,
      actualReps: 8,
      setIndex: 1,
    );

    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'éxito → saca el log de la lista',
      build: () {
        when(
          () => repository.deleteSetLog(
            sessionId: any(named: 'sessionId'),
            exerciseId: any(named: 'exerciseId'),
            setIndex: any(named: 'setIndex'),
          ),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc()..emit(
          ActiveWorkoutState(
            status: ActiveWorkoutStatus.running,
            session: session,
            exercises: const [exerciseA],
            setLogs: const [savedLog],
          ),
        );
      },
      act: (b) => b.add(
        const UnsaveActiveSetLog(
          sessionId: sessionId,
          exerciseId: 'e1',
          setIndex: 1,
        ),
      ),
      wait: const Duration(milliseconds: 50),
      verify: (b) => expect(b.state.setLogs, isEmpty),
    );

    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'si falla restaura el log y no tumba la sesión',
      build: () {
        when(
          () => repository.deleteSetLog(
            sessionId: any(named: 'sessionId'),
            exerciseId: any(named: 'exerciseId'),
            setIndex: any(named: 'setIndex'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('sin red')));
        return buildBloc()..emit(
          ActiveWorkoutState(
            status: ActiveWorkoutStatus.running,
            session: session,
            exercises: const [exerciseA],
            setLogs: const [savedLog],
          ),
        );
      },
      act: (b) => b.add(
        const UnsaveActiveSetLog(
          sessionId: sessionId,
          exerciseId: 'e1',
          setIndex: 1,
        ),
      ),
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        expect(b.state.setLogs, hasLength(1));
        expect(b.state.status, ActiveWorkoutStatus.running);
        expect(b.state.actionError, contains('sin red'));
      },
    );
  });

  group('FinishActiveWorkout', () {
    test(
      'finalizar usa coaching del servidor y no una copia calculada antes de guardar',
      () async {
        when(
          () => repository.finishWorkoutSession(
            sessionId,
            coachingAnalysis: any(named: 'coachingAnalysis'),
          ),
        ).thenAnswer((_) async => const Right(null));
        final bloc = buildBloc()
          ..emit(
            ActiveWorkoutState(
              status: ActiveWorkoutStatus.running,
              session: session,
              exercises: const [exerciseA],
            ),
          );
        final done = bloc.stream.firstWhere(
          (s) => s.status == ActiveWorkoutStatus.finished,
        );
        bloc.add(
          const FinishActiveWorkout(
            sessionId: sessionId,
            coachingAnalysis: <CoachingAnalysis>[],
          ),
        );
        await done;
        verify(
          () => repository.finishWorkoutSession(
            sessionId,
            coachingAnalysis: null,
          ),
        ).called(1);
        await bloc.close();
      },
    );

    test('ignora finalizar una sesión distinta a la abierta', () async {
      final bloc = buildBloc()
        ..emit(
          ActiveWorkoutState(
            status: ActiveWorkoutStatus.running,
            session: session,
          ),
        );
      bloc.add(const FinishActiveWorkout(sessionId: 'otra-sesion'));
      await bloc.close();
      expect(bloc.state.isRunning, true);
      verifyNever(
        () => repository.finishWorkoutSession(
          any(),
          coachingAnalysis: any(named: 'coachingAnalysis'),
        ),
      );
    });
    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'éxito → status finished y limpia el activeSessionService',
      build: () {
        when(
          () => repository.finishWorkoutSession(
            any(),
            coachingAnalysis: any(named: 'coachingAnalysis'),
          ),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc()..emit(
          ActiveWorkoutState(
            status: ActiveWorkoutStatus.running,
            session: session,
            exercises: const [exerciseA],
          ),
        );
      },
      act: (b) => b.add(
        const FinishActiveWorkout(
          sessionId: sessionId,
          coachingAnalysis: <CoachingAnalysis>[],
        ),
      ),
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        expect(b.state.status, ActiveWorkoutStatus.finished);
        verify(() => activeSessionService.clear()).called(1);
      },
    );

    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'éxito → expone el coaching que guardó el servidor',
      build: () {
        when(
          () => repository.finishWorkoutSession(
            any(),
            coachingAnalysis: any(named: 'coachingAnalysis'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(() => repository.getSessionCoaching(sessionId)).thenAnswer(
          (_) async => const Right([
            CoachingAnalysis(
              exerciseName: 'Press',
              recommendation: 'INCREASE_WEIGHT',
            ),
          ]),
        );
        return buildBloc()..emit(
          ActiveWorkoutState(
            status: ActiveWorkoutStatus.running,
            session: session,
            exercises: const [exerciseA],
          ),
        );
      },
      act: (b) => b.add(const FinishActiveWorkout(sessionId: sessionId)),
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        expect(b.state.status, ActiveWorkoutStatus.finished);
        expect(b.state.finalCoaching.single.exerciseName, 'Press');
      },
    );

    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'si falla vuelve al entreno con aviso, sin pantalla de error',
      build: () {
        when(
          () => repository.finishWorkoutSession(
            any(),
            coachingAnalysis: any(named: 'coachingAnalysis'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('Servidor caído')));
        return buildBloc()..emit(
          ActiveWorkoutState(
            status: ActiveWorkoutStatus.running,
            session: session,
            exercises: const [exerciseA],
          ),
        );
      },
      act: (b) => b.add(const FinishActiveWorkout(sessionId: sessionId)),
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        expect(b.state.status, ActiveWorkoutStatus.running);
        expect(b.state.session, session);
        expect(b.state.actionError, 'No se pudo finalizar: Servidor caído');
        verifyNever(() => activeSessionService.clear());
      },
    );
  });

  group('DiscardActiveWorkout', () {
    const log = SetLog(
      sessionId: sessionId,
      exerciseId: 'e1',
      setIndex: 1,
      actualWeight: 80,
      actualReps: 10,
    );
    ActiveWorkoutBloc runningBloc({WorkoutDraftService? drafts}) =>
        ActiveWorkoutBloc(
          repository: repository,
          activeSessionService: activeSessionService,
          notifier: notifier,
          draftService: drafts,
          clock: clock,
        )..emit(
          ActiveWorkoutState(
            status: ActiveWorkoutStatus.running,
            session: session,
            exercises: const [exerciseA],
            setLogs: const [log],
          ),
        );

    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'éxito → discarded, limpia sesión activa, borradores y notificación',
      setUp: () => when(
        () => repository.discardWorkoutSession(sessionId),
      ).thenAnswer((_) async => const Right(null)),
      build: () {
        final drafts = _MockWorkoutDraftService();
        when(() => drafts.clear(any(), any())).thenAnswer((_) async {});
        return runningBloc(drafts: drafts);
      },
      act: (b) => b.add(const DiscardActiveWorkout(sessionId: sessionId)),
      expect: () => [
        isA<ActiveWorkoutState>().having(
          (s) => s.status,
          'status',
          ActiveWorkoutStatus.discarding,
        ),
        isA<ActiveWorkoutState>()
            .having((s) => s.status, 'status', ActiveWorkoutStatus.discarded)
            .having((s) => s.setLogs, 'setLogs', isEmpty),
      ],
      verify: (_) {
        verify(() => activeSessionService.clear()).called(1);
        verify(() => notifier.onEnded()).called(1);
        verifyNever(() => repository.finishWorkoutSession(any()));
      },
    );

    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'si falla vuelve al entreno con aviso y conserva las series',
      setUp: () => when(
        () => repository.discardWorkoutSession(sessionId),
      ).thenAnswer((_) async => const Left(NetworkFailure())),
      build: runningBloc,
      act: (b) => b.add(const DiscardActiveWorkout(sessionId: sessionId)),
      expect: () => [
        isA<ActiveWorkoutState>().having(
          (s) => s.status,
          'status',
          ActiveWorkoutStatus.discarding,
        ),
        isA<ActiveWorkoutState>()
            .having((s) => s.status, 'status', ActiveWorkoutStatus.running)
            .having((s) => s.setLogs, 'setLogs', const [log])
            .having(
              (s) => s.actionError,
              'actionError',
              startsWith('No se pudo descartar'),
            ),
      ],
      verify: (_) {
        verifyNever(() => activeSessionService.clear());
        verifyNever(() => notifier.onEnded());
      },
    );

    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'ignora descartar una sesión distinta a la abierta',
      build: runningBloc,
      act: (b) => b.add(const DiscardActiveWorkout(sessionId: 'otra')),
      expect: () => const <ActiveWorkoutState>[],
      verify: (_) => verifyNever(() => repository.discardWorkoutSession(any())),
    );
  });
}
