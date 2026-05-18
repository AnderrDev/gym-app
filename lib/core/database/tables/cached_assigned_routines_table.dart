import 'package:drift/drift.dart';

/// Caché local de las rutinas asignadas a un usuario.
///
/// Phase 4 (SWR polish) introduce este espejo para soportar el flujo
/// `getAssignedRoutines(userId)` con stale-while-revalidate. PK compuesta
/// `(userId, routineId)`: una fila por (usuario, rutina) asignada.
///
/// La fuente de verdad sigue siendo `user_routines` ⨝ `routines_view` en
/// Supabase; aquí no se aceptan writes desde la UI. El repositorio sólo lo
/// hidrata tras una llamada exitosa al remote.
@DataClassName('CachedAssignedRoutineRow')
class CachedAssignedRoutines extends Table {
  TextColumn get userId => text()();
  TextColumn get routineId => text()();
  TextColumn get routineName => text()();
  BoolColumn get isPublic => boolean().withDefault(const Constant(false))();
  TextColumn get creatorId => text().nullable()();
  TextColumn get creatorName => text().nullable()();
  IntColumn get exerciseCount => integer().withDefault(const Constant(0))();

  /// Epoch ms (UTC) del último write desde remote. Usado para invalidar / TTL.
  IntColumn get fetchedAt => integer()();

  @override
  Set<Column> get primaryKey => {userId, routineId};
}
