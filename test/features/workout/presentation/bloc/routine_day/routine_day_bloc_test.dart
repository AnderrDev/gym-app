import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_day/routine_day_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_day/routine_day_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_day/routine_day_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository repository;

  const userId = 'u1';
  const routineDayId = 'd1';
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

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repository = MockWorkoutRepository();
  });

  RoutineDayBloc buildBloc() => RoutineDayBloc(repository: repository);

  void whenLoadCommonAnswers({
    WorkoutSession? existing,
    WorkoutSession? activeOther,
    String? activeOtherDayName,
    List<Exercise> exercises = const [exerciseA],
    List<WorkoutSession> weekSessions = const [],
  }) {
    when(
      () => repository.getWeekSessions(any(), any(), any()),
    ).thenAnswer((_) async => Right(weekSessions));
    when(
      () => repository.getExercisesForDay(any()),
    ).thenAnswer((_) async => Right(exercises));
    when(
      () => repository.getExistingSession(any(), any(), any()),
    ).thenAnswer((_) async => Right(existing));
    when(
      () => repository.getRecentSessionsForDay(
        any(),
        any(),
        any(),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => const Right(<WorkoutSession>[]));
    when(
      () => repository.getActiveSessionForUser(any()),
    ).thenAnswer((_) async => Right(activeOther));
    when(
      () => repository.getSetLogsForSessions(any()),
    ).thenAnswer((_) async => const Right(<String, List<SetLog>>{}));
    when(
      () => repository.getLastExercisePerformances(any()),
    ).thenAnswer((_) async => const Right(<String, SetLog?>{}));
    when(
      () => repository.getRoutineDayNameById(any()),
    ).thenAnswer((_) async => Right(activeOtherDayName));
  }

  group('LoadRoutineDay', () {
    blocTest<RoutineDayBloc, RoutineDayState>(
      'sin sesión existente → ready con flag de otra sesión activa',
      build: () {
        whenLoadCommonAnswers(
          activeOther: WorkoutSession(
            id: 's-other',
            userId: userId,
            routineDayId: 'd-other',
            sessionDate: sessionDate,
          ),
          activeOtherDayName: 'Pull Day',
        );
        return buildBloc();
      },
      act: (b) => b.add(
        LoadRoutineDay(
          userId: userId,
          routineDayId: routineDayId,
          sessionDate: sessionDate,
        ),
      ),
      wait: const Duration(milliseconds: 100),
      verify: (b) {
        expect(b.state.status, RoutineDayStatus.ready);
        expect(b.state.exercises, hasLength(1));
        expect(b.state.existingSession, isNull);
        expect(b.state.hasAnotherActiveSession, isTrue);
        expect(b.state.anotherActiveSessionDayName, 'Pull Day');
      },
    );

    blocTest<RoutineDayBloc, RoutineDayState>(
      'con sesión existente del mismo día → ready exponiendo existingSession',
      build: () {
        whenLoadCommonAnswers(
          existing: WorkoutSession(
            id: 's1',
            userId: userId,
            routineDayId: routineDayId,
            sessionDate: sessionDate,
          ),
        );
        return buildBloc();
      },
      act: (b) => b.add(
        LoadRoutineDay(
          userId: userId,
          routineDayId: routineDayId,
          sessionDate: sessionDate,
        ),
      ),
      wait: const Duration(milliseconds: 100),
      verify: (b) {
        expect(b.state.status, RoutineDayStatus.ready);
        expect(b.state.existingSession, isNotNull);
        expect(b.state.hasAnotherActiveSession, isFalse);
      },
    );
  });

  blocTest<RoutineDayBloc, RoutineDayState>(
    'ResetRoutineDay vuelve al estado inicial',
    build: () {
      whenLoadCommonAnswers();
      return buildBloc();
    },
    act: (b) async {
      b.add(
        LoadRoutineDay(
          userId: userId,
          routineDayId: routineDayId,
          sessionDate: sessionDate,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      b.add(const ResetRoutineDay());
    },
    skip: 2,
    expect: () => [const RoutineDayState()],
  );

  blocTest<RoutineDayBloc, RoutineDayState>(
    'sin sesión en la fecha exacta usa la de esa rutina en la misma semana',
    build: () {
      // El día se abre con fecha de lunes, pero la sesión se hizo el
      // miércoles (se inició desde el día anterior → fecha de hoy).
      final midWeek = WorkoutSession(
        id: 's-week',
        userId: userId,
        routineDayId: routineDayId,
        sessionDate: DateTime(2026, 5, 6),
        completedAt: DateTime(2026, 5, 6, 19),
      );
      whenLoadCommonAnswers(weekSessions: [midWeek]);
      return buildBloc();
    },
    act: (b) => b.add(
      LoadRoutineDay(
        userId: userId,
        routineDayId: routineDayId,
        sessionDate: DateTime(2026, 5, 4),
      ),
    ),
    wait: const Duration(milliseconds: 100),
    verify: (b) {
      expect(b.state.status, RoutineDayStatus.ready);
      expect(b.state.existingSession?.id, 's-week');
    },
  );

  blocTest<RoutineDayBloc, RoutineDayState>(
    'ignora sesiones de la semana de otro día de rutina',
    build: () {
      final otherDay = WorkoutSession(
        id: 's-other-day',
        userId: userId,
        routineDayId: 'd2',
        sessionDate: DateTime(2026, 5, 6),
      );
      whenLoadCommonAnswers(weekSessions: [otherDay]);
      return buildBloc();
    },
    act: (b) => b.add(
      LoadRoutineDay(
        userId: userId,
        routineDayId: routineDayId,
        sessionDate: DateTime(2026, 5, 4),
      ),
    ),
    wait: const Duration(milliseconds: 100),
    verify: (b) {
      expect(b.state.status, RoutineDayStatus.ready);
      expect(b.state.existingSession, isNull);
    },
  );
}
