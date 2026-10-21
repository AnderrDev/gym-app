import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/notifications/rest_alarm_scheduler.dart';
import 'package:gym_flutter/core/utils/clock.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/utils/rest_timer_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

/// Registra las llamadas que hace el controller al aviso programado.
class FakeRestAlarmScheduler implements RestAlarmScheduler {
  final List<String> calls = [];

  @override
  Future<void> schedule(DateTime endsAt) async =>
      calls.add('schedule ${endsAt.toIso8601String()}');

  @override
  Future<void> switchToNotification(DateTime endsAt) async =>
      calls.add('switch ${endsAt.toIso8601String()}');

  @override
  Future<void> cancel() async => calls.add('cancel');

  @override
  Future<void> onRestFinished() async => calls.add('finished');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(Duration.zero));

  late MockActiveWorkoutNotifier notifier;
  late MockNotificationService notifications;
  late FakeClock clock;
  late FakeRestAlarmScheduler restAlarm;
  late bool foreground;
  late int naturalEnds;
  late RestTimerController controller;

  setUp(() {
    notifier = MockActiveWorkoutNotifier();
    notifications = MockNotificationService();
    clock = FakeClock(DateTime(2026, 10, 18, 10));
    restAlarm = FakeRestAlarmScheduler();
    foreground = true;
    naturalEnds = 0;
    when(
      () => notifier.onRestStarted(duration: any(named: 'duration')),
    ).thenAnswer((_) async {});
    when(() => notifier.onRestEnded()).thenAnswer((_) async {});
    when(() => notifications.scheduleRestEnded(any())).thenAnswer((_) async {});
    when(() => notifications.cancelRestEnded()).thenAnswer((_) async {});
    when(() => notifications.showRestEnded()).thenAnswer((_) async {});
    controller = RestTimerController(
      notifier: notifier,
      notifications: notifications,
      restAlarm: restAlarm,
      onNaturalEnd: () => naturalEnds++,
      clock: clock,
      isForeground: () => foreground,
    );
  });

  tearDown(() => controller.dispose());

  String at(int secondsFromStart) => DateTime(
    2026,
    10,
    18,
    10,
  ).add(Duration(seconds: secondsFromStart)).toIso8601String();

  test('el restante sale del reloj, no del número de ticks', () {
    controller.start(120);
    // La app estuvo suspendida 50s sin ticks: al volver, un solo tick.
    clock.set(clock.now().add(const Duration(seconds: 50)));
    controller.tick();
    expect(controller.snapshot.value.secondsRemaining, 70);
    expect(controller.snapshot.value.totalRestSeconds, 120);
  });

  test('si el descanso venció mientras estaba suspendida, termina', () {
    controller.start(60);
    clock.set(clock.now().add(const Duration(minutes: 5)));
    controller.tick();
    expect(controller.snapshot.value.isResting, isFalse);
    expect(naturalEnds, 1);
    verify(() => notifier.onRestEnded()).called(1);
  });

  test('adjust desplaza la hora de fin', () {
    controller.start(60);
    clock.set(clock.now().add(const Duration(seconds: 20)));
    controller.adjust(15);
    expect(controller.snapshot.value.secondsRemaining, 55);
    clock.set(clock.now().add(const Duration(seconds: 50)));
    controller.tick();
    expect(controller.snapshot.value.secondsRemaining, 5);
  });

  test('start con 0 segundos no arranca descanso', () {
    controller.start(0);
    expect(controller.snapshot.value.isResting, isFalse);
    verifyNever(() => notifier.onRestStarted(duration: any(named: 'duration')));
  });

  group('iOS: aviso programado siempre (con o sin Live Activity)', () {
    late RestTimerController ios;

    setUp(() {
      ios = RestTimerController(
        notifier: notifier,
        notifications: notifications,
        restAlarm: restAlarm,
        onNaturalEnd: () => naturalEnds++,
        clock: clock,
        scheduledAlertOverride: true,
        isForeground: () => foreground,
      );
    });

    tearDown(() => ios.dispose());

    test('start programa el aviso con la hora de fin y actualiza la LA', () {
      ios.start(90);
      expect(restAlarm.calls, ['schedule ${at(90)}']);
      // El controller ya no habla con la notificación directamente.
      verifyNever(() => notifications.scheduleRestEnded(any()));
      verify(
        () => notifier.onRestStarted(duration: const Duration(seconds: 90)),
      ).called(1);
    });

    test('adjust lo reprograma con la nueva hora de fin, sin cancelar', () {
      ios.start(60);
      clock.set(clock.now().add(const Duration(seconds: 10)));
      ios.adjust(15);
      expect(restAlarm.calls, ['schedule ${at(60)}', 'schedule ${at(75)}']);
    });

    test('adjust que deja el restante en 0 para y cancela', () {
      ios.start(10);
      ios.adjust(-15);
      expect(ios.snapshot.value.isResting, isFalse);
      expect(restAlarm.calls, ['schedule ${at(10)}', 'cancel']);
    });

    test('saltar/parar a mano lo cancela', () {
      ios.start(60);
      ios.stop();
      expect(restAlarm.calls, ['schedule ${at(60)}', 'cancel']);
      verify(() => notifier.onRestEnded()).called(1);
    });

    test('fin natural tras volver a primer plano: detiene la alarma, '
        'sin cancelar ni duplicar', () {
      ios.start(30);
      clock.set(clock.now().add(const Duration(seconds: 31)));
      ios.tick();
      expect(naturalEnds, 1);
      expect(restAlarm.calls, ['schedule ${at(30)}', 'finished']);
      verifyNever(() => notifications.showRestEnded());
      verify(() => notifier.onRestEnded()).called(1);
    });

    test('último segundo en primer plano: pasa a notificación una vez', () {
      ios.start(30);
      clock.set(clock.now().add(const Duration(milliseconds: 29200)));
      ios.tick();
      ios.tick();
      expect(restAlarm.calls, ['schedule ${at(30)}', 'switch ${at(30)}']);
      clock.set(clock.now().add(const Duration(seconds: 1)));
      ios.tick();
      expect(restAlarm.calls.last, 'finished');
      verifyNever(() => notifications.showRestEnded());
    });

    test('último segundo en segundo plano: la alarma se mantiene', () {
      foreground = false;
      ios.start(30);
      clock.set(clock.now().add(const Duration(milliseconds: 29200)));
      ios.tick();
      expect(restAlarm.calls, ['schedule ${at(30)}']);
    });

    test('adjust tras pasar a notificación vuelve a programar la alarma', () {
      ios.start(30);
      clock.set(clock.now().add(const Duration(milliseconds: 29200)));
      ios.tick();
      ios.adjust(15);
      expect(restAlarm.calls.last, startsWith('schedule '));
      // El nuevo último segundo vuelve a cambiar a notificación.
      clock.set(clock.now().add(const Duration(milliseconds: 15000)));
      ios.tick();
      expect(restAlarm.calls.last, startsWith('switch '));
    });

    test('con más de 1 s restante no se cambia a notificación', () {
      ios.start(30);
      clock.set(clock.now().add(const Duration(seconds: 28)));
      ios.tick();
      expect(restAlarm.calls, ['schedule ${at(30)}']);
    });
  });

  group('Android: avisa el Timer, sin programar', () {
    late RestTimerController android;

    setUp(() {
      android = RestTimerController(
        notifier: notifier,
        notifications: notifications,
        restAlarm: restAlarm,
        clock: clock,
        scheduledAlertOverride: false,
        isForeground: () => foreground,
      );
    });

    tearDown(() => android.dispose());

    test('start y adjust no programan nada', () {
      android.start(60);
      android.adjust(15);
      verifyNever(() => notifications.scheduleRestEnded(any()));
      expect(restAlarm.calls, isEmpty);
    });

    test('el fin natural muestra la alerta inmediata', () {
      android.start(30);
      clock.set(clock.now().add(const Duration(seconds: 31)));
      android.tick();
      verify(() => notifications.showRestEnded()).called(1);
    });

    test('saltar no cancela nada programado', () {
      android.start(30);
      android.stop();
      verifyNever(() => notifications.cancelRestEnded());
      expect(restAlarm.calls, isEmpty);
    });
  });
}
