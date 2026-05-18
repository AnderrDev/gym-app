import 'package:flutter_test/flutter_test.dart';

import '../../helpers/database_test_helper.dart';

/// Phase 4 (SWR polish) introduce 2 tablas:
///  - cached_assigned_routines
///  - cached_weekly_insights
/// Y 1 índice auxiliar:
///  - idx_car_user
///
/// Estos tests verifican el resultado tras `onCreate` (no probamos el upgrade
/// path real porque el harness en memoria sólo soporta open-with-current-
/// version — el `onUpgrade` quedaría dead-code aquí).
void main() {
  group('schema v4 (Phase 4 SWR polish)', () {
    test(
        'una BD fresca con schemaVersion=4 crea las 2 tablas SWR y su índice',
        () async {
      final db = openInMemoryDb();
      addTearDown(() async => db.close());

      // Fuerza onCreate.
      await db.ping();

      final tables = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name IN ('cached_assigned_routines', 'cached_weekly_insights') "
        'ORDER BY name',
      ).get();
      final tableNames = tables.map((r) => r.read<String>('name')).toList();
      expect(
        tableNames,
        containsAll([
          'cached_assigned_routines',
          'cached_weekly_insights',
        ]),
      );

      final indexes = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='index' "
        "AND name LIKE 'idx_%' ORDER BY name",
      ).get();
      final indexNames = indexes.map((r) => r.read<String>('name')).toList();
      expect(indexNames, contains('idx_car_user'));
    });

    test('app_meta.schema_version queda en "4" tras onCreate', () async {
      final db = openInMemoryDb();
      addTearDown(() async => db.close());
      await db.ping();

      final row = await (db.select(db.appMeta)
            ..where((t) => t.key.equals('schema_version')))
          .getSingle();
      expect(row.value, '4');
    });

    test('schemaVersion == 4 en Phase 4', () {
      final db = openInMemoryDb();
      addTearDown(() async => db.close());
      expect(db.schemaVersion, 4);
    });

    test('PK compuesta de cached_assigned_routines: (user_id, routine_id)',
        () async {
      final db = openInMemoryDb();
      addTearDown(() async => db.close());
      await db.ping();

      final info = await db.customSelect(
        "SELECT name FROM pragma_table_info('cached_assigned_routines') "
        'WHERE pk > 0 ORDER BY pk',
      ).get();
      final pkCols = info.map((r) => r.read<String>('name')).toList();
      expect(pkCols, ['user_id', 'routine_id']);
    });

    test(
        'PK compuesta de cached_weekly_insights: (user_id, routine_id, '
        'week_start)', () async {
      final db = openInMemoryDb();
      addTearDown(() async => db.close());
      await db.ping();

      final info = await db.customSelect(
        "SELECT name FROM pragma_table_info('cached_weekly_insights') "
        'WHERE pk > 0 ORDER BY pk',
      ).get();
      final pkCols = info.map((r) => r.read<String>('name')).toList();
      expect(pkCols, ['user_id', 'routine_id', 'week_start']);
    });
  });
}
