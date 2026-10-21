import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/notifications/live_activities_bridge.dart';
import 'package:live_activities/live_activities.dart';
import 'package:mocktail/mocktail.dart';

class _MockLiveActivities extends Mock implements LiveActivities {}

void main() {
  late _MockLiveActivities plugin;

  setUp(() {
    plugin = _MockLiveActivities();
    when(
      () => plugin.init(appGroupId: any(named: 'appGroupId')),
    ).thenAnswer((_) async {});
    when(() => plugin.areActivitiesEnabled()).thenAnswer((_) async => true);
    when(() => plugin.endAllActivities()).thenAnswer((_) async {});
  });

  LiveActivitiesBridge bridge({bool supported = true}) => LiveActivitiesBridge(
    plugin: plugin,
    supportsLiveActivitiesOverride: supported,
  );

  test('init finaliza las activities huérfanas', () async {
    when(
      () => plugin.getAllActivitiesIds(),
    ).thenAnswer((_) async => ['a', 'b']);
    final b = bridge();
    await b.init();
    expect(b.isAvailable, isTrue);
    verify(() => plugin.endAllActivities()).called(1);
  });

  test('init sin huérfanas no finaliza nada', () async {
    when(() => plugin.getAllActivitiesIds()).thenAnswer((_) async => []);
    await bridge().init();
    verifyNever(() => plugin.endAllActivities());
  });

  test('un fallo al limpiar no deshabilita la Live Activity', () async {
    when(() => plugin.getAllActivitiesIds()).thenThrow(Exception('boom'));
    final b = bridge();
    await b.init();
    expect(b.isAvailable, isTrue);
  });

  test('en plataformas sin soporte init no toca el plugin', () async {
    final b = bridge(supported: false);
    await b.init();
    expect(b.isAvailable, isFalse);
    verifyNever(() => plugin.init(appGroupId: any(named: 'appGroupId')));
  });

  test(
    'ready completa tras init y es idempotente (init corre una vez)',
    () async {
      when(() => plugin.getAllActivitiesIds()).thenAnswer((_) async => []);
      final b = bridge();
      expect(b.isAvailable, isFalse);
      await Future.wait([b.ready, b.init(), b.ready]);
      expect(b.isAvailable, isTrue);
      verify(() => plugin.init(appGroupId: any(named: 'appGroupId'))).called(1);
    },
  );

  test(
    'start antes del init diferido espera al init en vez de ignorarse',
    () async {
      when(() => plugin.getAllActivitiesIds()).thenAnswer((_) async => []);
      when(
        () => plugin.createActivity(
          any(),
          any(),
          removeWhenAppIsKilled: any(named: 'removeWhenAppIsKilled'),
          iOSEnableRemoteUpdates: any(named: 'iOSEnableRemoteUpdates'),
        ),
      ).thenAnswer((_) async => 'act-1');
      final b = bridge();
      await b.start(
        dayName: 'Pierna',
        sessionStartedAt: DateTime(2026, 10, 21),
        totalSets: 10,
      );
      verify(
        () => plugin.createActivity(
          any(),
          any(),
          removeWhenAppIsKilled: any(named: 'removeWhenAppIsKilled'),
          iOSEnableRemoteUpdates: any(named: 'iOSEnableRemoteUpdates'),
        ),
      ).called(1);
    },
  );
}
