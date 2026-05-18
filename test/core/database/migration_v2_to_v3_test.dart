import 'package:flutter_test/flutter_test.dart';

import '../../helpers/database_test_helper.dart';

void main() {
  group('schema v3 (Phase 2)', () {
    test(
        'una BD fresca con schemaVersion=3 crea las 3 tablas write-side + '
        'sus índices', () async {
      final db = openInMemoryDb();
      addTearDown(() async => db.close());

      await db.ping();

      final tables = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name IN ('cached_workout_sessions', 'cached_set_logs', "
        "'pending_mutations') ORDER BY name",
      ).get();
      final tableNames = tables.map((r) => r.read<String>('name')).toList();
      expect(
        tableNames,
        containsAll([
          'cached_set_logs',
          'cached_workout_sessions',
          'pending_mutations',
        ]),
      );

      final indexes = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='index' "
        "AND name LIKE 'idx_%' ORDER BY name",
      ).get();
      final indexNames = indexes.map((r) => r.read<String>('name')).toList();
      expect(
        indexNames,
        containsAll([
          'idx_csl_session',
          'idx_cws_user_date',
          'idx_cws_user_open',
          'idx_pm_ready',
          // Phase 4 onCreate también siembra los índices nuevos.
          'idx_car_user',
        ]),
      );
    });

    test('app_meta.schema_version queda en "4" tras onCreate (Phase 4)',
        () async {
      final db = openInMemoryDb();
      addTearDown(() async => db.close());
      await db.ping();

      final row = await (db.select(db.appMeta)
            ..where((t) => t.key.equals('schema_version')))
          .getSingle();
      expect(row.value, '4');
    });

    test('schemaVersion == 4 tras Phase 4', () {
      final db = openInMemoryDb();
      addTearDown(() async => db.close());
      expect(db.schemaVersion, 4);
    });

    test('PK compuesta de cached_set_logs respeta (session,exercise,setIndex)',
        () async {
      final db = openInMemoryDb();
      addTearDown(() async => db.close());
      await db.ping();

      // Sanity check: el schema declara la PK compuesta correcta.
      final info = await db.customSelect(
        "SELECT name FROM pragma_table_info('cached_set_logs') "
        'WHERE pk > 0 ORDER BY pk',
      ).get();
      final pkCols = info.map((r) => r.read<String>('name')).toList();
      expect(pkCols, ['session_id', 'exercise_id', 'set_index']);
    });
  });
}
