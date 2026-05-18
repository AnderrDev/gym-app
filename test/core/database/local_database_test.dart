import 'package:flutter_test/flutter_test.dart';

import 'package:gym_flutter/core/database/local_database.dart';

import '../../helpers/database_test_helper.dart';

void main() {
  group('LocalDatabase (in-memory)', () {
    test('ping() devuelve un DateTime cercano a now() tras onCreate', () async {
      final db = openInMemoryDb();
      addTearDown(() async => db.close());

      final before = DateTime.now().toUtc();
      final pinged = await db.ping();
      final after = DateTime.now().toUtc();

      // El timestamp insertado por onCreate debe estar dentro de la ventana
      // [before, after] con una tolerancia generosa (5s) para entornos lentos.
      expect(
        pinged.isAfter(before.subtract(const Duration(seconds: 5))),
        isTrue,
        reason: 'ping=$pinged debería ser >= before=$before (con tolerancia)',
      );
      expect(
        pinged.isBefore(after.add(const Duration(seconds: 5))),
        isTrue,
        reason: 'ping=$pinged debería ser <= after=$after (con tolerancia)',
      );
      expect(pinged.isUtc, isTrue);
    });

    test('schemaVersion == 3 tras Phase 2', () {
      final db = openInMemoryDb();
      addTearDown(() async => db.close());
      expect(db.schemaVersion, 3);
    });

    test('round-trip insert/select sobre app_meta', () async {
      final db = openInMemoryDb();
      addTearDown(() async => db.close());

      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db
          .into(db.appMeta)
          .insert(
            AppMetaCompanion.insert(
              key: 'custom_flag',
              value: 'hello-world',
              updatedAt: now,
            ),
          );

      final row = await (db.select(
        db.appMeta,
      )..where((t) => t.key.equals('custom_flag'))).getSingle();

      expect(row.key, 'custom_flag');
      expect(row.value, 'hello-world');
      expect(row.updatedAt, now);
    });

    test('cerrar y abrir una nueva BD en memoria no crashea', () async {
      final db1 = openInMemoryDb();
      await db1.ping();
      await db1.close();

      // Una segunda BD en memoria es totalmente independiente.
      final db2 = openInMemoryDb();
      addTearDown(() async => db2.close());
      final pinged = await db2.ping();
      expect(pinged, isA<DateTime>());
    });
  });
}
