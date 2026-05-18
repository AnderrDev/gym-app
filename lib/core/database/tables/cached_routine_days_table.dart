import 'package:drift/drift.dart';

/// Caché local (read-side) de `routine_days`.
///
/// Espejo parcial — sólo guardamos las columnas necesarias para pintar la
/// lista de días + status en `RoutineDayCard`. La fuente de verdad sigue
/// siendo Supabase; aquí no se aceptan writes desde la UI.
@DataClassName('CachedRoutineDayRow')
class CachedRoutineDays extends Table {
  TextColumn get id => text()();
  TextColumn get routineId => text()();
  IntColumn get dayOfWeek => integer()();
  TextColumn get name => text()();
  IntColumn get targetSetsCount => integer().withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  /// Epoch ms (UTC) del último write desde remote. Usado para invalidar / TTL.
  IntColumn get fetchedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
