import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/core/services/active_session_service.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/mocks.dart';

class _MockActiveSessionService extends Mock implements ActiveSessionService {}

void main() {
  late MockWorkoutRepository repository;
  late _MockActiveSessionService activeSessionService;
  late StreamController<ActiveSessionContext?> changes;

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repository = MockWorkoutRepository();
    activeSessionService = _MockActiveSessionService();
    changes = StreamController<ActiveSessionContext?>.broadcast();
    when(() => activeSessionService.changes).thenAnswer((_) => changes.stream);
    when(() => activeSessionService.clear()).thenAnswer((_) async {});
    when(() => activeSessionService.getContext()).thenReturn(null);
    when(
      () => activeSessionService.save(
        sessionId: any(named: 'sessionId'),
        routineDayId: any(named: 'routineDayId'),
        userId: any(named: 'userId'),
        sessionDate: any(named: 'sessionDate'),
        routineDayName: any(named: 'routineDayName'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() => changes.close());

  ActiveSessionWatcherBloc buildBloc() => ActiveSessionWatcherBloc(
    repository: repository,
    activeSessionService: activeSessionService,
  );

  blocTest<ActiveSessionWatcherBloc, ActiveSessionWatcherState>(
    'sin sesión activa → status none',
    build: () {
      when(
        () => repository.getActiveSessionForUser(any()),
      ).thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    act: (b) => b.add(const CheckActiveSession('u1')),
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.status, ActiveSessionWatcherStatus.none);
      expect(b.state.session, isNull);
      verify(() => activeSessionService.clear()).called(1);
    },
  );

  blocTest<ActiveSessionWatcherBloc, ActiveSessionWatcherState>(
    'sesión en curso → status detected con session info',
    build: () {
      final session = WorkoutSession(
        id: 's1',
        userId: 'u1',
        routineDayId: 'd1',
        sessionDate: DateTime(2026, 5, 4),
      );
      when(
        () => repository.getActiveSessionForUser(any()),
      ).thenAnswer((_) async => Right(session));
      when(
        () => repository.getRoutineDayNameById(any()),
      ).thenAnswer((_) async => const Right('Push Day'));
      return buildBloc();
    },
    act: (b) => b.add(const CheckActiveSession('u1')),
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.status, ActiveSessionWatcherStatus.detected);
      expect(b.state.session?.routineDayName, 'Push Day');
      verify(
        () => activeSessionService.save(
          sessionId: 's1',
          routineDayId: 'd1',
          userId: 'u1',
          sessionDate: any(named: 'sessionDate'),
          routineDayName: 'Push Day',
        ),
      ).called(1);
    },
  );

  blocTest<ActiveSessionWatcherBloc, ActiveSessionWatcherState>(
    'ClearActiveSession resetea estado y llama service.clear',
    build: () => buildBloc(),
    act: (b) => b.add(const ClearActiveSession()),
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.status, ActiveSessionWatcherStatus.none);
      verify(() => activeSessionService.clear()).called(1);
    },
  );

  final ctx = ActiveSessionContext(
    sessionId: 's1',
    routineDayId: 'd1',
    userId: 'u1',
    sessionDate: DateTime(2026, 5, 4),
    routineDayName: 'Push Day',
  );

  blocTest<ActiveSessionWatcherBloc, ActiveSessionWatcherState>(
    'empezar un entreno (save) muestra el banner sin reiniciar la app',
    build: buildBloc,
    act: (b) {
      when(() => activeSessionService.getContext()).thenReturn(ctx);
      changes.add(ctx);
    },
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.status, ActiveSessionWatcherStatus.detected);
      expect(b.state.session?.sessionId, 's1');
      verifyNever(() => repository.getActiveSessionForUser(any()));
    },
  );

  blocTest<ActiveSessionWatcherBloc, ActiveSessionWatcherState>(
    'finalizar (clear) oculta el banner',
    build: buildBloc,
    seed: () => ActiveSessionWatcherState(
      status: ActiveSessionWatcherStatus.detected,
      session: ActiveSessionInfo(
        sessionId: 's1',
        userId: 'u1',
        routineDayId: 'd1',
        routineDayName: 'Push Day',
        sessionDate: DateTime(2026, 5, 4),
      ),
    ),
    act: (_) => changes.add(null),
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.status, ActiveSessionWatcherStatus.none);
      expect(b.state.session, isNull);
    },
  );

  blocTest<ActiveSessionWatcherBloc, ActiveSessionWatcherState>(
    'si el backend falla conserva la sesión local en vez de borrarla',
    build: () {
      when(() => activeSessionService.getContext()).thenReturn(ctx);
      when(
        () => repository.getActiveSessionForUser(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      return buildBloc();
    },
    act: (b) => b.add(const CheckActiveSession('u1')),
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.status, ActiveSessionWatcherStatus.detected);
      expect(b.state.session?.routineDayName, 'Push Day');
      verifyNever(() => activeSessionService.clear());
    },
  );
}
