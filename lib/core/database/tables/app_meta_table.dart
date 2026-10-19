import 'package:drift/drift.dart';

/// Tabla de metadatos transversales de la base local.
///
/// Mantiene pares clave/valor de configuración y bookkeeping (versión de
/// esquema, timestamps de inicialización, flags de migración, etc.). El
/// healthcheck en [`LocalDatabase.ping`] lee la fila `schema_initialized_at`.
@DataClassName('AppMetaRow')
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  /// Epoch en milisegundos (UTC) del último write. Usamos INTEGER en lugar de
  /// DateTime para que el formato sea independiente del codec drift y trivial
  /// de inspeccionar desde sqlite3 CLI.
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {key};
}
