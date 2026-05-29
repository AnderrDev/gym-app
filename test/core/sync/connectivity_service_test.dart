import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:gym_flutter/core/sync/connectivity_service.dart';

/// Fake del platform interface de `connectivity_plus`. Sigue el patrón
/// recomendado upstream (extends Mock + MockPlatformInterfaceMixin), pero sin
/// mockito: aquí implementamos a mano las dos APIs que `Connectivity`
/// consulta. Esto evita el coste de añadir mockito sólo para este test.
class _FakeConnectivityPlatform extends ConnectivityPlatform
    with MockPlatformInterfaceMixin {
  _FakeConnectivityPlatform({List<ConnectivityResult>? initial})
    : _last = initial ?? const [ConnectivityResult.wifi];

  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  List<ConnectivityResult> _last;

  void emit(List<ConnectivityResult> results) {
    _last = results;
    _controller.add(results);
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _last;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  Future<void> close() => _controller.close();
}

void main() {
  late _FakeConnectivityPlatform fake;

  tearDown(() async {
    await fake.close();
  });

  test('isOnline arranca en true antes del primer evento', () {
    fake = _FakeConnectivityPlatform(initial: [ConnectivityResult.wifi]);
    ConnectivityPlatform.instance = fake;
    final service = ConnectivityServiceImpl(Connectivity());
    addTearDown(service.dispose);

    expect(service.isOnline, isTrue);
  });

  test('[none] => offline', () async {
    fake = _FakeConnectivityPlatform(initial: [ConnectivityResult.wifi]);
    ConnectivityPlatform.instance = fake;
    final service = ConnectivityServiceImpl(Connectivity());
    addTearDown(service.dispose);

    final firstFalse = service.isOnline$.firstWhere((v) => v == false);
    fake.emit(const [ConnectivityResult.none]);
    await expectLater(firstFalse, completion(isFalse));
    expect(service.isOnline, isFalse);
  });

  test('[wifi] => online (tras un offline previo)', () async {
    fake = _FakeConnectivityPlatform(initial: [ConnectivityResult.none]);
    ConnectivityPlatform.instance = fake;
    final service = ConnectivityServiceImpl(Connectivity());
    addTearDown(service.dispose);

    await service.checkNow();
    expect(service.isOnline, isFalse);

    final firstTrue = service.isOnline$.firstWhere((v) => v == true);
    fake.emit(const [ConnectivityResult.wifi]);
    await expectLater(firstTrue, completion(isTrue));
    expect(service.isOnline, isTrue);
  });

  test('[vpn] cuenta como online', () async {
    fake = _FakeConnectivityPlatform(initial: [ConnectivityResult.none]);
    ConnectivityPlatform.instance = fake;
    final service = ConnectivityServiceImpl(Connectivity());
    addTearDown(service.dispose);

    await service.checkNow();
    expect(service.isOnline, isFalse);

    final firstTrue = service.isOnline$.firstWhere((v) => v == true);
    fake.emit(const [ConnectivityResult.vpn]);
    await expectLater(firstTrue, completion(isTrue));
  });

  test('dedupe: eventos iguales consecutivos emiten una sola vez', () async {
    fake = _FakeConnectivityPlatform(initial: [ConnectivityResult.wifi]);
    ConnectivityPlatform.instance = fake;
    final service = ConnectivityServiceImpl(Connectivity());
    addTearDown(service.dispose);

    // Sincronizar estado cacheado a true.
    await service.checkNow();
    expect(service.isOnline, isTrue);

    final emitted = <bool>[];
    final sub = service.isOnline$.listen(emitted.add);

    // wifi → wifi: no debe emitir (dedupe).
    fake.emit(const [ConnectivityResult.wifi]);
    fake.emit(const [ConnectivityResult.wifi]);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Cambio a offline: debe emitir false una vez.
    fake.emit(const [ConnectivityResult.none]);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // none → none: dedupe nuevamente.
    fake.emit(const [ConnectivityResult.none]);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emitted, [false]);

    await sub.cancel();
  });
}
