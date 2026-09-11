import 'package:flutter_test/flutter_test.dart';

import '../../helpers/database_test_helper.dart';

void main() {
  group('schema v2 (Phase 1)', () {
    test('una BD fresca con schemaVersion=2 crea las 4 tablas de caché y sus '
        'índices', () async {
      final db = openInMemoryDb();
      addTearDown(() async => db.close());

      // Forzar onCreate.
      await db.ping();

      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name LIKE 'cached_%' ORDER BY name",
          )
          .get();
      final tableNames = tables.map((r) => r.read<String>('name')).toList();
      expect(
        tableNames,
        containsAll([
          'cached_exercises',
          'cached_last_performances',
          'cached_routine_days',
          'cached_routine_exercises',
        ]),
      );

      final indexes = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='index' "
            "AND name LIKE 'idx_%' ORDER BY name",
          )
          .get();
      final indexNames = indexes.map((r) => r.read<String>('name')).toList();
      expect(
        indexNames,
        containsAll([
          'idx_cached_routine_days_routine',
          'idx_cre_day_position',
          'idx_cre_exercise',
        ]),
      );
    });

    test(
      'app_meta.schema_version queda en "4" tras onCreate (Phase 4)',
      () async {
        final db = openInMemoryDb();
        addTearDown(() async => db.close());
        await db.ping();

        final row = await (db.select(
          db.appMeta,
        )..where((t) => t.key.equals('schema_version'))).getSingle();
        expect(row.value, '4');
      },
    );

    test('schemaVersion == 4 tras Phase 4', () {
      final db = openInMemoryDb();
      addTearDown(() async => db.close());
      expect(db.schemaVersion, 4);
    });
  });
}
