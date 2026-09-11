import 'package:flutter_test/flutter_test.dart';

import '../../helpers/database_test_helper.dart';

void main() {
  group('buildMigrationStrategy.onCreate', () {
    test(
      'siembra schema_initialized_at y schema_version=4 en app_meta',
      () async {
        final db = openInMemoryDb();
        addTearDown(() async => db.close());

        // Forzar `onCreate` con una operación trivial.
        await db.ping();

        final rows = await db.select(db.appMeta).get();
        final byKey = {for (final r in rows) r.key: r};

        expect(
          byKey.containsKey('schema_initialized_at'),
          isTrue,
          reason: 'Falta la fila schema_initialized_at',
        );
        expect(
          byKey.containsKey('schema_version'),
          isTrue,
          reason: 'Falta la fila schema_version',
        );
        expect(byKey['schema_version']!.value, '4');

        // schema_initialized_at debe parsear como int (epoch ms).
        expect(int.tryParse(byKey['schema_initialized_at']!.value), isNotNull);
      },
    );
  });
}
