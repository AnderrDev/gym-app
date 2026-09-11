import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/notifications/active_workout_notifier.dart';
import 'package:gym_flutter/core/services/active_session_service.dart';
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

  ActiveWorkoutBloc buildBloc() => ActiveWorkoutBloc(
    repository: repository,
    activeSessionService: activeSessionService,
    notifier: notifier,
  );

  group('StartActiveWorkout', () {
    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'éxito → status running con session/exercises/setLogs',
      build: () {
        when(
          () => repository.startWorkoutForDay(any(), any(), any()),
        ).thenAnswer((_) async => Right(session));
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
        StartActiveWorkout(
          userId: userId,
          routineDayId: routineDayId,
          sessionDate: sessionDate,
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
        StartActiveWorkout(
          userId: userId,
          routineDayId: routineDayId,
          sessionDate: sessionDate,
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
  });

  group('FinishActiveWorkout', () {
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
  });
}
