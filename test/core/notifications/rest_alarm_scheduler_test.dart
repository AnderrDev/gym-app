import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/notifications/alarm_kit_bridge.dart';
import 'package:gym_flutter/core/notifications/rest_alarm_scheduler.dart';
import 'package:gym_flutter/core/utils/clock.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

/// Fake del canal nativo: estado de autorización configurable y registro de
/// llamadas.
class FakeAlarmKitBridge implements AlarmKitBridge {
  FakeAlarmKitBridge(this.state, {this.afterRequest, this.scheduleOk = true});

  AlarmKitAuthorization state;
  AlarmKitAuthorization? afterRequest;
  bool scheduleOk;
  final List<String> calls = [];

  @override
  Future<AlarmKitAuthorization> authorizationState() async => state;

  @override
  Future<AlarmKitAuthorization> requestAuthorization() async {
    calls.add('request');
    state = afterRequest ?? state;
    return state;
  }

  @override
  Future<bool> scheduleAt(DateTime endsAt) async {
    calls.add('schedule ${endsAt.toIso8601String()}');
    return scheduleOk;
  }

  @override
  Future<void> cancelAll() async => calls.add('cancelAll');
}

void main() {
  setUpAll(() => registerFallbackValue(Duration.zero));

  late MockNotificationService notifications;
  late FakeClock clock;
  final start = DateTime(2026, 10, 21, 10);
  final endsAt = start.add(const Duration(seconds: 90));

  setUp(() {
    notifications = MockNotificationService();
    clock = FakeClock(start);
    when(() => notifications.scheduleRestEnded(any())).thenAnswer((_) async {});
    when(() => notifications.cancelRestEnded()).thenAnswer((_) async {});
  });

  AlarmKitRestAlarmScheduler build(FakeAlarmKitBridge alarmKit) =>
      AlarmKitRestAlarmScheduler(
        notifications: notifications,
        alarmKit: alarmKit,
        clock: clock,
      );

  group('AlarmKit autorizado (iOS 26+)', () {
    late FakeAlarmKitBridge alarmKit;
    late AlarmKitRestAlarmScheduler scheduler;

    setUp(() {
      alarmKit = FakeAlarmKitBridge(AlarmKitAuthorization.authorized);
      scheduler = build(alarmKit);
    });

    test('schedule usa AlarmKit y no programa la notificación', () async {
      await scheduler.schedule(endsAt);
      expect(alarmKit.calls, ['schedule ${endsAt.toIso8601String()}']);
      verifyNever(() => notifications.scheduleRestEnded(any()));
      // Limpia una posible notificación previa: nunca dos sonidos.
      verify(() => notifications.cancelRestEnded()).called(1);
    });

    test('cancel cancela la alarma', () async {
      await scheduler.schedule(endsAt);
      await scheduler.cancel();
      expect(alarmKit.calls.last, 'cancelAll');
    });

    test('fin natural detiene la alarma', () async {
      await scheduler.schedule(endsAt);
      await scheduler.onRestFinished();
      expect(alarmKit.calls.last, 'cancelAll');
    });

    test('switchToNotification: primero la notificación, luego cancela la '
        'alarma', () async {
      await scheduler.schedule(endsAt);
      clock.set(start.add(const Duration(milliseconds: 89500)));
      await scheduler.switchToNotification(endsAt);
      verify(
        () =>
            notifications.scheduleRestEnded(const Duration(milliseconds: 500)),
      ).called(1);
      expect(alarmKit.calls.last, 'cancelAll');
      // Ya no es AlarmKit: el fin natural no vuelve a tocar AlarmKit.
      alarmKit.calls.clear();
      await scheduler.onRestFinished();
      expect(alarmKit.calls, isEmpty);
    });

    test('operaciones encadenadas se aplican en orden', () async {
      final later = endsAt.add(const Duration(seconds: 15));
      // Sin await entre medias, como hace el controller (unawaited).
      final a = scheduler.schedule(endsAt);
      final b = scheduler.schedule(later);
      final c = scheduler.cancel();
      await Future.wait([a, b, c]);
      expect(alarmKit.calls, [
        'schedule ${endsAt.toIso8601String()}',
        'schedule ${later.toIso8601String()}',
        'cancelAll',
      ]);
    });

    test('si AlarmKit falla al programar, cae a la notificación', () async {
      alarmKit.scheduleOk = false;
      await scheduler.schedule(endsAt);
      verify(
        () => notifications.scheduleRestEnded(const Duration(seconds: 90)),
      ).called(1);
      verifyNever(() => notifications.cancelRestEnded());
    });
  });

  test('iOS < 26: solo notificación, sin pedir autorización', () async {
    final alarmKit = FakeAlarmKitBridge(AlarmKitAuthorization.unsupported);
    final scheduler = build(alarmKit);
    await scheduler.schedule(endsAt);
    await scheduler.onRestFinished();
    verify(
      () => notifications.scheduleRestEnded(const Duration(seconds: 90)),
    ).called(1);
    expect(alarmKit.calls, isEmpty);
    await scheduler.cancel();
    verify(() => notifications.cancelRestEnded()).called(1);
    expect(alarmKit.calls, isEmpty);
  });

  test('autorización denegada: notificación', () async {
    final alarmKit = FakeAlarmKitBridge(AlarmKitAuthorization.denied);
    await build(alarmKit).schedule(endsAt);
    verify(
      () => notifications.scheduleRestEnded(const Duration(seconds: 90)),
    ).called(1);
    expect(alarmKit.calls, isEmpty);
  });

  group('primer descanso (autorización sin decidir)', () {
    test('pide autorización con la notificación de cobertura y, si la '
        'concede, la sustituye por la alarma', () async {
      final alarmKit = FakeAlarmKitBridge(
        AlarmKitAuthorization.notDetermined,
        afterRequest: AlarmKitAuthorization.authorized,
      );
      await build(alarmKit).schedule(endsAt);
      verify(
        () => notifications.scheduleRestEnded(const Duration(seconds: 90)),
      ).called(1);
      verify(() => notifications.cancelRestEnded()).called(1);
      expect(alarmKit.calls, [
        'request',
        'schedule ${endsAt.toIso8601String()}',
      ]);
    });

    test('si la deniega, queda la notificación', () async {
      final alarmKit = FakeAlarmKitBridge(
        AlarmKitAuthorization.notDetermined,
        afterRequest: AlarmKitAuthorization.denied,
      );
      await build(alarmKit).schedule(endsAt);
      expect(alarmKit.calls, ['request']);
      verify(() => notifications.scheduleRestEnded(any())).called(1);
      verifyNever(() => notifications.cancelRestEnded());
    });
  });

  test('descanso ya vencido al ejecutar: no programa nada', () async {
    final alarmKit = FakeAlarmKitBridge(AlarmKitAuthorization.authorized);
    clock.set(endsAt.add(const Duration(seconds: 1)));
    await build(alarmKit).schedule(endsAt);
    expect(alarmKit.calls, isEmpty);
    verifyNever(() => notifications.scheduleRestEnded(any()));
  });

  test('fuera de iOS el puente real responde unsupported sin canal', () async {
    final bridge = AlarmKitBridge();
    expect(
      await bridge.authorizationState(),
      AlarmKitAuthorization.unsupported,
    );
    expect(await bridge.scheduleAt(endsAt), isFalse);
  });
}
