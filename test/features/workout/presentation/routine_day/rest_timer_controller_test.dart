import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/utils/clock.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/utils/rest_timer_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(Duration.zero));

  late MockActiveWorkoutNotifier notifier;
  late MockLiveActivitiesBridge liveActivities;
  late MockNotificationService notifications;
  late FakeClock clock;
  late int naturalEnds;
  late RestTimerController controller;

  setUp(() {
    notifier = MockActiveWorkoutNotifier();
    liveActivities = MockLiveActivitiesBridge();
    notifications = MockNotificationService();
    clock = FakeClock(DateTime(2026, 10, 18, 10));
    naturalEnds = 0;
    when(
      () => notifier.onRestStarted(duration: any(named: 'duration')),
    ).thenAnswer((_) async {});
    when(
      () => notifier.onRestEnded(naturalEnd: any(named: 'naturalEnd')),
    ).thenAnswer((_) async {});
    when(() => liveActivities.isAvailable).thenReturn(true);
    controller = RestTimerController(
      notifier: notifier,
      liveActivities: liveActivities,
      notifications: notifications,
      onNaturalEnd: () => naturalEnds++,
      clock: clock,
    );
  });

  tearDown(() => controller.dispose());

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
    verify(() => notifier.onRestEnded(naturalEnd: true)).called(1);
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
}
