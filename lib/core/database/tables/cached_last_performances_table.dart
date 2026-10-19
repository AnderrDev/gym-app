import 'package:drift/drift.dart';

/// Caché local del "último set_log por (user, exercise)" — soporta el preview
/// de progresión que muestra el día activo sin pegar a Supabase en cada
/// pantalla. PK compuesta `(userId, exerciseId)`: 1 fila por par.
@DataClassName('CachedLastPerformanceRow')
class CachedLastPerformances extends Table {
  TextColumn get userId => text()();
  TextColumn get exerciseId => text()();
  TextColumn get setLogId => text().nullable()();
  TextColumn get sessionId => text()();
  RealColumn get actualWeight => real()();
  IntColumn get actualReps => integer()();
  IntColumn get setIndex => integer()();

  /// Epoch ms (UTC) del `created_at` del set_log original (cuándo se realizó).
  /// Nullable si el remote no lo devolvió.
  IntColumn get performedAt => integer().nullable()();

  /// Epoch ms (UTC) del último write desde remote.
  IntColumn get fetchedAt => integer()();

  @override
  Set<Column> get primaryKey => {userId, exerciseId};
}
