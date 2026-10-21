import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/auth/data/datasources/password_recovery_buffer.dart';

void main() {
  late StreamController<void> source;
  late PasswordRecoveryBuffer buffer;

  setUp(() {
    source = StreamController<void>.broadcast();
    buffer = PasswordRecoveryBuffer(source.stream);
  });

  tearDown(() async {
    await buffer.dispose();
    await source.close();
  });

  test('sin eventos no hay nada pendiente ni emite', () async {
    var count = 0;
    final sub = buffer.events.listen((_) => count++);
    await pumpEventQueue();
    expect(buffer.hasPending, isFalse);
    expect(count, 0);
    await sub.cancel();
  });

  test(
    'un evento sin oyentes queda pendiente y se entrega al suscribirse',
    () async {
      source.add(null);
      await pumpEventQueue();
      expect(buffer.hasPending, isTrue);

      var count = 0;
      final sub = buffer.events.listen((_) => count++);
      await pumpEventQueue();

      expect(count, 1);
      expect(buffer.hasPending, isFalse);
      await sub.cancel();
    },
  );

  test(
    'el pendiente se entrega una sola vez (solo al primer oyente)',
    () async {
      source.add(null);
      await pumpEventQueue();

      var first = 0;
      var second = 0;
      final sub1 = buffer.events.listen((_) => first++);
      await pumpEventQueue();
      final sub2 = buffer.events.listen((_) => second++);
      await pumpEventQueue();

      expect(first, 1);
      expect(second, 0);
      await sub1.cancel();
      await sub2.cancel();
    },
  );

  test(
    'con oyentes, los eventos nuevos se entregan y no quedan pendientes',
    () async {
      var count = 0;
      final sub = buffer.events.listen((_) => count++);
      await pumpEventQueue();

      source.add(null);
      await pumpEventQueue();
      source.add(null);
      await pumpEventQueue();

      expect(count, 2);
      expect(buffer.hasPending, isFalse);
      await sub.cancel();
    },
  );

  test(
    'tras cancelar el oyente, un evento nuevo vuelve a quedar pendiente',
    () async {
      final sub = buffer.events.listen((_) {});
      await pumpEventQueue();
      await sub.cancel();

      source.add(null);
      await pumpEventQueue();

      expect(buffer.hasPending, isTrue);
    },
  );

  test('los errores del origen no cortan la escucha', () async {
    var count = 0;
    final sub = buffer.events.listen((_) => count++);
    source.addError(Exception('enlace caducado'));
    await pumpEventQueue();
    source.add(null);
    await pumpEventQueue();

    expect(count, 1);
    await sub.cancel();
  });
}
