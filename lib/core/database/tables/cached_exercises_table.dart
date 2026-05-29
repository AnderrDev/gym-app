import 'package:drift/drift.dart';

/// Caché local del catálogo `exercises` (datos canónicos por ejercicio:
/// nombre, grupo muscular, imagen). Se llena de forma laxa cuando se cargan
/// ejercicios de un día; no representa el catálogo completo.
@DataClassName('CachedExerciseRow')
class CachedExercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get muscleGroup => text().withDefault(const Constant(''))();
  TextColumn get imageUrl => text().nullable()();

  /// Epoch ms (UTC) del último write desde remote.
  IntColumn get fetchedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
