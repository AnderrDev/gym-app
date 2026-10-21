import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/notifications/active_workout_notifier.dart';
import 'package:gym_flutter/core/services/active_session_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockNotificationService notifications;
  late MockLiveActivitiesBridge liveActivities;
  late MockActiveSessionService sessionService;
  late ActiveWorkoutNotifier notifier;

  setUp(() {
    notifications = MockNotificationService();
    liveActivities = MockLiveActivitiesBridge();
    sessionService = MockActiveSessionService();
    when(() => liveActivities.isAvailable).thenReturn(true);
    when(() => liveActivities.ready).thenAnswer((_) async {});
    when(
      () => liveActivities.start(
        dayName: any(named: 'dayName'),
        sessionStartedAt: any(named: 'sessionStartedAt'),
        totalSets: any(named: 'totalSets'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => liveActivities.update(
        dayName: any(named: 'dayName'),
        sessionStartedAt: any(named: 'sessionStartedAt'),
        completedSets: any(named: 'completedSets'),
        totalSets: any(named: 'totalSets'),
        restEndsAt: any(named: 'restEndsAt'),
      ),
    ).thenAnswer((_) async {});
    notifier = ActiveWorkoutNotifier(
      notifications: notifications,
      liveActivities: liveActivities,
      sessionService: sessionService,
    );
  });

  test('con Live Activity el descanso solo actualiza el countdown; el fin '
      'vuelve a workout-view sin notificación propia', () async {
    await notifier.onStarted(
      dayName: 'Pierna',
      sessionStartedAt: DateTime(2026, 10, 21, 10),
      totalSets: 12,
    );
    await notifier.onRestStarted(duration: const Duration(seconds: 90));
    verify(
      () => liveActivities.update(
        dayName: 'Pierna',
        sessionStartedAt: DateTime(2026, 10, 21, 10),
        completedSets: 0,
        totalSets: 12,
        restEndsAt: any(named: 'restEndsAt', that: isNotNull),
      ),
    ).called(1);

    await notifier.onRestEnded();
    verify(
      () => liveActivities.update(
        dayName: 'Pierna',
        sessionStartedAt: DateTime(2026, 10, 21, 10),
        completedSets: 0,
        totalSets: 12,
        restEndsAt: null,
      ),
    ).called(1);
    // El sonido de fin de descanso no sale de aquí (lo da la notificación
    // programada en iOS / showRestEnded en Android).
    verifyNever(() => notifications.showRestEnded());
  });

  test('onRestEnded sin descanso en curso no hace nada', () async {
    await notifier.onStarted(
      dayName: 'Pierna',
      sessionStartedAt: DateTime(2026, 10, 21, 10),
      totalSets: 12,
    );
    await notifier.onRestEnded();
    verifyNever(
      () => liveActivities.update(
        dayName: any(named: 'dayName'),
        sessionStartedAt: any(named: 'sessionStartedAt'),
        completedSets: any(named: 'completedSets'),
        totalSets: any(named: 'totalSets'),
        restEndsAt: any(named: 'restEndsAt'),
      ),
    );
  });

  test('bootstrapFromPersistedSession arranca con totalSets 0 (la vista '
      'oculta el contador) y usa el nombre y la fecha persistidos', () async {
    when(() => sessionService.getContext()).thenReturn(
      ActiveSessionContext(
        sessionId: 's1',
        routineDayId: 'd1',
        userId: 'u1',
        sessionDate: DateTime(2026, 10, 21, 9),
        routineDayName: 'Espalda',
      ),
    );
    await notifier.bootstrapFromPersistedSession();
    verify(
      () => liveActivities.start(
        dayName: 'Espalda',
        sessionStartedAt: DateTime(2026, 10, 21, 9),
        totalSets: 0,
      ),
    ).called(1);
  });

  test(
    'bootstrapFromPersistedSession sin sesión persistida no hace nada',
    () async {
      when(() => sessionService.getContext()).thenReturn(null);
      await notifier.bootstrapFromPersistedSession();
      verifyNever(
        () => liveActivities.start(
          dayName: any(named: 'dayName'),
          sessionStartedAt: any(named: 'sessionStartedAt'),
          totalSets: any(named: 'totalSets'),
        ),
      );
    },
  );

  test('bootstrap diferido no pisa una sesión ya iniciada', () async {
    await notifier.onStarted(
      dayName: 'Pierna',
      sessionStartedAt: DateTime(2026, 10, 21, 10),
      totalSets: 12,
    );
    await notifier.bootstrapFromPersistedSession();
    verifyNever(() => sessionService.getContext());
  });

  test(
    '_post espera a que el bridge esté listo antes de elegir canal',
    () async {
      await notifier.onStarted(
        dayName: 'Pierna',
        sessionStartedAt: DateTime(2026, 10, 21, 10),
        totalSets: 12,
      );
      verifyInOrder([
        () => liveActivities.ready,
        () => liveActivities.isAvailable,
      ]);
    },
  );
}
